local constants = require("constants")

local exports = {}

local tile_name = constants.prefab_tile_name


local function is_prefab(entity)
    return entity.name:find("^prefab") ~= nil
end

local function starts_with(haystack, needle)
    return string.sub(haystack, 1, string.len(needle)) == needle
end
local function is_build_prefab(entity)
    return starts_with(entity.name, "prefab-build")
end

local function sort_entities(entities)
    table.sort(entities, function(l, r)
        if l.position.y < r.position.y then
            return true
        elseif l.position.y > r.position.y then
            return false
        elseif l.position.x < r.position.x then
            return true
        elseif l.position.x > r.position.x then
            return false
        end
        return l.name < r.name
    end)
end

local function centered_bounding_box(position, size)
    return {left_top = { x = position.x - size / 2, y = position.y - size / 2}, right_bottom = { x = position.x + size / 2, y = position.y + size / 2}}
end

local function contains_bounding_box(parent, child)
    return parent.left_top.x <= child.left_top.x and
        parent.left_top.y <= child.left_top.y and
        parent.right_bottom.x >= child.right_bottom.x and
        parent.right_bottom.y >= child.right_bottom.y
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
        if tile.hidden_tile then
            table.insert(tiles, { name = tile.hidden_tile, position = tile.position })
        end
    end

    surface.set_tiles(tiles)
end

function exports.on_built_entity(e)
    local entity = e.created_entity
    local position = entity.position
    local surface = entity.surface
    local force = entity.force

    local player = game.players[e.player_index]

    -- Replace the "build entity" has a large collission box to indicate the whole prefab's size, we replace it with the in-world entity before deploying the prefab
    if is_build_prefab(entity) then
        local build_name = entity.name
        entity.destroy()
        entity = surface.create_entity{ name = constants.build_name_to_prefab_name(build_name), position = position, force = force, player = player, source = player.character}
    end

    local prefab_spec = constants.prefab[entity.name]
    assert(prefab_spec, "No prefab spec for " .. entity.name)

    local inventory = game.create_inventory(1)
    inventory.insert{ name = "blueprint", count = 1 }
    local blueprint = inventory.find_item_stack("blueprint")

    if not e.stack.valid_for_read then return end
    local blueprint_string = e.stack.get_tag("blueprint")
    if blueprint_string then
        blueprint.import_stack(blueprint_string)

        local center = blueprint_center_position(blueprint)

        local place_position = { position.x + center.x - prefab_spec.size / 2, position.y + center.y - prefab_spec.size / 2 }
        local built_entities = blueprint.build_blueprint{ surface = surface, force = force, position = place_position, by_player = e.player_index }
        if #built_entities  ~= #blueprint.get_blueprint_entities() - 1 then -- Subtract one for the prefab itself
            game.players[e.player_index].insert(e.stack)
			surface.create_entity{ name="flying-text", position = position, text = "Unable to build prefab as some entities could not be built" }
            entity.destroy()
            return
        end
        for _, e in ipairs(built_entities) do
            if player.can_place_entity{ name = e.ghost_name, position = e.position, direction = e.direction } then
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
                    local _, built_entity, item_request_proxy = e.silent_revive{ return_item_request_proxy = true, raise_revive = false }

                    if item_request_proxy then
                        local remaining_requests = {}
                        for item_name, count in pairs(item_request_proxy.item_requests) do
                            local modules_placed = player_inventory.remove{name = item_name, count = count}
                            built_entity.insert{name = item_name, count = modules_placed}
                            if modules_placed < count then
                                remaining_requests[item_name] = count - modules_placed
                            end
                        end
                        item_request_proxy.item_requests = remaining_requests
                    end
                end
            end
        end
    end

    set_tiles_around(surface, position, prefab_spec.size, tile_name)


    -- TEST
    if false then
        player.insert(blueprint)
    end

    inventory.destroy()
end

local function create_blueprint(inventory, surface, force, size, prefab_bounding_box)
    -- log(serpent.block{"create_blueprint", prefab_bounding_box})
    assert(inventory.insert{name = "blueprint", count = 1} == 1)
    local blueprint = inventory.find_item_stack("blueprint")
    blueprint.create_blueprint{ surface = surface, force = force, area = prefab_bounding_box }
    blueprint.blueprint_snap_to_grid = { x = size, y = size }
    blueprint.blueprint_absolute_snapping = false
    local blueprint_entities = blueprint.get_blueprint_entities()

    -- Don't create a blueprint if the prefab is the only entity
    if blueprint_entities == nil or #blueprint_entities == 1 then
        assert(inventory.remove("blueprint") == 1)
        return nil
    end

    local prefab_position
    for _, e in ipairs(blueprint_entities) do
        if is_prefab(e) then
            prefab_position = { x = e.position.x - size / 2, y = e.position.y - size / 2 }
            break
        end
    end
    assert(prefab_position, "BUG: Unable to find prefab when generating prefab blueprint")
    for _, e in ipairs(blueprint_entities) do
        e.position.x = math.floor(e.position.x - prefab_position.x)
        e.position.y = math.floor(e.position.y - prefab_position.y)
    end

    sort_entities(blueprint_entities)
    blueprint.set_blueprint_entities(blueprint_entities)

    -- TEST
    if true then
        game.players[1].insert(blueprint)
    end

    local blueprint_string = blueprint.export_stack()
    assert(inventory.remove("blueprint") == 1)
    return blueprint_string
end

local function show_error_at(surface, position, text)
    surface.create_entity{ name="flying-text", position = position, text = text }
    surface.play_sound{ path = "utility/cannot_build", position = position }
end

function exports.on_player_mined_entity(e)
    local prefab = e.entity
    local player = game.players[e.player_index]

    local prefab_spec = constants.prefab[prefab.name]

    local prefab_bounding_box = centered_bounding_box(prefab.position, prefab_spec.size)
    local searched_entities = prefab.surface.find_entities_filtered{ area = prefab_bounding_box, force = player.force }
    local prefabbed_entities = {}
    for i, entity in ipairs(searched_entities) do
        if not is_prefab(entity) and not (entity.type == "character") and not (entity.type == "car")and entity.minable then
            if contains_bounding_box(prefab_bounding_box, entity.bounding_box) then
                table.insert(prefabbed_entities, entity)
            else
                show_error_at(entity.surface, entity.position, { "", entity.localised_name, " is not fully within the prefab's construction area" })
                prefab.surface.create_entity { name = prefab.name, position = prefab.position, force = prefab.force }
                return
            end
        end
    end

    sort_entities(prefabbed_entities)

    local blueprint_string = create_blueprint(e.buffer, prefab.surface, player.force, prefab_spec.size, prefab_bounding_box)

    remove_tiles_around(prefab.surface, prefab.position, prefab_spec.size)

    if blueprint_string then
        local prefab_stack
        for _, spec in pairs(constants.prefab) do
            prefab_stack = e.buffer.find_item_stack(spec.build_name)
            if prefab_stack then
                break
            end
        end
        assert(prefab_stack, "Missing prefab!")
        prefab_stack.set_tag("blueprint", blueprint_string)

        local params = {}
        local previous_x = nil
        for _, entity in ipairs(prefabbed_entities) do
            if entity.valid and entity.minable and not is_prefab(entity) then
                local item_name = entity.name == "entity-ghost" and entity.ghost_name or entity.name
                local x = entity.position.x
                if player.mine_entity(entity) then
                    if previous_x ~= nil then
                        if x > previous_x then
                            table.insert(params, " ")
                        else
                            -- Start of a new line
                            table.insert(params, "\n")
                        end
                    end
                    table.insert(params, '[item=' .. item_name .. ']')
                    previous_x = x
                end
            end
        end
        prefab_stack.custom_description = table.concat(params, "")

    end
end

function exports.on_player_mined_tile(e)
    local surface = game.surfaces[e.surface_index]
    local tiles = e.tiles

    -- Disables mining of the prefab tiles, without making them not-minable (which would cause any natural tiles to be erased when the prefab is placed)
    local tiles_to_restore = {}
    for _, tile in pairs(tiles) do
        if tile.old_tile.name == constants.prefab_tile_name then
            table.insert(tiles_to_restore, { name = constants.prefab_tile_name, position = tile.position })
        end
    end

    if #tiles_to_restore > 0 then
        surface.set_tiles(tiles_to_restore)
    end
end

function exports.on_player_built_tile(e)
    -- log(serpent.block{"on_player_mined_tile", e})
    if e.tile.name == constants.prefab_tile_name then return end

    local tiles = e.tiles
    local surface = game.surfaces[e.surface_index]

    local tiles_to_restore = {}
    -- Disable building tiles on top of any prefab tiles

    for _, tile in pairs(tiles) do
        if tile.old_tile.name == constants.prefab_tile_name then
            table.insert(tiles_to_restore, { name = constants.prefab_tile_name, position = tile.position })
        end
    end

    if #tiles_to_restore > 0 then
        surface.set_tiles(tiles_to_restore)
        if e.stack then
            e.stack.count = e.stack.count + #tiles_to_restore
        end
    end
end

return exports
