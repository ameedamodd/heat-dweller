local AcidProjectile = {}
AcidProjectile.__index = AcidProjectile

function AcidProjectile.new(x, y, targetX, targetY)
  local distanceX = targetX - x
  local distanceY = targetY - y
  local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
  local speed = 420

  if distance == 0 then
    distance = 1
  end

  return setmetatable({
    x = x,
    y = y,
    velocityX = distanceX / distance * speed,
    velocityY = distanceY / distance * speed,
    radius = 14,
    damage = 8,
    lifetime = 3,
    alive = true,
  }, AcidProjectile)
end

function AcidProjectile:update(dt, player)
  if not self.alive then
    return
  end

  self.x = self.x + self.velocityX * dt
  self.y = self.y + self.velocityY * dt
  self.lifetime = self.lifetime - dt

  local distanceX = player.x - self.x
  local distanceY = player.y - self.y
  local hitRadius = self.radius + math.max(player.width, player.height) / 2
  if distanceX * distanceX + distanceY * distanceY <= hitRadius * hitRadius then
    player:takeDamage(self.damage)
    self.alive = false
  elseif self.lifetime <= 0 then
    self.alive = false
  end
end

return AcidProjectile