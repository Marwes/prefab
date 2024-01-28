local constants = require("constants")

local t = table.deepcopy(data.raw["lamp"]["small-lamp"])
t.name = constants.prefab_name
t.minable.result = constants.prefab_name

local i = table.deepcopy(data.raw["item"]["small-lamp"])
i.name = constants.prefab_name
i.place_result = constants.prefab_name
i.subgroup = "other" 
i.order = "a[prefab]-f[prefab]"
i.type = "item-with-tags"
 
local r = table.deepcopy(data.raw["recipe"]["small-lamp"])
r.name = constants.prefab_name
r.result = constants.prefab_name

data:extend{t, i}