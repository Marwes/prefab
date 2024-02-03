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
 
local r = table.deepcopy(data.raw["recipe"][base])
r.name = constants.prefab_name
r.result = constants.prefab_name

data:extend{t, i}