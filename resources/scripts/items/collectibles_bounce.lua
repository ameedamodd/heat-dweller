-- Heat Dweller Collectibles Bounce Animation
-- Handles collectible spawning and bouncing animation logic

local Collectibles = {}

-- Collectible definitions
local COLLECTIBLE_TYPES = {
  burnt_chilli = {
    id = 1,
    name = "Burnt Chilli",
    sprite = "collectibles_001_burntchilli.png",
    bobSpeed = 2.0,
    bobHeight = 3
  },
  light_bulb = {
    id = 2,
    name = "Light Bulb",
    sprite = "collectibles_002_lightbulb.png",
    bobSpeed = 1.8,
    bobHeight = 4
  },
  wet_sock = {
    id = 3,
    name = "Wet Sock",
    sprite = "collectibles_003_wetsock.png",
    bobSpeed = 2.2,
    bobHeight = 2
  },
  dead_spider = {
    id = 4,
    name = "Dead Spider",
    sprite = "collectibles_004_deadspider.png",
    bobSpeed = 1.5,
    bobHeight = 5
  },
  mysterious_key = {
    id = 5,
    name = "Mysterious Key",
    sprite = "collectibles_005_mysteriouskey.png",
    bobSpeed = 2.5,
    bobHeight = 3
  },
  playdough = {
    id = 6,
    name = "Playdough",
    sprite = "collectibles_006_playdough.png",
    bobSpeed = 1.2,
    bobHeight = 6
  },
  playdough_shotgun = {
    id = 7,
    name = "Playdough Shotgun",
    sprite = "collectibles_007_playdoughshotgun.png",
    bobSpeed = 2.0,
    bobHeight = 3
  },
  playdough_cake = {
    id = 8,
    name = "Playdough Cake",
    sprite = "collectibles_008_playdoughcake.png",
    bobSpeed = 1.8,
    bobHeight = 4
  },
  playdough_shield = {
    id = 9,
    name = "Playdough Shield",
    sprite = "collectibles_009_playdoughshield.png",
    bobSpeed = 1.5,
    bobHeight = 5
  },
  molotov = {
    id = 12,
    name = "Molotov",
    sprite = "collectibles_012_molotov.png",
    bobSpeed = 2.3,
    bobHeight = 2
  },
  charger = {
    id = 13,
    name = "Charger",
    sprite = "collectibles_013_charger.png",
    bobSpeed = 2.0,
    bobHeight = 3
  },
  duality = {
    id = 14,
    name = "Duality",
    sprite = "collectibles_014_duality.png",
    bobSpeed = 1.9,
    bobHeight = 4
  },
  garlic = {
    id = 15,
    name = "Garlic",
    sprite = "collectibles_015_garlic.png",
    bobSpeed = 2.1,
    bobHeight = 3
  },
  snowman = {
    id = 16,
    name = "Snowman",
    sprite = "collectibles_016_snowman.png",
    bobSpeed = 1.6,
    bobHeight = 4
  },
  utensils = {
    id = 17,
    name = "Utensils",
    sprite = "collectibles_017_utensils.png",
    bobSpeed = 2.0,
    bobHeight = 3
  }
}

-- Initialize collectibles list
Collectibles.items = {}
Collectibles.nextId = 0

-- Spawn a collectible at the given position
-- Reusable Bounce component (frame-rate independent physics-style bounce)
local Bounce = {}

local GRAVITY = 900 -- pixels per second^2

local QUALITY_PARAMS = {
  -- quality: initialVy, restitution
  { vy = 80,  rest = 0.35 }, -- 0 weakest
  { vy = 140, rest = 0.45 }, -- 1 low
  { vy = 220, rest = 0.55 }, -- 2 medium
  { vy = 320, rest = 0.66 }, -- 3 high
  { vy = 420, rest = 0.76 }, -- 4 extreme
}

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

function Bounce.new(quality)
  quality = quality or 1
  quality = clamp(quality, 0, 4)
  local p = QUALITY_PARAMS[quality + 1]
  return {
    y = 0,             -- offset above ground
    vy = p.vy,         -- initial upward velocity
    rest = p.rest,
    quality = quality,
    impactTimer = 0,
    settled = false,
    scaleX = 1,        -- for squash/stretch
    scaleY = 1,
  }
end

function Bounce.update(bc, dt)
  if not bc or bc.settled then
    return
  end

  -- integrate
  bc.vy = bc.vy - GRAVITY * dt
  bc.y = bc.y + bc.vy * dt

  -- impact
  if bc.y <= 0 then
    -- compute impact energy
    local impactEnergy = math.abs(bc.vy)
    if impactEnergy < 60 then
      -- small impact -> settle
      bc.y = 0
      bc.vy = 0
      bc.settled = true
      bc.impactTimer = 0.08
    else
      -- bounce
      bc.y = 0
      bc.vy = -bc.vy * bc.rest
      bc.impactTimer = 0.12
    end
  end

  -- update scales based on motion or impact
  if bc.impactTimer and bc.impactTimer > 0 then
    -- squash on impact proportional to recent energy
    local energy = clamp(math.min(math.abs(bc.vy) / 500, 1.0), 0, 1)
    local squashX = 1.0 + 0.35 * energy
    local squashY = 1.0 - 0.35 * energy
    bc.scaleX = squashX
    bc.scaleY = squashY
    bc.impactTimer = bc.impactTimer - dt
  else
    -- stretch on upward motion, normalize when slow
    local upEnergy = 0
    if bc.vy > 0 then
      upEnergy = clamp(bc.vy / 600, 0, 1)
      bc.scaleX = clamp(1.0 - 0.15 * upEnergy, 0.6, 1.2)
      bc.scaleY = clamp(1.0 + 0.3 * upEnergy, 0.8, 1.6)
    else
      -- easing back to normal
      bc.scaleX = bc.scaleX + (1.0 - bc.scaleX) * math.min(dt * 10, 1)
      bc.scaleY = bc.scaleY + (1.0 - bc.scaleY) * math.min(dt * 10, 1)
    end
  end
end

function Bounce.getTransform(bc)
  if not bc then return 0,1,1 end
  return bc.y, bc.scaleX, bc.scaleY
end


-- Spawn a collectible at the given position
function Collectibles:spawn(collectibleType, x, y, quality)
  local typeData = COLLECTIBLE_TYPES[collectibleType]
  if not typeData then
    error("Unknown collectible type: " .. tostring(collectibleType))
    return nil
  end

  quality = quality or typeData.quality or 1

  local collectible = {
    id = self.nextId,
    type = collectibleType,
    typeData = typeData,
    x = x,
    y = y,
    baseY = y,
    bounce = Bounce.new(quality),
    active = true,
    spawnTime = os.time()
  }

  self.nextId = self.nextId + 1
  table.insert(self.items, collectible)
  return collectible
end

-- Update all collectibles
function Collectibles:update(dt)
  for i, collectible in ipairs(self.items) do
    if collectible.active then
      if collectible.bounce then
        Bounce.update(collectible.bounce, dt)
        local oy, sx, sy = Bounce.getTransform(collectible.bounce)
        collectible.offsetY = oy
        collectible.scaleX = sx
        collectible.scaleY = sy
      else
        -- fallback to old bobbing behaviour
        collectible.timer = (collectible.timer or 0) + dt
        collectible.offsetY = math.sin(collectible.timer * (collectible.bobSpeed or 2.0)) * (collectible.bobHeight or 3)
        collectible.scaleX = 1
        collectible.scaleY = 1
      end
    end
  end
end

-- Get collectible by ID
function Collectibles:getById(id)
  for _, collectible in ipairs(self.items) do
    if collectible.id == id then
      return collectible
    end
  end
  return nil
end

-- Remove collectible by ID
function Collectibles:removeById(id)
  for i, collectible in ipairs(self.items) do
    if collectible.id == id then
      table.remove(self.items, i)
      return true
    end
  end
  return false
end

-- Get all active collectibles
function Collectibles:getActive()
  local active = {}
  for _, collectible in ipairs(self.items) do
    if collectible.active then
      table.insert(active, collectible)
    end
  end
  return active
end

-- Clear all collectibles
function Collectibles:clear()
  self.items = {}
  self.nextId = 0
end

-- Get collectible type data
function Collectibles:getTypeData(collectibleType)
  return COLLECTIBLE_TYPES[collectibleType]
end

-- Get all collectible types
function Collectibles:getAllTypes()
  return COLLECTIBLE_TYPES
end

return Collectibles
