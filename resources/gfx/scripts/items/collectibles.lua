local Collectibles = {}

Collectibles.Items = {}

function Collectibles:Spawn(sprite, x, y)
    local item = {
        sprite = sprite,
        x = x,
        baseY = y,
        timer = math.random() * 10,
        bobHeight = 3,
        bobSpeed = 2,
        offsetY = 0
    }

    table.insert(self.Items, item)
end

function Collectibles:Update(dt)
    for _, item in ipairs(self.Items) do
        item.timer = item.timer + dt
        item.offsetY = math.sin(item.timer * item.bobSpeed) * item.bobHeight
    end
end

function Collectibles:Draw()
    for _, item in ipairs(self.Items) do

        -- shadow
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.ellipse(
            "fill",
            item.x,
            item.baseY + 10,
            10,
            4
        )

        -- item
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(
            item.sprite,
            math.floor(item.x),
            math.floor(item.baseY + item.offsetY),
            0,
            1,
            1,
            item.sprite:getWidth() / 2,
            item.sprite:getHeight() / 2
        )
    end
end

return Collectibles