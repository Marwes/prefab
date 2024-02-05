
local exports = {}

exports.prefab = {
    ["prefab"] = {
        size = 7,
        name = "prefab",
        build_name = "prefab-build",
    },
    ["prefab-9x9"] = {
        size = 9,
        name = "prefab-9x9",
        build_name = "prefab-build-9x9",
    }
}

exports.prefab_name = "prefab"
-- Dummy entity only used to emulate a large bounding box when placing the prefab so entities do not overlap
exports.prefab_build_name = "prefab-build"
exports.prefab_size = 7
exports.prefab_tile_name = "prefab-tile"

function exports.build_name_to_prefab_name(name)
    return name:gsub("-build", "")
end

return exports