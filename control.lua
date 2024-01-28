

script.on_event(defines.events.on_tick, function(e)
    if e.tick % 60 ~= 0 then return end
end)

script.on_event(defines.events.on_pre_build, function(e)
    -- Check that we are building a blueprint somehow?
    -- log(serpent.block{'----', e, e.name})
end)

script.on_event(defines.events.on_built_entity, function(e)
    log(serpent.block{e})
    local player = game.players[e.player_index]
    local inventory = player.get_inventory(defines.inventory.character_main)
    if not player.can_place_entity{ name = e.created_entity.ghost_name, position = e.created_entity.position, direction = e.created_entity.direction} then
        log("NO")
    end

  --      player.surface.create_entity{
  --          name = blueprintEntity.name,
  --          position = blueprintEntity.position,
  --          force = player.force,
  --          direction = blueprintEntity.direction,
  --      }
  --  for i, blueprintEntity in ipairs(e.stack.get_blueprint_entities()) do
  --  end
    -- log(serpent.block{e})
end, {{ filter = "ghost" }})