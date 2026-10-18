local Wet = {}

function Wet.apply(entity, duration)
  entity.wetSlowRemaining = math.max(entity.wetSlowRemaining or 0, duration)
end

function Wet.update(entity, dt)
  entity.wetSlowRemaining = math.max(0, (entity.wetSlowRemaining or 0) - dt)
  return entity.wetSlowRemaining > 0 and 0.5 or 1
end

return Wet
