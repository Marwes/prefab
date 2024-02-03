local constants = require("constants")

local exports = {}

local tile_name = "refined-concrete"

local size = 7

local function centered_bounding_box(position, size)
    return {left_top = { x = position.x - size / 2, y = position.y - size / 2}, right_bottom = { x = position.x + size / 2, y = position.y + size / 2}}
end

local function contains_bounding_box(parent, child)
    return parent.left_top.x <= child.left_top.x and
        parent.left_top.y <= child.left_top.y and
        parent.right_bottom.x >= child.right_bottom.x and
        parent.right_bottom.y >= child.right_bottom.y
end

local function find_prefab_in_blueprint(blueprint)
    local blueprint_entities = blueprint.get_blueprint_entities()

    for _, e in ipairs(blueprint_entities) do
        if e.name == constants.prefab_name then
            return { x = e.position.x, y = e.position.y }
        end
    end
    return nil
end

local function vecAdd(l, r)
    return { x = l.x + r.x, y = l.y + r.y }
end

local function blueprint_center_position(blueprint)
    local blueprint_entities = blueprint.get_blueprint_entities()

    local position = { x = 0, y = 0}
    for _, e in ipairs(blueprint_entities) do
        position = vecAdd(position, e.position)
    end
    return { x = position.x / #blueprint_entities, y = position.y / #blueprint_entities }
end

local function set_tiles_around(surface, position, size, tile_name)
    local tiles = {}
    for x = position.x - size / 2, position.x + size / 2 - 1, 1 do
        for y = position.y - size / 2, position.y + size / 2 - 1, 1 do
            table.insert(tiles, { name = tile_name, position = {x, y} })
        end
    end

    surface.set_tiles(tiles)
end

local function remove_tiles_around(surface, position, size)
    local tiles = {}
    for _, tile in ipairs(surface.find_tiles_filtered{ position = position, area = centered_bounding_box(position, size) }) do
        table.insert(tiles, { name = tile.hidden_tile, position = tile.position })
    end

    surface.set_tiles(tiles)
end

function exports.on_built_entity(e)
    local entity = e.created_entity
    local position = entity.position
    local player = game.players[e.player_index]


    local inventory = game.create_inventory(1)
    inventory.insert{ name = "blueprint", count = 1 }
    local blueprint = inventory.find_item_stack("blueprint")

    if not e.stack.valid_for_read then return end
    local blueprint_string = e.stack.get_tag("blueprint")
    if blueprint_string then
        blueprint.import_stack(blueprint_string)
        log(serpent.block{"----", find_prefab_in_blueprint(blueprint), blueprint_center_position(blueprint)})

        local center = blueprint_center_position(blueprint)

        local place_position = { entity.position.x + center.x - size / 2, entity.position.y + center.y - size / 2 }
        log(serpent.block{place_position, center})
        local built_entities = blueprint.build_blueprint{ surface = entity.surface, force = entity.force, position = place_position, by_player = e.player_index }
        log(serpent.block{#built_entities, #blueprint.get_blueprint_entities()})
        if #built_entities  ~= #blueprint.get_blueprint_entities() - 1 then -- Subtract one for the prefab itself
            game.players[e.player_index].insert(e.stack)
			entity.surface.create_entity{ name="flying-text", position = entity.position, text = "Unable to build prefab due to colliding entities" }
            entity.destroy()
            return
        end
        for _, e in ipairs(built_entities) do 
            if player.can_place_entity{ name = e.ghost_name, position = e.position, direction = e.direction } then
                log(serpent.block{e.ghost_name, player.get_main_inventory().get_item_count("electric-mining-drill")})
                local cant_remove_index = nil 
                local items_to_place_this = e.ghost_prototype.items_to_place_this
                local player_inventory = player.get_main_inventory()
                for i, item in ipairs(items_to_place_this) do
                    local to_remove = item.count or 1
                    if player_inventory.remove(item) ~= to_remove then
                        cant_remove_index = i
                        break
                    end
                end

                if cant_remove_index then
                    -- Did not have the items to place this entity, restore the items we removed and don't place the entity (leave it as a ghost)
                    for i=1,cant_remove_index - 1,1 do
                        player_inventory.insert(items_to_place_this[i])
                    end
                else
                    e.silent_revive{ return_item_request_proxy = true, raise_revive = false }
                end
            end
        end
    end

    set_tiles_around(entity.surface, position, size, tile_name)

    -- TEST
    if true then
        player.insert(blueprint)
    end

    inventory.destroy()
end

local function create_blueprint(inventory, surface, force, prefab_bounding_box)
    assert(inventory.insert{name = "blueprint", count = 1} == 1)
    local blueprint = inventory.find_item_stack("blueprint")
    blueprint.create_blueprint{ surface = surface, force = force, area = prefab_bounding_box }
    blueprint.blueprint_snap_to_grid = { x = size, y = size }
    blueprint.blueprint_absolute_snapping = false
    local blueprint_entities = blueprint.get_blueprint_entities()

    -- Don't create a blueprint if the prefab is the only entity
    if #blueprint_entities == 1 then return nil end

    local prefab_position
    for _, e in ipairs(blueprint_entities) do
        if e.name == constants.prefab_name then
            prefab_position = { x = e.position.x - size / 2, y = e.position.y - size / 2 }
            break
        end
    end
    for _, e in ipairs(blueprint_entities) do
        e.position.x = e.position.x - prefab_position.x
        e.position.y = e.position.y - prefab_position.y
    end
    blueprint.set_blueprint_entities(blueprint_entities)

    local blueprint_string = blueprint.export_stack()
    inventory.remove("blueprint")
    return blueprint_string
end

function exports.on_player_mined_entity(e)
    local prefab = e.entity
    local player = game.players[e.player_index]

    local prefab_bounding_box = centered_bounding_box(prefab.position, size)
    local searchedEntities = prefab.surface.find_entities_filtered{ area = prefab_bounding_box }
    local searchedEntities = prefab.surface.find_entities_filtered{ area = prefab_bounding_box, force = player.force }
    local prefabbedEntities = {}
    for i, entity in ipairs(searchedEntities) do
        if entity.name ~= constants.prefab_name and contains_bounding_box(prefab_bounding_box, entity.bounding_box) then
            table.insert(prefabbedEntities, entity)
        end
    end

    local blueprint_string = create_blueprint(e.buffer, prefab.surface, player.force, prefab_bounding_box)

    remove_tiles_around(prefab.surface, prefab.position, size)

    if blueprint_string then
        local prefab_stack = e.buffer.find_item_stack(constants.prefab_name)
        assert(prefab_stack)
        prefab_stack.set_tag("blueprint", blueprint_string)

        local params = {}
        for _, entity in ipairs(prefabbedEntities) do
            if entity.name ~= constants.prefab_name then
                table.insert(params, '[item=' .. entity.name .. ']')
                player.mine_entity(entity)
            end
        end
        prefab_stack.custom_description = table.concat(params, " ")

    end
end

return exports