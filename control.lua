local constants = require("constants")

local prefab = require("control/prefab")

script.on_event(defines.events.on_tick, function(e)
    if e.tick % 60 ~= 0 then return end
end)

script.on_event(defines.events.on_pre_build, function(e)
    -- Check that we are building a blueprint somehow?
    -- log(serpent.block{'----', e, e.name})
end)

local function is_prefab(entity)
    return entity.name:find("^prefab") ~= nil
end

script.on_event(defines.events.on_built_entity, function(e)
    if is_prefab(e.created_entity) then
        prefab.on_built_entity(e)
        return
    end
end)

script.on_event(defines.events.on_robot_built_entity, function(e)
    if is_prefab(e.created_entity) then
        prefab.on_built_entity(e)
        return
    end
end)

script.on_event(defines.events.on_pre_player_mined_item, function(e)
    -- log(serpent.block{e})
    if is_prefab(e.entity) and prefab.on_pre_player_mined_item  then
        prefab.on_pre_player_mined_item(e)
        return
    end
end)

script.on_event(defines.events.on_player_mined_entity, function(e)
    -- log(serpent.block{e})
    if is_prefab(e.entity) and prefab.on_player_mined_entity then
        prefab.on_player_mined_entity(e)
        return
    end
end)

script.on_event(defines.events.on_robot_mined_entity, function(e)
    -- log(serpent.block{e})
    if is_prefab(e.entity) and prefab.on_player_mined_entity then
        prefab.on_player_mined_entity(e)
        return
    end
end)

script.on_event(defines.events.on_player_built_tile, function(e)
    -- log(serpent.block{e})
    if  prefab.on_player_built_tile then
        prefab.on_player_built_tile(e)
        return
    end
end)

script.on_event(defines.events.on_player_mined_tile, function(e)
    -- log(serpent.block{e})
    if  prefab.on_player_mined_tile then
        prefab.on_player_mined_tile(e)
        return
    end
end)