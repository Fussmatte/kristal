local DarkEquipMenu, super = Class(Object)

function DarkEquipMenu:init()
    super:init(self, 82, 112, 477, 277)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow")

    self.caption_sprites = {
            ["char"] = Assets.getTexture("ui/menu/caption_char"),
        ["equipped"] = Assets.getTexture("ui/menu/caption_equipped"),
           ["stats"] = Assets.getTexture("ui/menu/caption_stats"),
         ["weapons"] = Assets.getTexture("ui/menu/caption_weapons"),
          ["armors"] = Assets.getTexture("ui/menu/caption_armors"),
    }

    self.stat_icons = {
         ["attack"] = Assets.getTexture("ui/menu/icon/sword"),
        ["defense"] = Assets.getTexture("ui/menu/icon/armor"),
          ["magic"] = Assets.getTexture("ui/menu/icon/magic"),
    }

    self.armor_icons = {
        Assets.getTexture("ui/menu/equip/armor_1"),
        Assets.getTexture("ui/menu/equip/armor_2"),
    }

    self.bg = DarkBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self:addChild(self.bg)

    self.party = DarkMenuPartySelect(8, 48)
    self.party.focused = true
    self:addChild(self.party)

    -- PARTY, SLOTS, ITEMS
    self.state = "PARTY"

    self.selected_slot = 1

    self.selected_item = {
        ["weapon"] = 1,
        ["armor"] = 1
    }
    self.item_scroll = {
        ["weapon"] = 1,
        ["armor"] = 1
    }
end

function DarkEquipMenu:getCurrentItemType()
    if self.selected_slot == 1 then
        return "weapon"
    else
        return "armor"
    end
end

function DarkEquipMenu:getSelectedItem()
    local type = self:getCurrentItemType()
    return Game.inventory:getItem(type, self.selected_item[type])
end

function DarkEquipMenu:getMaxItems()
    local type = self:getCurrentItemType()
    return Game.inventory:getStorage(type, self.selected_item[type]).max
end

function DarkEquipMenu:canEquipSelected()
    local item = self:getSelectedItem()
    if item then
        local can_equip = item.can_equip[self.party:getSelected().id]
        if item.type == "weapon" then
            return can_equip or false
        elseif item.type == "armor" then
            return can_equip or can_equip == nil
        end
    elseif self:getCurrentItemType() == "weapon" or self.party:getSelected().id == "susie" then -- TODO: unhardcode
        return false
    end
    return true
end

function DarkEquipMenu:getEquipPreview()
    local party = self.party:getSelected()
    local equipped = {}
    local item = self:getSelectedItem()
    if self.selected_slot == 1 then
        equipped[1] = item
    elseif party.equipped.weapon then
        equipped[1] = Registry.getItem(party.equipped.weapon)
    end
    for i = 1, 2 do
        if self.selected_slot == i+1 then
            equipped[i+1] = item
        elseif party.equipped.armor[i] then
            equipped[i+1] = Registry.getItem(party.equipped.armor[i])
        end
    end
    return equipped
end

function DarkEquipMenu:getStatsPreview()
    local party = self.party:getSelected()
    local current_stats = party:getStats()
    if self.state == "ITEMS" and self:canEquipSelected() then
        local preview_stats = Utils.copy(party.stats)
        local equipment = self:getEquipPreview()
        for i = 1, 3 do
            if equipment[i] then
                for stat,amount in pairs(equipment[i].bonuses) do
                    if preview_stats[stat] then
                        preview_stats[stat] = preview_stats[stat] + amount
                    end
                end
            end
        end
        return preview_stats, current_stats
    else
        return current_stats, current_stats
    end
end

function DarkEquipMenu:getAbilityPreview()
    local party = self.party:getSelected()
    local current_abilities = {}
    if party.equipped.weapon then
        local item = Registry.getItem(party.equipped.weapon)
        if item.bonus_name then
            current_abilities[1] = {name = item.bonus_name, icon = item.bonus_icon}
        end
    end
    for i = 1, 2 do
        if party.equipped.armor[i] then
            local item = Registry.getItem(party.equipped.armor[i])
            if item.bonus_name then
                current_abilities[i+1] = {name = item.bonus_name, icon = item.bonus_icon}
            end
        end
    end
    if self.state == "ITEMS" and self:canEquipSelected() then
        local preview_abilities = {}
        local equipment = self:getEquipPreview()
        for i = 1, 3 do
            if equipment[i] and equipment[i].bonus_name then
                preview_abilities[i] = {name = equipment[i].bonus_name, icon = equipment[i].bonus_icon}
            end
        end
        return preview_abilities, current_abilities
    else
        return current_abilities, current_abilities
    end
end

function DarkEquipMenu:react()
    local item, party = self:getSelectedItem(), self.party:getSelected()

    if item then
        local reactions = item:getReactions(party.id)
        for name, reaction in pairs(reactions) do
            for index, chara in ipairs(Game.party) do
                if name == chara.id then
                    Game.world.healthbar.action_boxes[index].reaction_alpha = 50
                    Game.world.healthbar.action_boxes[index].reaction_text = reaction
                end
            end
        end
    elseif party.id == "susie" then -- TODO: unhardcode
        for index, chara in ipairs(Game.party) do
            if chara.id == party.id then
                Game.world.healthbar.action_boxes[index].reaction_alpha = 50
                Game.world.healthbar.action_boxes[index].reaction_text = "Hey, hands off!"
            end
        end
    end
end

function DarkEquipMenu:updateDescription()
    if self.state == "PARTY" then
        Game.world.menu:setDescription("", false)
    elseif self.state == "SLOTS" then
        local party = self.party:getSelected()
        local item
        if self.selected_slot == 1 then
            item = party:getWeapon()
        else
            item = party:getArmor(self.selected_slot - 1)
        end
        Game.world.menu:setDescription(item and item.description or "", true)
    elseif self.state == "ITEMS" then
        local item = self:getSelectedItem()
        Game.world.menu:setDescription(item and item.description or "", true)
    end
end

function DarkEquipMenu:onRemove(parent)
    super:onRemove(parent)
    Game.world.menu:updateSelectedBoxes()
end

function DarkEquipMenu:update(dt)
    if self.state == "PARTY" then
        if Input.pressed("cancel") then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            Game.world.menu:closeBox()
            return
        elseif Input.pressed("confirm") then
            self.state = "SLOTS"

            self.party.focused = false

            self.ui_select:stop()
            self.ui_select:play()

            self.selected_slot = 1
            self:updateDescription()
        end
    elseif self.state == "SLOTS" then
        if Input.pressed("cancel") then
            self.state = "PARTY"

            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            self.party.focused = true
            self:updateDescription()
            return
        elseif Input.pressed("confirm") then
            self.state = "ITEMS"

            self.ui_select:stop()
            self.ui_select:play()

            love.keyboard.setKeyRepeat(true)
            self:updateDescription()
        end
        local old_selected = self.selected_slot
        if Input.pressed("up") then
            self.selected_slot = self.selected_slot - 1
        end
        if Input.pressed("down") then
            self.selected_slot = self.selected_slot + 1
        end
        self.selected_slot = (self.selected_slot - 1) % 3 + 1
        if old_selected ~= self.selected_slot then
            self.ui_move:stop()
            self.ui_move:play()
            self:updateDescription()
        end
    elseif self.state == "ITEMS" then
        if Input.pressed("cancel") then
            self.state = "SLOTS"

            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            love.keyboard.setKeyRepeat(false)
            self:updateDescription()
            return
        end
        local type = self:getCurrentItemType()
        local max_items = self:getMaxItems()
        local old_selected = self.selected_item[type]
        if Input.pressed("up") then
            self.selected_item[type] = self.selected_item[type] - 1
        end
        if Input.pressed("down") then
            self.selected_item[type] = self.selected_item[type] + 1
        end
        self.selected_item[type] = Utils.clamp(self.selected_item[type], 1, max_items)
        if self.selected_item[type] ~= old_selected then
            local min_scroll = math.max(1, self.selected_item[type] - 5)
            local max_scroll = math.min(math.max(1, max_items - 5), self.selected_item[type])
            self.item_scroll[type] = Utils.clamp(self.item_scroll[type], min_scroll, max_scroll)

            self.ui_move:stop()
            self.ui_move:play()

            self:updateDescription()
        end
        if Input.pressed("confirm") then
            self:react()
            local item, party = self:getSelectedItem(), self.party:getSelected()
            if not self:canEquipSelected() then
                self.ui_cant_select:stop()
                self.ui_cant_select:play()
            else
                Assets.playSound("snd_equip")
                local swap_with
                if self.selected_slot == 1 then
                    swap_with = party.equipped.weapon
                    party.equipped.weapon = item and item.id or nil
                else
                    swap_with = party.equipped.armor[self.selected_slot-1]
                    party.equipped.armor[self.selected_slot-1] = item and item.id or nil
                end
                Game.inventory:replaceItem(type, swap_with and Registry.getItem(swap_with) or nil, self.selected_item[type])

                self.state = "SLOTS"
                love.keyboard.setKeyRepeat(false)
                self:updateDescription()
            end
        end
    end
    super:update(self, dt)
end

function DarkEquipMenu:draw(dt)
    love.graphics.setFont(self.font)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 188, -24,  6,  139)
    love.graphics.rectangle("fill", -24, 109, 58,  6)
    love.graphics.rectangle("fill", 130, 109, 160, 6)
    love.graphics.rectangle("fill", 422, 109, 81,  6)
    love.graphics.rectangle("fill", 241, 109, 6,   192)

    love.graphics.draw(self.caption_sprites[    "char"],  36, -26, 0, 2, 2)
    love.graphics.draw(self.caption_sprites["equipped"], 294, -26, 0, 2, 2)
    love.graphics.draw(self.caption_sprites[   "stats"],  34, 104, 0, 2, 2)
    if self.selected_slot == 1 then
        love.graphics.draw(self.caption_sprites["weapons"], 290, 104, 0, 2, 2)
    else
        love.graphics.draw(self.caption_sprites["armors"], 290, 104, 0, 2, 2)
    end

    self:drawChar()
    self:drawEquipped()
    self:drawItems()
    self:drawStats()

    super:draw(self)
end

function DarkEquipMenu:drawChar()
    local party = self.party:getSelected()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(party.name, 53, -5)
end

function DarkEquipMenu:drawEquipped()
    local party = self.party:getSelected()
    love.graphics.setColor(1, 1, 1, 1)

    if self.state ~= "SLOTS" or self.selected_slot ~= 1 then
        local weapon_icon = Assets.getTexture(party.weapon_icon)
        if weapon_icon then
            love.graphics.draw(weapon_icon, 220, -4, 0, 2, 2)
        end
    end
    if self.state ~= "SLOTS" or self.selected_slot ~= 2 then love.graphics.draw(self.armor_icons[1], 220, 30, 0, 2, 2) end
    if self.state ~= "SLOTS" or self.selected_slot ~= 3 then love.graphics.draw(self.armor_icons[2], 220, 60, 0, 2, 2) end

    if self.state == "SLOTS" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.draw(self.heart_sprite, 226, 10 + ((self.selected_slot - 1) * 30))
    end

    for i = 1, 3 do
        self:drawEquippedItem(i, 261, 6 + ((i - 1) * 30))
    end
end

function DarkEquipMenu:drawEquippedItem(index, x, y)
    local party = self.party:getSelected()
    local item
    if index == 1 then
        item = party:getWeapon()
    else
        item = party:getArmor(index-1)
    end
    if item then
        love.graphics.setColor(1, 1, 1)
        if item.icon and Assets.getTexture(item.icon) then
            love.graphics.draw(Assets.getTexture(item.icon), x, y, 0, 2, 2)
        end
        love.graphics.print(item.name, x + 22, y - 6)
    else
        love.graphics.setColor(0.25, 0.25, 0.25)
        love.graphics.print("(Nothing)", x + 22, y - 6)
    end
end

function DarkEquipMenu:drawItems()
    local type = self:getCurrentItemType()
    local party = self.party:getSelected()
    local items = Game.inventory:getStorage(type)

    local x, y = 282, 124

    local scroll = self.item_scroll[type]
    for i = scroll, math.min(items.max, scroll + 5) do
        local item = items[i]
        local offset = i - scroll

        if item then
            local usable = false
            if item.type == "weapon" then
                usable = item.can_equip[party.id]
            else
                usable = item.can_equip[party.id] or item.can_equip[party.id] == nil
            end
            if usable then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            if item.icon and Assets.getTexture(item.icon) then
                love.graphics.draw(Assets.getTexture(item.icon), x, y + (offset * 27), 0, 2, 2)
            end
            love.graphics.print(item.name, x + 20, y + (offset * 27) - 6)
        else
            love.graphics.setColor(0.25, 0.25, 0.25)
            love.graphics.print("---------", x + 20, y + (offset * 27) - 6)
        end
    end

    if self.state == "ITEMS" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.draw(self.heart_sprite, x - 20, y + 4 + ((self.selected_item[type] - scroll) * 27))

        if items.max > 6 then
            love.graphics.setColor(1, 1, 1)
            local sine_off = math.sin((love.timer.getTime()*30)/12) * 3
            if scroll + 6 <= items.max then
                love.graphics.draw(self.arrow_sprite, x + 187, y + 149 + sine_off)
            end
            if scroll > 1 then
                love.graphics.draw(self.arrow_sprite, x + 187, y + 14 - sine_off, 0, 1, -1)
            end
            love.graphics.setColor(0.25, 0.25, 0.25)
            love.graphics.rectangle("fill", x + 191, y + 24, 6, 119)
            local percent = (scroll - 1) / (items.max - 6)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", x + 191, y + 24 + math.floor(percent * (119-6)), 6, 6)
        end
    end
end

function DarkEquipMenu:drawStats()
    local party = self.party:getSelected()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.stat_icons[ "attack"], -8, 124, 0, 2, 2)
    love.graphics.draw(self.stat_icons["defense"], -8, 151, 0, 2, 2)
    love.graphics.draw(self.stat_icons[  "magic"], -8, 178, 0, 2, 2)
    love.graphics.print( "Attack:", 18, 118)
    love.graphics.print("Defense:", 18, 145)
    love.graphics.print(  "Magic:", 18, 172)
    local stats, compare = self:getStatsPreview()
    self:drawStatPreview( "attack", 148, 118, stats, compare)
    self:drawStatPreview("defense", 148, 145, stats, compare)
    self:drawStatPreview(  "magic", 148, 172, stats, compare)
    local abilities, ability_comp = self:getAbilityPreview()
    for i = 1, 3 do
        self:drawAbilityPreview(i, -8, 178 + (27 * i), abilities, ability_comp)
    end
end

function DarkEquipMenu:drawStatPreview(stat, x, y, stats, compare)
    local stat_num = stats[stat] or 0
    local comp_num = compare[stat] or 0
    if stat_num > comp_num then
        love.graphics.setColor(1, 1, 0)
    elseif stat_num < comp_num then
        love.graphics.setColor(1, 0, 0)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.print(stat_num, x, y)
end

function DarkEquipMenu:drawAbilityPreview(index, x, y, abilities, compare)
    local name = abilities[index] and abilities[index].name or nil
    local comp_name = compare[index] and compare[index].name or nil
    if abilities[index] and abilities[index].icon then
        local yoff = self.state == "ITEMS" and -6 or 2
        local texture = Assets.getTexture(abilities[index].icon)
        if texture then
            love.graphics.setColor(255/255, 160/255, 64/255)
            love.graphics.draw(texture, x, y + yoff, 0, 2, 2)
        end
    end
    if name ~= comp_name then
        if name ~= nil then
            love.graphics.setColor(1, 1, 0)
        else
            love.graphics.setColor(1, 0, 0)
        end
    else
        if (name and self.state ~= "ITEMS") or (self.state == "ITEMS" and self.selected_slot == index and self:canEquipSelected()) then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.25, 0.25, 0.25)
        end
    end
    love.graphics.print(name or "(No ability.)", x + 26, y - 6)
end

return DarkEquipMenu