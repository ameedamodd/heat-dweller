local TheGeometric = {}
TheGeometric.__index = TheGeometric

local bodyBaseHealth = 480
local headHealth = 48
local recoveryDuration = 3
local finalHeadHealth = 150

local function configureHead(boss, head)
  head.kind = 'geometric_head'
  head.width = 128
  head.height = 128
  head.health = head.health or headHealth
  head.maxHealth = head.maxHealth or headHealth
  head.alive = head.alive ~= false
  head.geometricPart = true
  head.hitFlashTimer = head.hitFlashTimer or 0
  head.isInvulnerable = function(self)
    return not self.alive
  end
  head.takeDamage = function(self, amount)
    return boss:damageHead(self, amount)
  end
end

function TheGeometric.new(world)
  local boss = setmetatable({
    kind = 'geometric',
    projectilePassThroughWhenInvulnerable = true,
    x = world.width / 2,
    y = world.height / 2,
    width = 224,
    height = 224,
    radius = 112,
    health = bodyBaseHealth,
    maxHealth = bodyBaseHealth,
    bodyHealth = bodyBaseHealth,
    speed = 48,
    alive = true,
    bodyAlive = true,
    world = world,
    animationTime = 0,
    facing = 'forward',
    moving = false,
    contactCooldown = 0,
    phase = 'body',
    heads = {},
    headOrbitAngle = 0,
    headShatters = {},
    bodyInvulnerabilityTimer = 0,
    finalShakeTimer = 0,
    finalVx = 280,
    finalVy = -235,
  }, TheGeometric)
  boss:spawnHeads(1, true)
  return boss
end

function TheGeometric:spawnHeads(count, shieldBody)
  self.heads = {}
  self.shieldActive = shieldBody
  for index = 1, count do
    local head = {
      orbitOffset = (index - 1) * math.pi * 2 / count,
      health = headHealth,
      maxHealth = headHealth,
      alive = true,
    }
    configureHead(self, head)
    self.heads[#self.heads + 1] = head
  end
  self:updateHeadPositions()
end

function TheGeometric:updateHeadPositions()
  local count = #self.heads
  local orbitRadius = count == 1 and 176 or count == 2 and 190 or 208
  for _, head in ipairs(self.heads) do
    local angle = self.headOrbitAngle + head.orbitOffset
    head.x = self.x + math.cos(angle) * orbitRadius
    head.y = self.y + math.sin(angle) * orbitRadius
    head.facing = math.cos(angle) < 0 and 'left' or 'right'
  end
end

function TheGeometric:restoreRuntimeState()
  for _, head in ipairs(self.heads or {}) do
    configureHead(self, head)
  end
  self.heads = self.heads or {}
  self.headShatters = self.headShatters or {}
  self.finalShakeTimer = self.finalShakeTimer or 0
  self.bodyHealth = math.max(0, math.min(
    bodyBaseHealth,
    self.bodyHealth or self.health or bodyBaseHealth
  ))
  if self.phase == 'final' then
    self.maxHealth = self.finalHeadHealth or finalHeadHealth
    self.width = 256
    self.height = 256
    self.radius = 128
  else
    self.maxHealth = bodyBaseHealth
    self.width = 224
    self.height = 224
    self.radius = 112
    self.health = self.bodyHealth
  end
  local hasLivingHead = false
  for _, head in ipairs(self.heads) do
    if head.alive then
      hasLivingHead = true
      break
    end
  end
  self.shieldActive = hasLivingHead
    and (self.phase == 'body' or self.phase == 'split_two' or self.phase == 'split_four')
  self:updateHeadPositions()
end

function TheGeometric:damageHead(head, amount)
  if not self.alive or not head.alive or self.phase == 'body_recovery'
      or self.phase == 'body_final' or self.phase == 'final' then
    return false
  end

  head.hitFlashTimer = 0.14
  head.health = math.max(0, head.health - amount)
  if head.health <= 0 then
    head.alive = false
    self.headShatters[#self.headShatters + 1] = {
      x = head.x,
      y = head.y,
      timer = 0.45,
    }
    if self.onScreenShake then
      self.onScreenShake(6, 'head_destroyed')
    end
    local remainingHeads = false
    for _, candidate in ipairs(self.heads) do
      if candidate.alive then
        remainingHeads = true
        break
      end
    end
    if not remainingHeads and self.shieldActive then
      self.shieldActive = false
      if self.phase == 'split_two' then
        self.phase = 'body_after_two'
      elseif self.phase == 'split_four' then
        self.phase = 'body_after_four'
      end
    end
    return true
  end
  return false
end

function TheGeometric:isInvulnerable()
  return not self.alive or (self.phase ~= 'final' and not self.bodyAlive) or self.shieldActive
    or self.phase == 'body_recovery'
end

function TheGeometric:beginFinalPhase()
  self.phase = 'final'
  self.bodyAlive = false
  self.shieldActive = false
  self.heads = {}
  self.width = 256
  self.height = 256
  self.radius = 128
  self.health = finalHeadHealth
  self.finalHeadHealth = finalHeadHealth
  self.maxHealth = finalHeadHealth
  self.finalVx = self.finalVx < 0 and -330 or 330
  self.finalVy = self.finalVy < 0 and -295 or 295
end

function TheGeometric:takeDamage(amount)
  if not self.alive or self:isInvulnerable() then
    return false
  end

  if self.phase == 'final' then
    self.health = math.max(0, self.health - amount)
    if self.health <= 0 then
      self.alive = false
      return true
    end
    return false
  end

  self.bodyHealth = math.max(0, self.bodyHealth - amount)
  if self.phase == 'body' and self.bodyHealth <= self.maxHealth * 0.5 then
    self.bodyHealth = self.maxHealth * 0.5
    self.phase = 'split_two'
    self:spawnHeads(2, true)
    if self.onScreenShake then
      self.onScreenShake(10, 'split_two')
    end
  elseif self.phase == 'body_after_two' and self.bodyHealth <= self.maxHealth * 0.25 then
    self.bodyHealth = self.maxHealth * 0.25
    self.phase = 'split_four'
    self:spawnHeads(4, true)
    if self.onScreenShake then
      self.onScreenShake(13, 'split_four')
    end
  elseif self.phase == 'body_after_four' and self.bodyHealth <= self.maxHealth * 0.125 then
    self.bodyHealth = self.maxHealth * 0.125
    self.phase = 'body_recovery'
    self.bodyInvulnerabilityTimer = recoveryDuration
    self.heads = {}
  elseif self.phase == 'body_final' and self.bodyHealth <= 0 then
    self:beginFinalPhase()
  end

  if self.phase ~= 'final' then
    self.health = self.bodyHealth
  end
  return false
end

function TheGeometric:getTargets()
  local targets = {}
  if self.alive and (self.phase == 'final' or self.bodyAlive) then
    targets[#targets + 1] = self
  end
  if self.phase ~= 'body_recovery' and self.phase ~= 'body_final' and self.phase ~= 'final' then
    for _, head in ipairs(self.heads) do
      if head.alive then
        targets[#targets + 1] = head
      end
    end
  end
  return targets
end

local function bounceFromWalls(self, oldX, oldY, walls)
  for _, wall in ipairs(walls or {}) do
    local closestX = math.max(wall.x, math.min(self.x, wall.x + wall.width))
    local closestY = math.max(wall.y, math.min(self.y, wall.y + wall.height))
    local offsetX, offsetY = self.x - closestX, self.y - closestY
    if offsetX * offsetX + offsetY * offsetY < self.radius * self.radius then
      if oldX + self.radius <= wall.x or oldX - self.radius >= wall.x + wall.width then
        self.x = oldX
        self.finalVx = -self.finalVx
      elseif oldY + self.radius <= wall.y or oldY - self.radius >= wall.y + wall.height then
        self.y = oldY
        self.finalVy = -self.finalVy
      else
        self.x, self.y = oldX, oldY
        self.finalVx, self.finalVy = -self.finalVx, -self.finalVy
      end
    end
  end
end

function TheGeometric:update(dt, player, walls)
  if not self.alive then
    return
  end

  self.animationTime = self.animationTime + dt
  self.contactCooldown = math.max(0, self.contactCooldown - dt)
  for index = #self.headShatters, 1, -1 do
    local shatter = self.headShatters[index]
    shatter.timer = shatter.timer - dt
    if shatter.timer <= 0 then
      table.remove(self.headShatters, index)
    end
  end
  for _, head in ipairs(self.heads) do
    head.hitFlashTimer = math.max(0, (head.hitFlashTimer or 0) - dt)
  end
  if self.phase == 'final' then
    self.finalShakeTimer = (self.finalShakeTimer or 0) + dt
    while self.finalShakeTimer >= 0.12 do
      self.finalShakeTimer = self.finalShakeTimer - 0.12
      if self.onScreenShake then
        self.onScreenShake(2.5, 'final_bounce')
      end
    end
  end
  if self.phase == 'body_recovery' then
    self.bodyInvulnerabilityTimer = math.max(0, self.bodyInvulnerabilityTimer - dt)
    if self.bodyInvulnerabilityTimer <= 0 then
      self.phase = 'body_final'
    end
  end

  if self.phase == 'final' then
    local minX, maxX = self.radius, self.world.width - self.radius
    local minY, maxY = self.radius, self.world.height - self.radius
    local stepCount = math.max(
      1,
      math.ceil(math.max(math.abs(self.finalVx), math.abs(self.finalVy)) * dt / 8)
    )
    local step = dt / stepCount
    for _ = 1, stepCount do
      local oldX, oldY = self.x, self.y
      self.x = self.x + self.finalVx * step
      self.y = self.y + self.finalVy * step
      if self.x < minX then
        self.x = minX + (minX - self.x)
        self.finalVx = math.abs(self.finalVx)
      elseif self.x > maxX then
        self.x = maxX - (self.x - maxX)
        self.finalVx = -math.abs(self.finalVx)
      end
      if self.y < minY then
        self.y = minY + (minY - self.y)
        self.finalVy = math.abs(self.finalVy)
      elseif self.y > maxY then
        self.y = maxY - (self.y - maxY)
        self.finalVy = -math.abs(self.finalVy)
      end
      bounceFromWalls(self, oldX, oldY, walls)
    end
    self.moving = true
  else
    local offsetX, offsetY = player.x - self.x, player.y - self.y
    local distance = math.sqrt(offsetX * offsetX + offsetY * offsetY)
    local playerRadius = math.max(player.width, player.height) / 2
    local collisionDistance = self.radius + playerRadius
    local stoppingDistance = collisionDistance - 4
    self.moving = distance > stoppingDistance

    if self.moving and distance > 0 then
      local movement = math.min(self.speed * dt, distance - stoppingDistance)
      self.x = self.x + offsetX / distance * movement
      self.y = self.y + offsetY / distance * movement
      if math.abs(offsetX) > math.abs(offsetY) then
        self.facing = offsetX < 0 and 'left' or 'right'
      else
        self.facing = 'forward'
      end
    end

    local boundary = self.radius
    self.x = math.max(boundary, math.min(self.world.width - boundary, self.x))
    self.y = math.max(boundary, math.min(self.world.height - boundary, self.y))
    self.headOrbitAngle = self.headOrbitAngle + dt * (self.shieldActive and 1.8 or 1.1)
    self:updateHeadPositions()

    offsetX, offsetY = player.x - self.x, player.y - self.y
    if offsetX * offsetX + offsetY * offsetY <= collisionDistance * collisionDistance
        and self.contactCooldown <= 0 then
      player:takeDamage(10)
      self.contactCooldown = 1
    end
  end

  if self.phase == 'final' then
    local offsetX, offsetY = player.x - self.x, player.y - self.y
    local playerRadius = math.max(player.width, player.height) / 2
    local contactDistance = self.radius + playerRadius
    if offsetX * offsetX + offsetY * offsetY <= contactDistance * contactDistance
        and self.contactCooldown <= 0 then
      player:takeDamage(10)
      self.contactCooldown = 0.65
    end
  end
end

function TheGeometric:getFrame()
  if self.phase == 'final' then
    return self.animationTime % 1.5 < 0.12 and 'headForwardBlink' or 'headForward'
  end
  if self.moving then
    return math.floor(self.animationTime / 0.18) % 2 == 0 and 'bodyWalk' or 'bodyWalkAlt'
  end
  if self.facing == 'right' or self.facing == 'left' then
    return self.animationTime % 4 < 0.14 and 'headRightBlink' or 'headRight'
  end
  return self.animationTime % 4 < 0.14 and 'headForwardBlink' or 'headForward'
end

return TheGeometric
