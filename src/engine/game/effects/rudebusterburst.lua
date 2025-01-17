local RudeBusterBurst, super = Class(Sprite)

function RudeBusterBurst:init(red, x, y, angle, slow)
    super:init(self, red and "effects/rudebuster/beam_red" or "effects/rudebuster/beam", x, y)

    self:setOrigin(0.5, 0.5)
    self:setScale(2)

    self:fadeOutAndRemove()
    self:play(1/15, true)

    self.rotation = angle
    self.physics.speed = 25
    self.physics.match_rotation = true

    self.slow = slow
end

function RudeBusterBurst:update(dt)
    local slow_down = self.slow and 0.8 or 0.75

    self.physics.speed = self.physics.speed * (slow_down ^ DTMULT)
    self.scale_x = self.scale_x * (0.8 ^ DTMULT)

    super:update(self, dt)
end

return RudeBusterBurst