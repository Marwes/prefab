
local function find_field(t, n, path)
    if type(t) ~= "table" then return end
    if path == nil then path = "" end
    for k, v in pairs(t) do
        if k == n then
            log(serpent.block{path, k})
        end
        if type(t) == "table" then
            find_field(v, n, path .. "." .. k)
        end
    end
end

find_field(data.raw, "created_smoke")
