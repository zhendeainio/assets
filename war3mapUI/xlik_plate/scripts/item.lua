---@type UI_LikPlate
local ui = UIKit("xlik_plate")
function ui:updateItem()
    async.loc(function()
        local p = PlayerLocal()
        local selection = p:selection()
        if (false == class.isObject(selection, UnitClass)) then
            self.item:show(false)
            return
        end
        --- 物品栏
        local itemSlot = selection:itemSlot()
        if (nil == itemSlot) then
            self.item:show(false)
            return
        end
        --- 物品控制
        local storage = itemSlot:storage()
        local th = vistring.height(1, 7)
        for i = 1, self.itemMAX, 1 do
            ---@type Item
            local it = storage[i]
            if (false == class.isObject(it, ItemClass)) then
                self.itemBtn[i]:show(false)
            else
                local texture = it:icon()
                local text = ''
                local border = "btn/border-white"
                local maskValue = 0
                local charge = math.round(it:charges())
                local ab = it:bindAbility()
                local potText = ''
                if (class.isObject(ab, AbilityClass)) then
                    if (ab:coolDown() > 0 and ab:coolingRemain() > 0) then
                        maskValue = ab:coolingRemain() / ab:coolDown()
                        text = math.trunc(ab:coolingRemain(), 1)
                    elseif (ab:isBan() == true) then
                        local reason = ab:banReason()
                        maskValue = 1
                        if (nil ~= reason) then
                            border = X_UI_NIL
                            text = reason
                        end
                    end
                    if (ab == cursor.currentData().ability) then
                        border = "btn/border-gold"
                    end
                    -- pot
                    local castPotTimes = ab:castPotTimes()
                    if (castPotTimes > 0) then
                        potText = ab:castPotRemain() .. '/' .. ab:castPotTimes()
                    end
                end
                if (charge > 0) then
                    self.itemCharges[i]
                        :size(0.002 + vistring.width(charge, 7), 0.002 + th)
                        :text(charge)
                        :show(true)
                else
                    self.itemCharges[i]:show(false)
                end
                self.itemPot[i]:text(potText)
                self.itemBtn[i]:texture(texture)
                self.itemBtn[i]:border(border)
                self.itemBtn[i]:maskRatio(maskValue)
                self.itemBtn[i]:text(text)
                self.itemBtn[i]:show(true)
            end
            self.item:show(true)
        end
    end)
end