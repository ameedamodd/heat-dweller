-- Scar enemy behavior and state.
local Enemy = {}
Enemy.__index = Enemy
local Wet = require('wet')

function Enemy.new(config)
  config = config or {}

  return setmetatable({
    kind = config.kind or 'scar',
    x = config.x or 1100,
    y = config.y or 600,
    width = 64,
    height = 64,
    health = 5.5,
    damage = 0.5,
    speed = config.speed or 90,
    aggroRadius = 260,
    contactRadius = 52,
    attackCooldown = 0,
    attackInterval = 0.75,
    aggravated = false,
    animationTime = 0,
    alive = true,
  }, Enemy)
end

function Enemy:update(dt, player)
  if not self.alive then
    return
  end
  local speedScale = Wet.update(self, dt)

  local distanceX = player.x - self.x
  local distanceY = player.y - self.y
  local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY)

  if not self.aggravated and distance <= self.aggroRadius then
    self.aggravated = true
    self.animationTime = 0
  end

  if self.aggravated then
    self.animationTime = self.animationTime + dt

    if distance > self.contactRadius and distance > 0 then
      self.x = self.x + distanceX / distance * self.speed * speedScale * dt
      self.y = self.y + distanceY / distance * self.speed * speedScale * dt
    end

    self.attackCooldown = math.max(0, self.attackCooldown - dt)
    if distance <= self.contactRadius and self.attackCooldown <= 0 then
      player:takeDamage(self.damage)
      self.attackCooldown = self.attackInterval
    end
  end
end

function Enemy:getFrame()
  if not self.aggravated then
    return 'idle_0'
  end

  return 'scream_' .. (math.floor(self.animationTime / 0.1) % 9)
end

return Enemy