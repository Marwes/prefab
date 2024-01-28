local constants = require("constants")

local exports = {}

local tile_name = "refined-concrete"

local size = 7

local function centered_bounding_box(position, size)
    return {left_top = { x = position.x - size / 2, y = position.y - size / 2}, right_bottom = { x = position.x + size / 2, y = position.y + size / 2}}
end

local function contains_bounding_box(parent, child)
    log(serpent.block{parent, child})
    return parent.left_top.x <= child.left_top.x and
        parent.left_top.y <= child.left_top.y and
        parent.right_bottom.x >= child.right_bottom.x and
        parent.right_bottom.y >= child.right_bottom.y
end

function exports.on_built_entity(e)
    local entity = e.created_entity

    local position = entity.position

    local tiles = {}
    for x = position.x - size / 2, position.x + size / 2 - 1, 1 do
        for y = position.y - size / 2, position.y + size / 2 - 1, 1 do
            table.insert(tiles, { name = tile_name, position = {x, y} })
        end
    end

    entity.surface.set_tiles(tiles)
end

function exports.on_player_mined_entity(e)
    local prefab = e.entity
    local player = game.players[e.player_index]

    local prefabBoundingBox = centered_bounding_box(prefab.position, size)
    local searchedEntities = prefab.surface.find_entities(prefabBoundingBox)
    local prefabbedEntities = {}
    for i, entity in ipairs(searchedEntities) do
        if entity.name == constants.prefab_name then
            ::continue::
        end
        log(serpent.block{contains_bounding_box(prefabBoundingBox, entity.bounding_box)})
        if contains_bounding_box(prefabBoundingBox, entity.bounding_box) then
            table.insert(prefabbedEntities, entity)
        end
    end

    assert(e.buffer.insert{name = "blueprint", count = 1} == 1)
    local blueprint = e.buffer.find_item_stack("blueprint")
    blueprint.create_blueprint{ surface = prefab.surface, force = player.force, area = prefabBoundingBox }
    blueprint.blueprint_snap_to_grid = {0, 0}
    blueprint.blueprint_position_relative_to_grid = {size, size}

    local prefab_stack = e.buffer.find_item_stack(constants.prefab_name)
    assert(prefab_stack)
    prefab_stack.set_tag("blueprint", blueprint.export_stack())


    local params = {}
    for _, entity in ipairs(prefabbedEntities) do
	    table.insert(params, '[item=' .. entity.name .. ']')
        entity.destroy()
    end
    prefab_stack.custom_description = table.concat(params, " ")
end

return exports