-- 面板
local kit = "xlik_plate"

---@class UI_LikPlate:UIKit
local ui = UIKit(kit)

function ui:onSetup()
    
    japi.DZ_FrameSetPoint(japi.DZ_FrameGetTooltip(), UI_ALIGN_LEFT_BOTTOM, UIGame:handle(), UI_ALIGN_LEFT_BOTTOM, -0.2, -0.2)
    -- params
    do
        self.plateBarW = 0.0772
        self.plateBarH = 0.013
        self.abilityMAX = #keyboard.abilityHotkey()
        self.itemMAX = #keyboard.itemHotkey()
        self.warehouseMAX = player.warehouseSlotVolume
        self.warehouseRaw = 4
        self.warehouseSize = 0.03
        self.warehouseMarginW = 0.003
        self.warehouseMarginH = 0.002
        self.warehouseResAllow = {}
        self.warehouseResOpt = {
            lumber = { texture = "interfaces/iconLumber", color = 'FED112', x = 3, y = 2 },
            gold = { texture = "interfaces/iconGold", color = 'FED112', x = 0.02, y = -0.03 },
            silver = { texture = "interfaces/iconSilver", color = 'BEC8EB', x = 0.02, y = -0.043 },
            copper = { texture = "interfaces/iconCopper", color = 'D7AE8E', x = 0.08, y = -0.043 },
        }
        local res = worth.get()
        res:forEach(function(key, value)
            if (self.warehouseResOpt[key]) then
                self.warehouseResOpt[key].name = value.name
                if (false == table.includes(self.warehouseResAllow, key)) then
                    table.insert(self.warehouseResAllow, key)
                end
            else
                self.warehouseResOpt[key] = { name = value.name }
            end
        end)
    end
    -- events
    do
        -- 参数变化事件监听参数
        local listenParams = {
            "exp", "level", "levelMax", "name",
            "hp", "hpCur", "mp", "mpCur",
            "attack", "attackSpeed", "attackSpaceBase", "noAttack",
            "invulnerable", "defend", "move"
        }
        player.onSelect(self:kit(), function(evtData)
            ---@type Unit
            local old, new = evtData.old, evtData.new
            async.call(evtData.triggerPlayer, function()
                -- 刷新一些UI
                self:updatePlate()
                self:updateAbility()
                self:updateItem()
                -- 注册变化事件
                if (class.isObject(old, UnitClass)) then
                    event.asyncUnregister(old, eventKind.unitItemChange, self:kit())
                    event.asyncUnregister(old, eventKind.unitAbilityChange, self:kit())
                    for _, k in ipairs(listenParams) do
                        event.asyncUnregister(old, eventKind.classAfterChange .. k, self:kit())
                    end
                end
                if (class.isObject(new, UnitClass)) then
                    event.asyncRegister(new, eventKind.unitItemChange, self:kit(), function()
                        self:updateItem()
                    end)
                    event.asyncRegister(new, eventKind.unitAbilityChange, self:kit(), function()
                        self:updateAbility()
                    end)
                    ---@param evtData2 eventOnClassAfterChange
                    local call = function(evtData2)
                        if (evtData2.triggerUnit == PlayerLocal():selection()) then
                            self:updatePlate()
                            if (evtData2.name == "hpCur" or evtData2.name == "mpCur") then
                                self:updateAbility()
                                self:updateItem()
                            end
                        end
                    end
                    for _, k in ipairs(listenParams) do
                        event.asyncRegister(new, eventKind.classAfterChange .. k, self:kit(), call)
                    end
                end
            end)
        end)
        -- 仓库变化事件
        event.asyncRegister(PlayerClass, eventKind.playerWarehouseChange, self:kit(), function()
            self:updateWarehouse()
        end)
    end
    -- plate
    do
        --- 信息
        local infoMargin = -0.002
        local infoWidth = 0.062
        local infoHeight = 0.032
        local infoAlpha = 220
        local infoFontSize = 10
        local plateTypes = { "Nil", "Unit", "Item" }
        ---@type table<string,UIBackdrop[]>
        self.plate = {}
        ---@type table<string,UIButton>
        self.plateInfo = {}
        --- 面板
        self.plateTopNameBlack = UIBackdrop(kit .. ":plateTopNameBlack", UIGame)
            :relation(UI_ALIGN_BOTTOM, UIGame, UI_ALIGN_BOTTOM, 0.003, 0.102)
            :size(0.178, 0.011)
            :texture(X_UI_BLACK)
        self.plateTopName = UIText(kit .. ":plateTopName", self.plateTopNameBlack)
            :relation(UI_ALIGN_CENTER, self.plateTopNameBlack, UI_ALIGN_CENTER, 0, 0)
            :textAlign(TEXT_ALIGN_CENTER)
            :fontSize(11)
        for _, t in ipairs(plateTypes) do
            local kp = kit .. ":plate:" .. t
            self.plate[t] = UIBackdrop(kp, UIGame)
                :block(true)
                :relation(UI_ALIGN_BOTTOM, UIGame, UI_ALIGN_BOTTOM, 0.003, 0)
                :size(0.19, 0.102)
                :texture(X_UI_BLACK)
                :show(false)
            if (t == "Nil") then
                self.plateNilMsg = UIText(kp .. ":description", self.plate[t])
                    :relation(UI_ALIGN_CENTER, self.plate[t], UI_ALIGN_CENTER, 0, -0.005)
                    :textAlign(TEXT_ALIGN_CENTER)
                    :fontSize(11)
            elseif (t == "Unit") then
                self.plateMP = UIBar(kp .. ":mp", self.plate[t], { _layouts = { LAYOUT_ALIGN_CENTER, LAYOUT_ALIGN_RIGHT } })
                    :relation(UI_ALIGN_LEFT_BOTTOM, self.plate[t], UI_ALIGN_LEFT_BOTTOM, -0.0934, 0.002)
                    :textureValue("bar/blue")
                    :fontSize(LAYOUT_ALIGN_CENTER, 10)
                    :fontSize(LAYOUT_ALIGN_RIGHT, 8)
                    :ratio(0, self.plateBarW, self.plateBarH)
                self.plateHP = UIBar(kp .. ":hp", self.plate[t], { _layouts = { LAYOUT_ALIGN_CENTER, LAYOUT_ALIGN_RIGHT } })
                    :relation(UI_ALIGN_BOTTOM, self.plateMP, UI_ALIGN_TOP, 0, 0.0015)
                    :textureValue("bar/green")
                    :fontSize(LAYOUT_ALIGN_CENTER, 10)
                    :fontSize(LAYOUT_ALIGN_RIGHT, 8)
                    :ratio(0, self.plateBarW, self.plateBarH)
                self.plateShield = UIBar(kp .. ":shield", self.plate[t])
                    :relation(UI_ALIGN_BOTTOM, self.plateHP, UI_ALIGN_TOP, 0, 0)
                    :textureValue("bar/gold")
                    :ratio(0, self.plateBarW, self.plateBarH / 8)
                -- 攻击
                self.plateInfo.attack = UILabel(kp .. ":info:attack", self.plate[t])
                    :relation(UI_ALIGN_LEFT_TOP, self.plate[t], UI_ALIGN_LEFT_BOTTOM, 0.005, 0.09)
                    :size(infoWidth, infoHeight)
                    :side(LAYOUT_ALIGN_LEFT)
                    :alpha(infoAlpha)
                    :icon("UI\\Widgets\\Console\\Human\\infocard-neutral-attack-melee.blp")
                    :textAlign(TEXT_ALIGN_LEFT)
                    :fontSize(infoFontSize)
                    :onEvent(eventKind.uiEnter, function(evtData) self.plateInfoEnter(evtData, "attack") end)
                    :onEvent(eventKind.uiLeave, self.plateInfoLeave)
                -- 攻速
                self.plateInfo.attackSpeed = UILabel(kp .. ":info:attackSpeed", self.plate[t])
                    :relation(UI_ALIGN_LEFT_TOP, self.plateInfo.attack, UI_ALIGN_LEFT_BOTTOM, 0, infoMargin)
                    :size(infoWidth, infoHeight)
                    :side(LAYOUT_ALIGN_LEFT)
                    :alpha(infoAlpha)
                    :icon("UI\\Widgets\\Console\\Human\\infocard-heroattributes-str.blp")
                    :textAlign(TEXT_ALIGN_LEFT)
                    :fontSize(infoFontSize)
                    :onEvent(eventKind.uiEnter, function(evtData) self.plateInfoEnter(evtData, "attackSpeed") end)
                    :onEvent(eventKind.uiLeave, self.plateInfoLeave)
                -- 防御
                self.plateInfo.defend = UILabel(kp .. ":info:defend", self.plate[t])
                    :relation(UI_ALIGN_LEFT_TOP, self.plateInfo.attack, UI_ALIGN_RIGHT_TOP, 0.04, 0)
                    :size(infoWidth, infoHeight)
                    :side(LAYOUT_ALIGN_LEFT)
                    :alpha(infoAlpha)
                    :icon("UI\\Widgets\\Console\\Human\\infocard-neutral-armor-medium.blp")
                    :textAlign(TEXT_ALIGN_LEFT)
                    :fontSize(infoFontSize)
                    :onEvent(eventKind.uiEnter, function(evtData) self.plateInfoEnter(evtData, "defend") end)
                    :onEvent(eventKind.uiLeave, self.plateInfoLeave)
                -- 移动
                self.plateInfo.move = UILabel(kp .. ":info:move", self.plate[t])
                    :relation(UI_ALIGN_LEFT_TOP, self.plateInfo.defend, UI_ALIGN_LEFT_BOTTOM, 0, infoMargin)
                    :size(infoWidth, infoHeight)
                    :side(LAYOUT_ALIGN_LEFT)
                    :alpha(infoAlpha)
                    :icon("UI\\Widgets\\Console\\Human\\infocard-heroattributes-agi.blp")
                    :textAlign(TEXT_ALIGN_LEFT)
                    :fontSize(infoFontSize)
                    :onEvent(eventKind.uiEnter, function(evtData) self.plateInfoEnter(evtData, "move") end)
                    :onEvent(eventKind.uiLeave, self.plateInfoLeave)
            elseif (t == "Item") then
                self.plateItemIcon = UIBackdrop(kp .. ":itemIcon", self.plate[t])
                    :relation(UI_ALIGN_LEFT_TOP, self.plate[t], UI_ALIGN_LEFT_BOTTOM, 0.005, 0.08)
                    :size(0.03, 0.03)
                self.plateItemDesc = UIText(kp .. ":itemDesc", self.plate[t])
                    :relation(UI_ALIGN_LEFT_TOP, self.plateItemIcon, UI_ALIGN_RIGHT_TOP, 0.006, 0)
                    :textAlign(TEXT_ALIGN_LEFT)
                    :fontSize(10)
            end
        end
    end
    -- ability
    do
        local kitAb = kit .. ":ability"
        self.abilitySizeX = 0.0366
        self.abilitySizeY = 0.0376
        self.abilityMarginX = 0.0068
        self.abilityMarginY = 0.0056
        ---@type UIBackdrop[]
        self.abilityBedding = {}
        ---@type UIButton[]
        self.abilityBtn = {}
        ---@type UIText[]
        self.abilityPot = {}
        ---@type UIButton[]
        self.abilityBtnLvUp = {}
        self.ability = UIBackdrop(kitAb, UIGame)
            :relation(UI_ALIGN_RIGHT_BOTTOM, UIGame, UI_ALIGN_RIGHT_BOTTOM, 0, 0)
            :size(0.202, 0.16)
            :show(false)
        for i = 1, self.abilityMAX do
            self.abilityBedding[i] = UIBackdrop(kitAb .. ':bedding:' .. i, self.ability)
                :size(self.abilitySizeX, self.abilitySizeY)
                :texture(X_UI_NIL)
                :show(i < 5)
            if (i == 1) then
                self.abilityBedding[i]:relation(UI_ALIGN_LEFT_TOP, UIGame, UI_ALIGN_RIGHT_BOTTOM, -0.181, 0.0446)
            elseif ((i - 1) % 4 == 0) then
                local j = (i // 4 - 1) * 4 + 1
                self.abilityBedding[i]:relation(UI_ALIGN_LEFT_BOTTOM, self.abilityBedding[j], UI_ALIGN_LEFT_TOP, 0, self.abilityMarginY)
            else
                self.abilityBedding[i]:relation(UI_ALIGN_LEFT_TOP, self.abilityBedding[i - 1], UI_ALIGN_RIGHT_TOP, self.abilityMarginX, 0)
            end
        end
        for i = 1, self.abilityMAX do
            self.abilityBtn[i] = UIButton(kitAb .. ':btn:' .. i, self.ability)
                :size(self.abilitySizeX, self.abilitySizeY)
                :relation(UI_ALIGN_CENTER, self.abilityBedding[i], UI_ALIGN_CENTER, 0, 0)
                :fontSize(10)
                :hotkeyFontSize(9)
                :hotkeyRelation(UI_ALIGN_RIGHT_TOP, UI_ALIGN_RIGHT_TOP, -0.004, -0.004)
                :borderScale(1.05, 1.04)
                :mask(X_UI_BLACK)
                :maskAlpha(180)
                :onEvent(eventKind.uiEnter,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local selection = evtData.triggerPlayer:selection()
                    if (nil == selection) then
                        return
                    end
                    local slot = selection:abilitySlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    evtData.triggerUI._highlight:show(true)
                    local content = tooltipsAbility(storage[i], 0)
                    if (nil ~= content) then
                        content.textAlign = TEXT_ALIGN_LEFT
                        content.fontSize = 10
                        UITooltips()
                            :relation(UI_ALIGN_LEFT_BOTTOM, self.ability, UI_ALIGN_LEFT_TOP, 0.002, 0.002)
                            :content(content)
                            :show(true)
                    end
                end)
                :onEvent(eventKind.uiLeave,
                function(evtData)
                    evtData.triggerUI._highlight:show(false)
                    UITooltips():show(false)
                end)
                :onEvent(eventKind.uiLeftClick,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local selection = evtData.triggerPlayer:selection()
                    if (false == class.isObject(selection, UnitClass)) then
                        return
                    end
                    local slot = selection:abilitySlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    ---@type Ability
                    local ab = storage[i]
                    if (class.isObject(ab, AbilityClass)) then
                        cursor.quote(ab:targetType(), { ability = ab, mouseLeft = true })
                    end
                end)
                :onEvent(eventKind.uiRightClick,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local selection = evtData.triggerPlayer:selection()
                    if (false == class.isObject(selection, UnitClass)) then
                        return
                    end
                    if (evtData.triggerPlayer ~= selection:owner()) then
                        return
                    end
                    local slot = selection:abilitySlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    local ob = storage[i]
                    local triggerUI = evtData.triggerUI
                    japi.DZ_FrameSetAlpha(triggerUI:handle(), 0)
                    sound.vcm("war3_MouseClick1")
                    cursor.quote("follow", {
                        object = ob,
                        ui = triggerUI,
                        over = function()
                            japi.DZ_FrameSetAlpha(triggerUI:handle(), triggerUI._alpha)
                        end,
                        ---@param evt eventOnMouseRightClick
                        rightClick = function(evt)
                            local sel = evt.triggerPlayer:selection()
                            if (class.isObject(sel, UnitClass) and sel:owner() == evt.triggerPlayer) then
                                local tarIdx = -1
                                local tarObj
                                local sto = sel:abilitySlot():storage()
                                for j = 1, self.abilityMAX do
                                    local ab = sto[j]
                                    local btn = self.abilityBtn[j]
                                    if (isInsideUI(btn, evt.rx, evt.ry, false)) then
                                        tarIdx = j
                                        tarObj = ab
                                        break
                                    end
                                end
                                if (-1 ~= tarIdx and false == table.equal(ob, tarObj)) then
                                    sync.send("lk_sync_g", { "ability_push", sel:id(), ob:id(), tarIdx })
                                    sound.vcm("war3_MouseClick1")
                                else
                                    cursor.quoteOver()
                                end
                            else
                                cursor.quoteOver()
                            end
                        end,
                    })
                end)
                :show(false)
            self.abilityPot[i] = UIText(kitAb .. ':pot:' .. i, self.abilityBtn[i])
                :relation(UI_ALIGN_LEFT_TOP, self.abilityBtn[i], UI_ALIGN_LEFT_TOP, 0.004, -0.004)
                :fontSize(9)
                :text('')
            self.abilityBtnLvUp[i] = UIButton(kitAb .. ':upbtn:' .. i, self.abilityBedding[i])
                :relation(UI_ALIGN_BOTTOM, self.abilityBtn[i], UI_ALIGN_TOP, 0, 0)
                :texture('icon/up')
                :show(false)
                :onEvent(eventKind.uiLeave, function(_) UITooltips():show(false) end)
                :onEvent(eventKind.uiEnter,
                function(evtData)
                    local selection = evtData.triggerPlayer:selection()
                    if (nil == selection) then
                        return
                    end
                    local content = tooltipsAbility(selection:abilitySlot():storage()[i], 1)
                    if (nil ~= content) then
                        content.textAlign = TEXT_ALIGN_LEFT
                        content.fontSize = 10
                        UITooltips()
                            :relation(UI_ALIGN_BOTTOM, self.abilityBtnLvUp[i], UI_ALIGN_TOP, 0, 0.002)
                            :content(content)
                            :show(true)
                    end
                end)
                :onEvent(eventKind.uiLeftClick,
                function(evtData)
                    local selection = evtData.triggerPlayer:selection()
                    if (class.isObject(selection, UnitClass) and selection:isAlive() and selection:owner() == evtData.triggerPlayer) then
                        sound.vcm("war3_MouseClick1")
                        local ab = selection:abilitySlot():storage()[i]
                        if (class.isObject(ab, AbilityClass)) then
                            sync.send("lk_sync_g", { "ability_level_up", ab:id() })
                            local content = tooltipsAbility(ab, 1)
                            if (nil ~= content) then
                                content.textAlign = TEXT_ALIGN_LEFT
                                content.fontSize = 10
                                UITooltips():content(content)
                            end
                        end
                    end
                end)
        end
    end
    -- item
    do
        local kitIt = kit .. ":item"
        self.itemSizeX = 0.032
        self.itemSizeY = 0.0294
        self.itemMarginX = 0.008
        self.itemMarginY = 0.009
        ---@type UIButton[]
        self.itemBtn = {}
        ---@type UIText[]
        self.itemPot = {}
        ---@type UIButton[]
        self.itemCharges = {}
        self.item = UIBackdrop(kitIt, UIGame)
            :block(true)
            :relation(UI_ALIGN_LEFT_BOTTOM, UIGame, UI_ALIGN_BOTTOM, 0.111, 0)
            :size(0.078, 0.098)
        local raw = 2
        for i = 1, self.itemMAX do
            local xo = 0.0040 + (i - 1) % raw * (self.itemSizeX + self.itemMarginX)
            local yo = 0.0132 - (math.ceil(i / raw) - 1) * (self.itemMarginY + self.itemSizeY)
            self.itemBtn[i] = UIButton(kit .. ':btn:' .. i, self.item)
                :relation(UI_ALIGN_LEFT_TOP, self.item, UI_ALIGN_LEFT_TOP, xo, yo)
                :size(self.itemSizeX, self.itemSizeY)
                :fontSize(7.5)
                :borderScale(1.05, 1.04)
                :mask(X_UI_BLACK)
                :maskAlpha(180)
                :show(false)
                :onEvent(eventKind.uiLeave,
                function(evtData)
                    evtData.triggerUI._highlight:show(false)
                    UITooltips():show(false)
                end)
                :onEvent(eventKind.uiEnter,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local selection = evtData.triggerPlayer:selection()
                    if (false == class.isObject(selection, UnitClass)) then
                        return nil
                    end
                    local slot = selection:itemSlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    evtData.triggerUI._highlight:show(true)
                    local content = tooltipsItem(storage[i])
                    if (nil ~= content) then
                        content.textAlign = TEXT_ALIGN_LEFT
                        content.fontSize = 10
                        UITooltips()
                            :relation(UI_ALIGN_BOTTOM, self.item, UI_ALIGN_TOP, 0, 0.04)
                            :content(content)
                            :show(true)
                    end
                end)
                :onEvent(eventKind.uiLeftClick,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local selection = evtData.triggerPlayer:selection()
                    if (false == class.isObject(selection, UnitClass)) then
                        return
                    end
                    local slot = selection:itemSlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    ---@type Item
                    local it = storage[i]
                    if (class.isObject(it, ItemClass)) then
                        local ab = it:bindAbility()
                        if (class.isObject(ab, AbilityClass)) then
                            cursor.quote(ab:targetType(), { ability = ab, mouseLeft = true })
                        end
                    end
                end)
                :onEvent(eventKind.uiRightClick,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local selection = evtData.triggerPlayer:selection()
                    if (false == class.isObject(selection, UnitClass)) then
                        return
                    end
                    if (evtData.triggerPlayer ~= selection:owner()) then
                        return
                    end
                    local slot = selection:itemSlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    local ob = storage[i]
                    local triggerUI = evtData.triggerUI
                    japi.DZ_FrameSetAlpha(triggerUI:handle(), 0)
                    sound.vcm("war3_MouseClick1")
                    cursor.quote("follow", {
                        object = ob,
                        ui = triggerUI,
                        over = function()
                            japi.DZ_FrameSetAlpha(triggerUI:handle(), triggerUI._alpha)
                        end,
                        ---@param evt eventOnMouseRightClick
                        rightClick = function(evt)
                            local p = evt.triggerPlayer
                            local sel = p:selection()
                            if (class.isObject(sel, UnitClass) and sel:owner() == p) then
                                local tarIdx = -1
                                local tarType, tarObj
                                local sto = sel:itemSlot():storage()
                                for j = 1, self.itemMAX do
                                    local it = sto[j]
                                    local btn = self.itemBtn[j]
                                    if (isInsideUI(btn, evt.rx, evt.ry, false)) then
                                        tarObj, tarType, tarIdx = it, "item", j
                                        break
                                    end
                                end
                                if (-1 == tarIdx and self.warehouseDrag:isShow()) then
                                    sto = p:warehouseSlot():storage()
                                    for w = 1, self.warehouseMAX do
                                        local it = sto[w]
                                        local btn = self.warehouseButton[w]
                                        if (isInsideUI(btn, evt.rx, evt.ry, false)) then
                                            tarObj, tarType, tarIdx = it, "warehouse", w
                                            break
                                        end
                                    end
                                end
                                if (-1 ~= tarIdx and false == table.equal(ob, tarObj)) then
                                    if (tarType == "item") then
                                        sync.send("lk_sync_g", { "item_push", sel:id(), ob:id(), tarIdx })
                                    elseif (tarType == "warehouse") then
                                        sync.send("lk_sync_g", { "item_to_warehouse", sel:id(), ob:id(), tarIdx })
                                    end
                                    sound.vcm("war3_MouseClick1")
                                else
                                    cursor.quoteOver()
                                end
                            else
                                cursor.quoteOver()
                            end
                        end,
                    })
                end)
            
            self.itemPot[i] = UIText(kitIt .. ':pot:' .. i, self.itemBtn[i])
                :relation(UI_ALIGN_LEFT_TOP, self.itemBtn[i], UI_ALIGN_LEFT_TOP, 0.002, -0.002)
                :fontSize(8)
                :text('')
            
            -- 物品使用次数
            self.itemCharges[i] = UIButton(kitIt .. ':charges:' .. i, self.itemBtn[i])
                :relation(UI_ALIGN_RIGHT_BOTTOM, self.itemBtn[i], UI_ALIGN_RIGHT_BOTTOM, -0.0014, 0.0014)
                :texture(BLP_COLOR_BLACK)
                :fontSize(7)
        end
    end
    -- warehouse
    do
        local kitWh = kit .. ":Warehouse"
        self.warehouseRes = {}
        self.warehouseButton = {}
        self.warehouseCharges = {}
        self.warehouseDrag = UIDrag(kitWh .. ":drag", UIGame)
            :esc(true)
            :relation(UI_ALIGN_RIGHT_BOTTOM, UIGame, UI_ALIGN_RIGHT_BOTTOM, -0.17, 0.3)
            :size(0.16, 0.03)
            :padding(0, 0, 0.13, 0)
            :show(false)
        self.warehouseTips = UIText(kitWh .. ':tips', UIGame)
            :relation(UI_ALIGN_BOTTOM, UIGame, UI_ALIGN_BOTTOM, 0.15, 0.142)
            :textAlign(TEXT_ALIGN_LEFT)
            :fontSize(9)
            :text("按B打开仓库")
        keyboard.onRelease(keyboard.code["B"], "_itemWarehouse", function()
            self:updateWarehouse()
            self.warehouseDrag:show(not self.warehouseDrag:isShow())
        end)
        self.warehouse = UIBackdrop(kitWh, self.warehouseDrag)
            :block(true)
            :relation(UI_ALIGN_TOP, self.warehouseDrag, UI_ALIGN_TOP, 0, 0)
            :size(0.16, 0.16)
            :texture("interfaces/tileBlack")
        self.warehouseCell = UIText(kitWh .. ":stgTxt", self.warehouse)
            :relation(UI_ALIGN_CENTER, self.warehouse, UI_ALIGN_TOP, 0, -0.012)
            :textAlign(TEXT_ALIGN_RIGHT)
            :fontSize(10)
        for i, k in ipairs(self.warehouseResAllow) do
            local n = self.warehouseResOpt[k].name
            local opt = self.warehouseResOpt[k]
            self.warehouseRes[i] = UILabel(kitWh .. ":res" .. k, self.warehouse, { _autoSize = true })
                :relation(UI_ALIGN_LEFT_TOP, self.warehouse, UI_ALIGN_LEFT_TOP, opt.x, opt.y)
                :icon(opt.texture)
                :textAlign(TEXT_ALIGN_LEFT)
                :fontSize(9)
                :onEvent(eventKind.uiLeave, function(_) UITooltips():show(false) end)
                :onEvent(eventKind.uiEnter,
                function(evtData)
                    --- 资源显示
                    local r = evtData.triggerPlayer:worth()
                    local tips = {
                        "资源名称: " .. n,
                        "资源总量: " .. math.floor(r[k] or 0),
                        "资源获得率: " .. math.trunc(evtData.triggerPlayer:worthRatio(), 2) .. "%",
                    }
                    local cov = worth.convert(k)
                    if (nil ~= cov) then
                        table.insert(tips, "经济体系: " .. "1" .. self.warehouseResOpt[cov[1]].name .. "=" .. cov[2] .. n)
                    end
                    UITooltips()
                        :relation(UI_ALIGN_BOTTOM, self.warehouseRes[i], UI_ALIGN_TOP, 0, 0.002)
                        :content({ textAlign = TEXT_ALIGN_LEFT, fontSize = 10, tips = tips })
                        :show(true)
                end)
        end
        for i = 1, self.warehouseMAX do
            local xo = 0.016 + (i - 1) % self.warehouseRaw * (self.warehouseSize + self.warehouseMarginW)
            local yo = -0.06 - (math.ceil(i / self.warehouseRaw) - 1) * (self.warehouseMarginH + self.warehouseSize)
            self.warehouseButton[i] = UIButton(kitWh .. ":btn" .. i, self.warehouse)
                :relation(UI_ALIGN_LEFT_TOP, self.warehouse, UI_ALIGN_LEFT_TOP, xo, yo)
                :size(self.warehouseSize, self.warehouseSize)
                :fontSize(7)
                :borderScale(1.06, 1.06)
                :show(false)
                :onEvent(eventKind.uiLeave,
                function(evtData)
                    evtData.triggerUI._highlight:show(false)
                    UITooltips():show(false)
                end)
                :onEvent(eventKind.uiEnter,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    evtData.triggerUI._highlight:show(true)
                    local content = tooltipsWarehouse(evtData.triggerPlayer:warehouseSlot():storage()[i], evtData.triggerPlayer)
                    if (nil ~= content) then
                        content.textAlign = TEXT_ALIGN_LEFT
                        content.fontSize = 10
                        UITooltips()
                            :relation(UI_ALIGN_BOTTOM, self.warehouseButton[i], UI_ALIGN_TOP, 0, 0.002)
                            :content(content)
                            :show(true)
                            :onEvent(eventKind.uiLeftClick,
                            function(ed)
                                UITooltips():show(false)
                                ---@type Item
                                local it = ed.triggerPlayer:warehouseSlot():storage()[i]
                                if (class.isObject(it, ItemClass)) then
                                    if (ed.key == "item") then
                                        local selection = ed.triggerPlayer:selection()
                                        if (class.isObject(selection, UnitClass)) then
                                            sync.send("lk_sync_g", { "warehouse_to_item", it:id() })
                                        end
                                    elseif (ed.key == "drop") then
                                        if (it:dropable()) then
                                            local selection = ed.triggerPlayer:selection()
                                            if (class.isObject(selection, UnitClass)) then
                                                sync.send("lk_sync_g", { "item_drop", it:id(), selection:x(), selection:y() })
                                            end
                                        end
                                    elseif (ed.key == "pawn") then
                                        if (it:pawnable()) then
                                            sync.send("lk_sync_g", { "item_pawn", it:id() })
                                        end
                                    elseif (ed.key == "separate") then
                                    
                                    end
                                end
                            end)
                    end
                end)
                :onEvent(eventKind.uiRightClick,
                function(evtData)
                    if (cursor.isQuoting()) then
                        return
                    end
                    local slot = evtData.triggerPlayer:warehouseSlot()
                    if (nil == slot) then
                        return
                    end
                    local storage = slot:storage()
                    if (nil == storage) then
                        return
                    end
                    local ob = storage[i]
                    local triggerUI = evtData.triggerUI
                    japi.DZ_FrameSetAlpha(triggerUI:handle(), 0)
                    sound.vcm("war3_MouseClick1")
                    cursor.quote("follow", {
                        object = ob,
                        ui = triggerUI,
                        over = function()
                            japi.DZ_FrameSetAlpha(triggerUI:handle(), triggerUI._alpha)
                        end,
                        ---@param evt eventOnMouseRightClick
                        rightClick = function(evt)
                            local p = evt.triggerPlayer
                            local tarIdx = -1
                            local tarType, tarObj
                            local sto = p:warehouseSlot():storage()
                            for w = 1, self.warehouseMAX do
                                local it = sto[w]
                                local btn = self.warehouseButton[w]
                                if (isInsideUI(btn, evt.rx, evt.ry, false)) then
                                    tarObj, tarType, tarIdx = it, "warehouse", w
                                    break
                                end
                            end
                            local tarUnit
                            if (-1 == tarIdx) then
                                local sel = p:selection()
                                if (class.isObject(sel, UnitClass) and sel:owner() == p) then
                                    sto = sel:itemSlot():storage()
                                    for j = 1, self.itemMAX do
                                        local it = sto[j]
                                        local btn = self.itemBtn[j]
                                        if (isInsideUI(btn, evt.rx, evt.ry, false)) then
                                            tarObj, tarType, tarIdx = it, "item", j
                                            tarUnit = sel
                                            break
                                        end
                                    end
                                end
                            end
                            if (-1 ~= tarIdx and false == table.equal(ob, tarObj)) then
                                if (tarType == "warehouse") then
                                    sync.send("lk_sync_g", { "warehouse_push", ob:id(), tarIdx })
                                elseif (tarType == "item" and nil ~= tarUnit) then
                                    sync.send("lk_sync_g", { "warehouse_to_item", tarUnit:id(), ob:id(), tarIdx })
                                end
                                sound.vcm("war3_MouseClick1")
                            else
                                cursor.quoteOver()
                            end
                        end,
                    })
                end)
            
            -- 物品使用次数
            self.warehouseCharges[i] = UIButton(kitWh .. ":charges:" .. i, self.warehouseButton[i]._border)
                :relation(UI_ALIGN_RIGHT_BOTTOM, self.warehouseButton[i], UI_ALIGN_RIGHT_BOTTOM, -0.0011, 0.00146)
                :texture(BLP_COLOR_BLACK)
                :fontSize(7)
        end
    end
end

function ui:onStart()
    self:updatePlate()
end