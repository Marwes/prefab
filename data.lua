local constants = require("constants")

local base = "medium-electric-pole"

local t = table.deepcopy(data.raw["electric-pole"][base])
t.name = constants.prefab_name
t.minable.result = constants.prefab_name

local i = table.deepcopy(data.raw["item"][base])
i.name = constants.prefab_name
i.place_result = constants.prefab_name
i.subgroup = "other" 
i.order = "a[prefab]-f[prefab]"
i.type = "item-with-tags"
i.collision_box = { { -constants.prefab_size, -constants.prefab_size }, { constants.prefab_size, constants.prefab_size } }
i.selection_box = { { -constants.prefab_size, -constants.prefab_size }, { constants.prefab_size, constants.prefab_size } }
i.collision_mask = { "item-layer", "object-layer", "water-tile", "layer-55" }
 
local r = table.deepcopy(data.raw["recipe"][base])
r.name = constants.prefab_name
r.result = constants.prefab_name

data:extend{t, i}

local prefab_tint = { r = 0.7, g = 0.7, b = 0.7, a = 1 }

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