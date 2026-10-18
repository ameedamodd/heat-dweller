-- Heat Dweller - Game Logic
-- Main game state and logic in Lua
local Atlas = require('resources.data.character_atlas')

local Game = {}
Game.__index = Game

function Game.new()
  local self = setmetatable({}, Game)
  self.state = 'title'
  self.player = {
    x = 800,
    y = 600,
    width = 64,
    height = 64,
    speed = 220,
    facing = 'down',
    moving = false,
    animationTime = 0,
    frameSpeed = 0.08,
    blinkTime = 0,
    blinkDuration = 0.12,
    nextBlink = math.random() * 2 + 2,
    blinking = false,
  }
  
  self.stats = {
    speed = 220,
    damage = 25,
    attackSpeed = 1.0,
    defense = 10,
    health = 100,
    maxHealth = 100,
    mana = 50,
    maxMana = 50,
    experience = 0,
    level = 1,
  }
  
  self.input = {
    left = false,
    right = false,
    up = false,
    down = false,
  }
  
  self.world = {
    width = 1600,
    height = 1200,
    tileSize = 80,
    rows = 15,
    cols = 20,
  }
  
  self.camera = {
    x = 0,
    y = 0,
    width = 1024,
    height = 576,
  }

  self.atlas = Atlas

  self.animation = {
    idle = 'body_idle',
    walkHorizontal = {
      'walk_right_0', 'walk_right_1', 'walk_right_2',
      'walk_right_3', 'walk_right_4', 'walk_right_5',
    },
    walkVertical = {
      'walk_down_0', 'walk_down_1', 'walk_down_2',
      'walk_down_3', 'walk_down_4',
    },
  }
  
  return self
end

function Game:updateMovement(delta)
  local directionX = 0
  local directionY = 0

  if self.input.left then directionX = directionX - 1 end
  if self.input.right then directionX = directionX + 1 end
  if self.input.up then directionY = directionY - 1 end
  if self.input.down then directionY = directionY + 1 end

  local length = math.sqrt(directionX * directionX + directionY * directionY)
  local moved = length > 0

  if moved then
    local distance = self.player.speed * delta
    self.player.x = self.player.x + directionX / length * distance
    self.player.y = self.player.y + directionY / length * distance

    -- Horizontal input wins when both axes are held, matching the old behavior.
    if directionX < 0 then
      self.player.facing = 'left'
    elseif directionX > 0 then
      self.player.facing = 'right'
    elseif directionY < 0 then
      self.player.facing = 'up'
    else
      self.player.facing = 'down'
    end
  end

  self.player.moving = moved
  if self.player.moving then
    self.player.animationTime = self.player.animationTime + delta
  else
    self.player.animationTime = 0
  end
  
  if self.player.blinking then
    self.player.blinkTime = self.player.blinkTime + delta
    if self.player.blinkTime >= self.player.blinkDuration then
      self.player.blinking = false
      self.player.blinkTime = 0
      self.player.nextBlink = math.random() * 2 + 2
    end
  else
    self.player.nextBlink = self.player.nextBlink - delta
    if self.player.nextBlink <= 0 then
      self.player.blinking = true
      self.player.blinkTime = 0
    end
  end
end

function Game:clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

function Game:update(delta)
  self:updateMovement(delta)

  -- Keep the player's center inside the world.
  self.player.x = self:clamp(self.player.x, self.player.width / 2, self.world.width - self.player.width / 2)
  self.player.y = self:clamp(self.player.y, self.player.height / 2, self.world.height - self.player.height / 2)

  -- Follow the player while keeping the camera inside the world.
  self.camera.x = self:clamp(self.player.x - self.camera.width / 2, 0, self.world.width - self.camera.width)
  self.camera.y = self:clamp(self.player.y - self.camera.height / 2, 0, self.world.height - self.camera.height)
end

function Game:getBodyFrame()
  if not self.player.moving then
    return self.animation.idle
  end

  local frames
  if self.player.facing == 'left' or self.player.facing == 'right' then
    frames = self.animation.walkHorizontal
  else
    frames = self.animation.walkVertical
  end

  local index = math.floor(self.player.animationTime / self.player.frameSpeed) % #frames + 1
  return frames[index]
end

function Game:getHeadFrame()
  local frame = 'head_forward_1'
  if self.player.facing == 'up' then
    frame = 'head_back_1'
  elseif self.player.facing == 'left' or self.player.facing == 'right' then
    frame = 'head_right_1'
  end

  if self.player.blinking then
    frame = frame:gsub('_1$', '_blink')
  end

  return frame
end

function Game:getAtlasFrame(frameName)
  return self.atlas.frames[frameName]
end

function Game:getPlayerPosition()
  return math.floor(self.player.x), math.floor(self.player.y)
end

function Game:getPlayerFacing()
  return self.player.facing
end

function Game:getStats()
  return self.stats
end

return Game
