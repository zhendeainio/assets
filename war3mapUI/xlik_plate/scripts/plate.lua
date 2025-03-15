---@type UI_LikPlate
local ui = UIKit("xlik_plate")

ui.plateInfoLeave = function()
    UITooltips():show(false)
end

ui.plateInfoEnter = function(evtData, field)
    ---@type Player
    local triggerPlayer = evtData.triggerPlayer
    local selection = triggerPlayer:selection()
    if (nil == selection) then
        return
    end
    local primary = selection:primary()
    local tips = {}
    local _attrLabel = function(sel, key)
        local label, form = attribute.label(key), attribute.form(key)
        local val = sel:get(key) or 0
        if (form == '%') then
            val = math.format(val, 2)
        elseif (form == "击每秒" or form == "每秒") then
            val = math.format(val, 3)
        else
            val = math.floor(val)
        end
        return label .. ": " .. val .. form
    end
    if (field == "portrait") then
        if (nil ~= primary) then
            table.insert(tips, colour.hex(colour.gold, "主属性: " .. primary.label))
            table.insert(tips, colour.hex(colour.littlepink, _attrLabel(selection, "str")))
            table.insert(tips, colour.hex(colour.mintcream, _attrLabel(selection, "agi")))
            table.insert(tips, colour.hex(colour.skyblue, _attrLabel(selection, "int")))
        end
        table.insert(tips, _attrLabel(selection, "sight"))
        table.insert(tips, _attrLabel(selection, "nsight"))
        if (selection:exp() > 0) then
            table.insert(tips, "经验: " .. selection:exp())
            table.insert(tips, "等级: " .. selection:level() .. "/" .. selection:levelMax())
        elseif (selection:level() > 0) then
            table.insert(tips, "等级: " .. selection:level())
        end
        local sp = selection._sp
        if (nil ~= sp) then
            table.insert(tips, colour.hex(colour.gold, "特性: " .. sp))
        end
    elseif (field == "attack") then
        if (false == selection:isAttackAble()) then
            table.insert(tips, colour.hex(colour.red, "无法攻击"))
        else
            table.insert(tips, _attrLabel(selection, "attack") .. colour.hex(colour.gold, "(快捷键A)"))
            table.insert(tips, _attrLabel(selection, "attackRipple"))
            table.insert(tips, _attrLabel(selection, "enchantMystery"))
        end
    elseif (field == "attackSpeed") then
        if (false == selection:isAttackAble()) then
            table.insert(tips, "武器: 无")
        else
            local ass = selection:assault()
            if (ass:mode() == "lightning") then
                table.insert(tips, "武器: 闪电")
                if (ass:scatter() > 0 and ass:radius() > 0) then
                    table.insert(tips, "散射数量: " .. math.floor(ass:scatter()))
                    table.insert(tips, "散射范围: " .. math.floor(ass:radius()))
                end
                if (ass:focus() > 0) then
                    table.insert(tips, "聚焦数量: " .. math.floor(ass:focus()))
                end
                if (ass:reflex() > 0) then
                    table.insert(tips, "反弹数量: " .. math.floor(ass:reflex()))
                end
            elseif (ass:mode() == "missile") then
                if (ass:homing()) then
                    table.insert(tips, "武器: 追踪箭矢")
                else
                    table.insert(tips, "武器: 箭矢")
                end
                table.insert(tips, "发射速度: " .. math.floor(ass:speed()))
                table.insert(tips, "发射加速度: " .. math.floor(ass:acceleration()))
                table.insert(tips, "发射高度: " .. math.floor(ass:height()))
                if (ass:scatter() > 0 and ass:radius() > 0) then
                    table.insert(tips, "散射数量: " .. math.floor(ass:scatter()))
                    table.insert(tips, "散射范围: " .. math.floor(ass:radius()))
                end
                if (ass:gatling() > 0) then
                    table.insert(tips, "多段数量: " .. math.floor(ass:gatling()))
                end
                if (ass:reflex() > 0) then
                    table.insert(tips, "反弹数量: " .. math.floor(ass:reflex()))
                end
            else
                if (selection:attackRange() <= 200) then
                    table.insert(tips, "武器: 近战")
                else
                    table.insert(tips, "武器: 远程")
                end
            end
            table.insert(tips, "伤害类型: " .. ass:damageType().label .. " Lv." .. ass:damageTypeLevel())
        end
        table.insert(tips, _attrLabel(selection, "attackSpaceBase"))
        table.insert(tips, _attrLabel(selection, "attackSpeed"))
        table.insert(tips, _attrLabel(selection, "attackRange"))
    elseif (field == "defend") then
        table.insert(tips, _attrLabel(selection, "defend"))
    elseif (field == "move") then
        table.insert(tips, _attrLabel(selection, "move") .. colour.hex(colour.gold, "(快捷键M)"))
        table.insert(tips, "移动类型: " .. selection:moveType().label)
    end
    local tt = UITooltips()
    local content = {
        textAlign = TEXT_ALIGN_LEFT,
        fontSize = 10,
        tips = tips
    }
    if (field == "portrait") then
        tt:relation(UI_ALIGN_BOTTOM, ui.plateInfo[field], UI_ALIGN_TOP, 0, 0.004)
        tt:content(content)
        tt:show(true)
    else
        tt:relation(UI_ALIGN_LEFT_BOTTOM, ui.plateInfo[field], UI_ALIGN_LEFT_TOP, 0, 0.002)
        tt:content(content)
        tt:show(true)
    end
end

function ui:updatePlate()
    async.loc(function()
        local p = PlayerLocal()
        local selection = p:selection()
        if (class.isObject(selection, UnitClass)) then
            local properName = selection:name()
            if (selection:properName() ~= nil and selection:properName() ~= '') then
                properName = properName .. "·" .. selection:properName()
            end
            if (selection:level() >= 1) then
                properName = colour.hex(colour.gold, "Lv" .. selection:level()) .. " " .. properName
            end
            local attackAlpha = 150
            local attack = " - "
            local attackSpeed = " - "
            if (selection:isAttackAble()) then
                attackAlpha = 255
                if (selection:attackRipple() == 0) then
                    local atk = math.floor(selection:attack())
                    if (atk > 0) then
                        attack = atk
                    else
                        attack = colour.hex(colour.indianred, atk)
                    end
                else
                    local atk = math.floor(selection:attack())
                    local atk2 = math.floor(atk + selection:attackRipple())
                    if (atk > 0) then
                        attack = atk .. "~" .. atk2
                    else
                        attack = colour.hex(colour.indianred, atk .. "~" .. atk2)
                    end
                end
                if (selection:attackSpeed() < 0) then
                    attackSpeed = colour.hex(colour.indianred, math.format(selection:attackSpace(), 2) .. " 秒/击")
                else
                    attackSpeed = math.format(selection:attackSpace(), 2) .. " 秒/击"
                end
            end
            local defend = math.floor(selection:defend())
            if (selection:isInvulnerable()) then
                defend = colour.hex(colour.gold, "无敌")
            else
                if (selection:defend() <= 9999) then
                    defend = math.floor(selection:defend())
                else
                    defend = math.numberFormat(selection:defend(), 2)
                end
            end
            local move = math.max(0, math.floor(selection:move()))
            local hpCur = math.floor(selection:hpCur())
            local hp = math.floor(selection:hp() or 0)
            local hpRegen = math.trunc(selection:hpRegen(), 2)
            if (hpRegen == 0 or hp == 0 or hpCur >= hp) then
                hpRegen = ''
            elseif (hpRegen > 0) then
                hpRegen = colour.hex(colour.green, "+" .. hpRegen)
            elseif (hpRegen < 0) then
                hpRegen = colour.hex(colour.red, hpRegen)
            end
            local hpPercent = math.trunc(hpCur / hp, 3)
            local hpTxt = hpCur .. " / " .. hp
            local hpTexture = "bar/green"
            if (hpCur < hp * 0.35) then
                hpTexture = "bar/red"
            elseif (hpCur < hp * 0.65) then
                hpTexture = "bar/orange"
            end
            local mpCur = math.floor(selection:mpCur())
            local mp = math.floor(selection:mp() or 0)
            local mpRegen = math.trunc(selection:mpRegen(), 2)
            if (mpRegen == 0 or mp == 0 or mpCur >= mp) then
                mpRegen = ''
            elseif (mpRegen > 0) then
                mpRegen = colour.hex(colour.lightcyan, "+" .. mpRegen)
            elseif (mpRegen < 0) then
                mpRegen = colour.hex(colour.red, mpRegen)
            end
            local mpPercent = nil
            local mpTxt = mpCur .. " / " .. mp
            local mpTexture = "bar/blue"
            if (mp == 0) then
                mpPercent = 1
                mpTxt = colour.hex(colour.silver, mpTxt)
                mpTexture = "bar/blueGrey"
            else
                mpPercent = math.trunc(mpCur / mp, 3)
            end
            self.plateTopName:text(properName)
            self.plateHP
                :valueTexture(hpTexture)
                :ratio(hpPercent, self.plateBarW, self.plateBarH)
                :text(LAYOUT_ALIGN_CENTER, hpTxt)
                :text(LAYOUT_ALIGN_RIGHT, hpRegen)
            self.plateMP
                :valueTexture(mpTexture)
                :ratio(mpPercent, self.plateBarW, self.plateBarH)
                :text(LAYOUT_ALIGN_CENTER, mpTxt)
                :text(LAYOUT_ALIGN_RIGHT, mpRegen)
            self.plateInfo.attack:text(attack):alpha(attackAlpha)
            self.plateInfo.attackSpeed:text(attackSpeed):alpha(attackAlpha)
            self.plateInfo.defend:text(defend)
            self.plateInfo.move:text(move)
            self.plate.Nil:show(false)
            self.plate.Item:show(false)
            self.plate.Unit:show(true)
        else
            self.plateNilMsg:text(game.name)
            self.plate.Unit:show(false)
            self.plate.Item:show(false)
            self.plate.Nil:show(true)
        end
    end)
end

---@param ab Ability
function ui:buttonBorder(ab)
    if (false == class.isObject(ab, AbilityClass)) then
        return
    end
    async.loc(function()
        local p = PlayerLocal()
        local selection = p:selection()
        if (false == class.isObject(selection, UnitClass) or selection:isDead()) then
            return
        end
        if (selection:owner() ~= p) then
            return
        end
        local it = ab:bindItem()
        if (class.isObject(it, ItemClass)) then
            local i = it:itemSlotIndex()
            if (nil == self.itemBtn[i] or false == self.itemBtn[i]:isShow()) then
                return
            end
            local border = "btn/border-white"
            if (ab:isBan() == true) then
                local reason = ab:banReason()
                if (nil ~= reason) then
                    border = X_UI_NIL
                end
            end
            if (ab == cursor.currentData().ability) then
                border = "btn/border-gold"
            end
            self.itemBtn[i]:border(border)
        else
            local i = ab:abilitySlotIndex()
            if (nil == self.abilityBtn[i] or false == self.abilityBtn[i]:isShow()) then
                return
            end
            local border = "btn/border-white"
            local tt = ab:targetType()
            if (ab:coolDown() > 0 and ab:coolingRemain() > 0) then
                border = X_UI_NIL
            elseif (ab:isBan() == true) then
                local reason = ab:banReason()
                if (nil == reason) then
                    border = X_UI_NIL -- ban
                else
                    border = X_UI_NIL
                end
            else
                if (nil == tt or ability.targetType.pas == tt) then
                    border = X_UI_NIL
                elseif (ab == cursor.currentData().ability) then
                    border = "btn/border-gold"
                end
            end
            self.abilityBtn[i]:border(border)
        end
    end)
end