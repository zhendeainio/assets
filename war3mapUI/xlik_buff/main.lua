-- BUFF
local kit = "xlik_buff"

---@class UI_LikBuff:UIKit
local ui = UIKit(kit)

function ui:onSetup()
    
    ---@type number 最大buff数
    self.buff_max = 12
    ---@type number 图标size
    self.buff_iSize = 0.02
    ---@type number 图标margin
    self.buff_iMar = 0
    ---@type UIButton[]
    self.buff_buffs = {}
    ---@type UIBackdrop[]
    self.buff_buffSignal = {}
    ---@type table
    self.buff_tips = {}
    
    self.buff = UIBackdrop(kit, UIGame)
        :relation(UI_ALIGN_LEFT_BOTTOM, UIGame, UI_ALIGN_BOTTOM, -0.054, 0.004)
        :size((self.buff_iSize * 0.8 + self.buff_iMar) * self.buff_max, self.buff_iSize)
    
    for i = 1, self.buff_max do
        self.buff_buffs[i] = UIButton(kit .. ':btn:' .. i, self.buff)
        if (i == 1) then
            self.buff_buffs[i]:relation(UI_ALIGN_CENTER, self.buff, UI_ALIGN_CENTER, -self.buff_max / 2 * (self.buff_iSize + self.buff_iMar), 0)
        else
            self.buff_buffs[i]:relation(UI_ALIGN_LEFT, self.buff_buffs[i - 1], UI_ALIGN_RIGHT, self.buff_iMar, 0)
        end
        self.buff_buffs[i]:size(self.buff_iSize * 0.8, self.buff_iSize)
            :fontSize(6.5)
            :maskRatio(1)
            :show(false)
            :onEvent(eventKind.uiLeave, function(_) UITooltips():show(false, 0) end)
            :onEvent(
            eventKind.uiEnter,
            function()
                local tips = self:tips(i)
                if (nil ~= tips) then
                    UITooltips()
                        :relation(UI_ALIGN_BOTTOM, self.buff_buffs[i], UI_ALIGN_TOP, 0, 0.002)
                        :content({ tips = tips })
                        :show(true)
                end
            end)
        self.buff_buffSignal[i] = UIBackdrop(kit .. ':signal:' .. i, self.buff_buffs[i])
            :relation(UI_ALIGN_CENTER, self.buff_buffs[i], UI_ALIGN_CENTER, 0, 0)
            :size(self.buff_iSize, self.buff_iSize)
    end
    
    -- 刷新
    if (nil == self._refresh) then
        async.loc(function()
            self._refresh = async.setInterval(7, function(curTimer)
                if (class.isDestroy(self)) then
                    class.destroy(curTimer)
                    self._refresh = nil
                    return
                end
                self:updated(PlayerLocal():selection())
            end)
        end)
    end
end

function ui:tips(i)
    if (nil ~= self.buff_tips and nil ~= self.buff_tips[i] and nil ~= self.buff_tips[i].tips) then
        return self.buff_tips[i].tips
    end
end

---@param whichUnit Unit
function ui:updated(whichUnit)
    local tmpData = {
        ---@type Unit
        buffTexture = {},
        buffAlpha = {},
        buffText = {},
        signalTexture = {},
        maskTexture = {},
        borderTexture = {},
    }
    self.buff_tips = {}
    if (class.isObject(whichUnit, UnitClass)) then
        if (whichUnit:isAlive()) then
            ---- 提取 附魔免疫
            --for _, v in ipairs(enchant.keys) do
            --    local isImmune = whichUnit:isEnchantImmune(v)
            --    if (isImmune) then
            --        local e = Enchant(v)
            --        local bt = {
            --            buffTexture = attribute.icon(e:key()),
            --            signalTexture = 'immune',
            --            maskTexture = X_UI_NIL,
            --            alpha = 255,
            --            text = '',
            --            tips = { attribute.label(SYMBOL_EI .. e:key()), colour.hex(colour.gold, "持久") }
            --        }
            --        table.insert(self.buff_tips, bt)
            --    end
            --end
            ---- 提取 附魔武器
            --local as = whichUnit:assault()
            --if (nil ~= as) then
            --    local damageType = as:damageType()
            --    if (type(damageType) == "table" and damageType.value ~= "common") then
            --        table.insert(self.buff_tips, {
            --            buffTexture = attribute.icon(damageType.value),
            --            signalTexture = 'weapon',
            --            maskTexture = X_UI_NIL,
            --            text = '',
            --            alpha = 255,
            --            tips = { attribute.label(SYMBOL_E .. damageType.value .. "Weapon"), colour.hex(colour.gold, "持久") },
            --        })
            --    end
            --end
            ---- 提取 附魔附着
            --local appending = whichUnit:enchantAppending()
            --if (type(appending) == "table") then
            --    for _, v in ipairs(enchant.keys) do
            --        ---@type noteEnchantAppendingData
            --        local a = appending[v]
            --        if (type(a) == "table") then
            --            local e = Enchant(v)
            --            local bt = {
            --                buffTexture = attribute.icon(e:key()),
            --                signalTexture = 'append',
            --                maskTexture = X_UI_NIL,
            --                alpha = 255,
            --            }
            --            if (a.level < 0) then
            --                bt.text = ''
            --                bt.tips = { attribute.label(SYMBOL_E .. e:key() .. "Append"), colour.hex(colour.gold, "持久") }
            --            else
            --                bt.text = math.format(a.timer:remain(), 1)
            --                bt.tips = { attribute.label(SYMBOL_E .. e:key() .. "Append"), a.level .. "级" }
            --            end
            --            table.insert(self.buff_tips, bt)
            --        end
            --    end
            --end
            local catch = BuffCatch(whichUnit, {
                limit = (self.buff_max - #self.buff_tips),
                ---@param enumBuff Buff
                filter = function(enumBuff)
                    return true == enumBuff:visible()
                end
            })
            if (#catch > 0) then
                for _, b in ipairs(catch) do
                    local isOdds = (string.subPos(b:key(), SYMBOL_ODD) == 1)
                    local isResistance = (string.subPos(b:key(), SYMBOL_RES) == 1)
                    local signalTexture = X_UI_NIL
                    local maskTexture = X_UI_NIL
                    if (isOdds) then
                        signalTexture = 'odds'
                    elseif (isResistance) then
                        signalTexture = 'resistance'
                    end
                    local lText = b:text()
                    local lAlpha = 255
                    local duration = b:duration()
                    if (duration > 0) then
                        local remain = b:remain()
                        local line = math.min(5, duration)
                        if (remain > line) then
                            lAlpha = 255
                        else
                            lAlpha = 55 + 200 * remain / line
                        end
                        if (nil == lText) then
                            lText = string.format('%0.1f', remain)
                        end
                    end
                    if (nil == lText) then
                        lText = ''
                    end
                    local s = b:signal()
                    if (s == "up") then
                        maskTexture = "up"
                    elseif (s == "down") then
                        maskTexture = "down"
                    end
                    table.insert(self.buff_tips, {
                        buffTexture = b:icon(),
                        signalTexture = signalTexture,
                        maskTexture = maskTexture,
                        text = lText,
                        alpha = lAlpha,
                        tips = b:description(),
                    })
                end
            end
            if (#self.buff_tips > 0) then
                for i, c in ipairs(self.buff_tips) do
                    tmpData.buffTexture[i] = c.buffTexture
                    tmpData.maskTexture[i] = c.maskTexture
                    tmpData.buffAlpha[i] = c.alpha
                    tmpData.buffText[i] = c.text
                    tmpData.signalTexture[i] = c.signalTexture
                end
            end
        end
    end
    for bi = 1, self.buff_max, 1 do
        if (nil ~= self.buff_tips[bi]) then
            self.buff_buffSignal[bi]:texture(japi.AssetsUI(self:kit(), tmpData.signalTexture[bi], "image"))
            self.buff_buffs[bi]:texture(tmpData.buffTexture[bi])
            self.buff_buffs[bi]:alpha(tmpData.buffAlpha[bi])
            self.buff_buffs[bi]:text(tmpData.buffText[bi])
            self.buff_buffs[bi]:mask(japi.AssetsUI(self:kit(), tmpData.maskTexture[bi], "image"))
            self.buff_buffs[bi]:show(true)
        else
            self.buff_buffs[bi]:show(false)
        end
    end
end