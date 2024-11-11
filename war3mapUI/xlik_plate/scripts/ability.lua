---@type UI_LikPlate
local ui = UIKit("xlik_plate")

function ui:updateAbility()
    async.loc(function()
        local p = PlayerLocal()
        ---@type Unit
        local selection = p:selection()
        if (class.isObject(selection, UnitClass) and selection:isAlive()) then
            --- 物品栏
            local abilitySlot = selection:abilitySlot()
            if (nil == abilitySlot) then
                self.ability:show(false)
            else
                self.ability:show(true)
                local tail = abilitySlot:tail()
                local storage = abilitySlot:storage()
                for i = 1, self.abilityMAX do
                    local beddingShow = false
                    local btnShow = false
                    local btnTexture = ''
                    local btnBorder = ''
                    local btnText = ''
                    local btnHotkey = 0
                    local btnMaskValue = 0
                    local btnLvUpShow = false
                    local potText = ''
                    local ab = storage[i]
                    if (i <= tail) then
                        beddingShow = true
                        if (nil ~= ab) then
                            local tt = ab:targetType()
                            btnShow = (nil ~= tt)
                            if (btnShow) then
                                btnTexture = ab:icon()
                                if (ab:coolDown() > 0 and ab:coolingRemain() > 0) then
                                    btnMaskValue = math.min(1, ab:coolingRemain() / ab:coolDown())
                                    btnBorder = X_UI_NIL
                                    btnText = math.format(ab:coolingRemain(), 1)
                                elseif (ab:isBan() == true) then
                                    local reason = ab:banReason()
                                    btnMaskValue = 1
                                    if (nil == reason) then
                                        btnBorder = X_UI_NIL -- ban
                                        btnText = ''
                                    else
                                        btnBorder = X_UI_NIL
                                        btnText = reason
                                    end
                                else
                                    btnMaskValue = 0
                                    btnText = ''
                                    if (nil == tt or ability.targetType.pas == tt) then
                                        btnBorder = X_UI_NIL
                                    else
                                        btnBorder = "btn/border-white"
                                        if (selection:owner() == p and ab == cursor.currentData().ability) then
                                            btnBorder = "btn/border-gold"
                                        end
                                    end
                                end
                                if (nil == tt or ability.targetType.pas == tt) then
                                    btnHotkey = 0
                                else
                                    btnHotkey = keyboard.abilityHotkey(i)
                                end
                                -- pot
                                local castPotTimes = ab:castPotTimes()
                                if (castPotTimes > 0) then
                                    potText = ab:castPotRemain() .. '/' .. ab:castPotTimes()
                                end
                                -- next
                                btnLvUpShow = false
                                if (nil ~= tt and selection:abilityPoint() > 0) then
                                    if (ab:level() < ab:levelMax() and ab:levelUpNeedPoint() > 0) then
                                        if (ab:levelUpNeedPoint() <= selection:abilityPoint()) then
                                            btnLvUpShow = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if (btnShow) then
                        self.abilityBtn[i]:hotkey(btnHotkey)
                        self.abilityBtn[i]:texture(btnTexture)
                        self.abilityBtn[i]:border(btnBorder)
                        self.abilityBtn[i]:maskRatio(btnMaskValue)
                        self.abilityBtn[i]:text(btnText)
                        self.abilityPot[i]:text(potText)
                    end
                    self.abilityBtn[i]:show(btnShow)
                    self.abilityBtnLvUp[i]:show(btnLvUpShow)
                    self.abilityBedding[i]:show(beddingShow)
                end
            end
        else
            self.ability:show(false)
        end
    end)
end