local constants = require("constants")

local base = "medium-electric-pole"

local prefab_tint = { r = 0.5, g = 0.5, b = 0.6, a = 1 }

local function tint_sprite(sprite, tint)
    if sprite.filename then
        sprite.tint = tint
        sprite.apply_runtime_tint = true
    end
    if sprite.hr_version then
        tint_sprite(sprite.hr_version, tint)
    end
    if sprite.layers then
        for _, layer in ipairs(sprite.layers) do
            tint_sprite(layer, tint)
        end
    end
end
local function tint_icons(t, tint)
    if t.icon then
        t.icons = {{ icon = t.icon }}
        t.icon = nil
    end
    if t.icons then
        for _, icon in ipairs(t.icons) do
            icon.tint = tint
        end
    end
end

local function create_prefab_data(spec)
    log(serpent.block{spec})
    local prefab_placed_entity = table.deepcopy(data.raw["electric-pole"][base])
    prefab_placed_entity.name = spec.name
    prefab_placed_entity.minable.result = spec.build_name
    prefab_placed_entity.supply_area_distance = spec.size / 2
    tint_sprite(prefab_placed_entity.pictures, prefab_tint)
    -- prefab_placed_entity.collision_mask = { "item-layer", "object-layer", "water-tile" }

    local prefab_build_entity = table.deepcopy(prefab_placed_entity)
    prefab_build_entity.name = spec.build_name
    local size = (spec.size - 0.01) / 2
    prefab_build_entity.collision_box = { { -size, -size }, { size, size } }
    -- prefab_build_entity.selection_box = { { -sizeew, -size }, { size, size } }

    local prefab_item = table.deepcopy(data.raw["item"][base])
    prefab_item.name = spec.build_name
    prefab_item.place_result = spec.build_name
    prefab_item.group = "logistics" 
    prefab_item.subgroup = "energy-pipe-distribution" 
    prefab_item.order = "a[energy]-f[prefab]"
    prefab_item.type = "item-with-tags"
    tint_icons(prefab_item, prefab_tint)
    table.insert(prefab_item.icons, {
        icon = "__base__/graphics/icons/signal/signal_" .. spec.size .. ".png",
        shift = {-10, -10},
        scale = 0.25,
    })

    local prefab_build_item = table.deepcopy(prefab_item)
    prefab_build_item.name = spec.name
    prefab_build_item.place_result = spec.name

    local prefab_recipe = table.deepcopy(data.raw["recipe"][base])
    prefab_recipe.name = spec.name
    prefab_recipe.result = spec.build_name
    prefab_recipe.ingredients = spec.ingredients
    prefab_recipe.energy_required = 20

    return {prefab_placed_entity, prefab_build_entity, prefab_item, prefab_build_item, prefab_recipe}
end

for _, spec in pairs(constants.prefab) do
    data:extend(create_prefab_data(spec))
end


local prefab_tile_item = table.deepcopy(data.raw.item["refined-concrete"])

prefab_tile_item.name = constants.prefab_tile_name 
prefab_tile_item.icons = {{ icon = prefab_tile_item.icon, tint = prefab_tint }}


local prefab_tile = table.deepcopy(data.raw.tile["refined-concrete"])
prefab_tile.name = constants.prefab_tile_name 
prefab_tile.localised_name = { constants.prefab_tile_name }
prefab_tile.tint = prefab_tint
prefab_tile.minable.result = nil
prefab_tile.minable.count = nil

data:extend{prefab_tile_item, prefab_tile}


data:extend{
    {
        type = "technology",
        name = "prefab-1",
        upgrade = true,
        unit = {
            count = 200,
            time = 30,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
            }
        },
        prerequisites = {"electric-energy-distribution-1", "concrete"},
        effects = {
            {
                type  = "unlock-recipe",
                recipe = constants.prefab["prefab"].name,
            },
            {
                type  = "unlock-recipe",
                recipe = constants.prefab["prefab-9x9"].name,
            },
        },
        icon_size = 128,
        icons = {
            {
                icon = "__base__/graphics/technology/concrete.png",
                tint = prefab_tint,
                icon_mipmaps = 4,
                icon_size = 256
            },
            {
                icon = "__base__/graphics/technology/electric-energy-distribution-1.png",
                priority = "medium",
                shift = {16, 0},
                scale = 0.6,
                icon_mipmaps = 4,
                icon_size = 256
            }
        }
    }
}