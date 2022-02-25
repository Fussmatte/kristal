local SmallFaceText, super = Class(Object)

function SmallFaceText:init(text, face, x, y, actor)
    super:init(self, x, y)

    self.alpha = 0

    self.sprite = Sprite(face, 40, 0, nil, nil, actor and actor.portrait_path or "")
    self.sprite.inherit_color = true
    self:addChild(self.sprite)

    self.text = Text("", 40+70, 10)
    self.text.font_size = 12
    self.text.inherit_color = true
    self.text:setText(text)
    self:addChild(self.text)
end

function SmallFaceText:update(dt)
    if self.alpha < 1 then
        self.alpha = Utils.approach(self.alpha, 1, 0.2*DTMULT)
    end
    if self.sprite.x > 0 then
        self.sprite.x = Utils.approach(self.sprite.x, 0, 10*DTMULT)
        self.text.x = self.sprite.x + 70
    end
    super:update(self, dt)
end

return SmallFaceText