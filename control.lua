ARROW_ENTITY = "orphan-arrow"

function createArrowAt(entity)
  if global.arrows[entity.unit_number] ~= nil then
    -- entity already has arrow
    return
  end

  global.arrows[entity.unit_number] = {entity, entity.surface.create_entity{name = ARROW_ENTITY, position = entity.position}}
end

function hasAlerts(player, options)
  local alerts = player.get_alerts(options)
  for _,surface_alerts in pairs(alerts) do
    for _, typed_alerts in pairs(surface_alerts) do
      if next(typed_alerts) ~= nil then
        return true
      end
    end
  end
  return false
end

function clearArrows()
  for _,arrow in pairs(global.arrows) do
    arrow[2].destroy()
  end
  global.arrows = {}

  for _,player in pairs(game.connected_players) do
    -- remove_alert doesn't seem to remove all alerts, so run it repeatedly
    local has_alerts = true
    local i = 0
    while has_alerts do
      player.remove_alert{type=defines.alert_type.custom, message={"unconnected-pipe-finder.alert"}}
      has_alerts = hasAlerts(player, {type=defines.alert_type.custom, message={"unconnected-pipe-finder.alert"}})
      i = i + 1
      if i > 10 then
        has_alerts = false
      end
    end

  end
end

function createArrows()
  local count = 0
  for _, surface in pairs(game.surfaces) do
    for _, pipe in pairs(surface.find_entities_filtered{type = {"pipe", "pipe-to-ground"}}) do
      if not hasConnections(pipe, 2) then
        createArrowAt(pipe)
        count = count + 1
      end
    end
  end

  createAlerts()
  return count
end


function deleteArrowAt(entity)
  if global.arrows[entity.unit_number] ~= nil then
    for _,player in pairs(game.connected_players) do
      player.remove_alert{
        entity = global.arrows[entity.unit_number][1],
        type = defines.alert_type.custom,
        message = {"unconnected-pipe-finder.alert"}
      }
    end
    global.arrows[entity.unit_number][2].destroy()
    global.arrows[entity.unit_number] = nil
  end
end

function createAlerts()
  for _,player in pairs(game.connected_players) do
    for _,arrow in pairs(global.arrows) do
      player.add_custom_alert(
        arrow[1],
        {type="item",name=arrow[1].type},
        {"unconnected-pipe-finder.alert"},
        true
    )
    end
  end
end


function isPipe(entity)
  return (entity.type == "pipe") or (entity.type == "pipe-to-ground")
end

function hasConnections(pipe, connections)
  -- A pipe is connected if it is attached to at least two other fluid boxes
  return pipe.fluidbox.get_connections(1)[connections] ~= nil
end

function recalculateNeighbours(pipe, being_removed)
  -- When a pipe state changes, add or remove nearby arrows
  if not isPipe(pipe) then
    return
  end

  if being_removed or hasConnections(pipe, 2) then
    deleteArrowAt(pipe)
  else
    createArrowAt(pipe)
  end

  -- pipes being removed count as connected, so look for an additional neighbour
  local need_connections = (being_removed and 3 or 2)

  for _,box in pairs(pipe.fluidbox.get_connections(1)) do
    local entity = box.owner
    if isPipe(entity) then
      if hasConnections(entity, need_connections) then
        deleteArrowAt(entity)
      else
        createArrowAt(entity)
      end
    end

  end
end

script.on_event(defines.events.on_built_entity, function(event)
  if global.enabled then
    recalculateNeighbours(event.created_entity, false)
  end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  if global.enabled then
    recalculateNeighbours(event.created_entity, false)
  end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
  if global.enabled then
    recalculateNeighbours(event.entity, false)
  end
end)

script.on_event(defines.events.on_pre_player_mined_item, function(event)
  if global.enabled then
    recalculateNeighbours(event.entity, true)
  end
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
  if global.enabled then
    recalculateNeighbours(event.entity, true)
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if global.enabled then
    recalculateNeighbours(event.entity, true)
  end
end)

script.on_init(function ()
  global.arrows = {}
  global.enabled = false
end)

-- refresh alerts every 5 seconds
script.on_nth_tick(300, function ()
  if global.enabled then
    createAlerts()
  end
end)


script.on_event("toggle-show-unconnected-pipe", function()
  global.enabled = not global.enabled
  if not global.enabled then
    clearArrows()
    game.print{"unconnected-pipe-finder.disabled"}
  else
    local num_unconnected = createArrows()
    if num_unconnected == 0 then
      game.print{"unconnected-pipe-finder.found-none", num_unconnected}
    elseif num_unconnected == 1 then
      game.print{"unconnected-pipe-finder.found-one", num_unconnected}
    else
      game.print{"unconnected-pipe-finder.found-many", num_unconnected}
    end
  end
end)
