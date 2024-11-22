-- debug提示
if (LK_DEBUG) then
    
    collectgarbage("collect")
    local ramCount = collectgarbage("count")
    
    local kit = "xlik_debug"
    
    ---@class UI_LikDebug:UIKit
    local ui = UIKit(kit)
    
    function ui:onSetup()
        
        self.main = UIText(kit, UIGame)
            :relation(UI_ALIGN_LEFT_TOP, UIGame, UI_ALIGN_LEFT_TOP, 0.003, -0.03)
            :textAlign(TEXT_ALIGN_LEFT)
            :fontSize(6)
        
        self.ram = UIText(kit .. ":ram", UIGame)
            :adaptive(true)
            :relation(UI_ALIGN_RIGHT_TOP, UIGame, UI_ALIGN_TOP, -0.06, -0.03)
            :textAlign(TEXT_ALIGN_LEFT)
            :fontSize(7)
        
        self.mark = UIBackdrop(kit .. ":mark", UIGame)
            :relation(UI_ALIGN_CENTER, UIGame, UI_ALIGN_CENTER, 0, 0)
            :size(2, 2)
            :alpha(100)
            :texture(BLP_COLOR_BLACK)
            :show(false)
        
        ---@type UIBackdrop[]
        self.line = {}
        local graduation = 0.05
        local texture = BLP_COLOR_YELLOW
        local txtColor = "ffe600"
        for i = 1, math.floor(0.6 / graduation - 0.5), 1 do
            local tile = UIBackdrop(kit .. ":horizontal:" .. i, UIGame)
                :relation(UI_ALIGN_BOTTOM, UIGame, UI_ALIGN_BOTTOM, 0, graduation * i)
                :size(2, 0.001)
                :texture(texture)
                :show(false)
            UIText(kit .. ":horizontal:txt:" .. i, tile)
                :relation(UI_ALIGN_LEFT, tile, UI_ALIGN_LEFT, 0.002, 0.01)
                :textAlign(TEXT_ALIGN_LEFT)
                :fontSize(12)
                :text(colour.hex(txtColor, graduation * i))
            table.insert(self.line, tile)
        end
        for i = 1, math.floor(0.8 / graduation - 0.5), 1 do
            local tile = UIBackdrop(kit .. ":vertical:" .. i, UIGame)
                :relation(UI_ALIGN_LEFT, UIGame, UI_ALIGN_LEFT, graduation * i, 0)
                :size(0.001, 2)
                :texture(texture)
                :show(false)
            UIText(kit .. ":vertical:txt:" .. i, tile)
                :relation(UI_ALIGN_BOTTOM, tile, UI_ALIGN_BOTTOM, 0.01, 0.01)
                :textAlign(TEXT_ALIGN_LEFT)
                :fontSize(12)
                :text(colour.hex(txtColor, graduation * i))
            table.insert(self.line, tile)
        end
        
        self.costAvg = self.costAvg or {}
        self.types = { "all", "max" }
        self.typesLabel = {
            all = "当前句柄数",
            max = "最大句柄数",
            ["+EIP"] = "对点特效",
            ["+EIm"] = "附着特效",
            ["+cst"] = "镜头",
            ["+dlb"] = "对话框按钮",
            ["+dlg"] = "对话框",
            ["+fgm"] = "可见修正器",
            ["+flt"] = "过滤器",
            ["+frc"] = "玩家势力",
            ["+grp"] = "单位组",
            ["+loc"] = "点",
            ["+ply"] = "玩家",
            ["+que"] = "任务",
            ["+rct"] = "矩形区域",
            ["+agr"] = "不规则区域",
            ["+rev"] = "不规则区域事件",
            ["+snd"] = "声音",
            ["+tac"] = "触发器动作",
            ["+tmr"] = "计时器",
            ["+trg"] = "触发器",
            ["+w3d"] = "可破坏物",
            ["+w3u"] = "单位",
            ["devt"] = "对话框事件",
            ["pcvt"] = "玩家聊天事件",
            ["pevt"] = "玩家事件",
            ["tcnd"] = "触发器条件",
            ["uevt"] = "单位事件",
            ["wdvt"] = "可破坏物事件",
        }
    end
    
    function ui:onStart()
        async.loc(function()
            async.setInterval(15, function()
                local p = PlayerLocal()
                if (p:isPlaying() and false == p:isComputer()) then
                    local ram = self:getRam()
                    local msg = self:getMsg()
                    self.ram:text(table.concat(ram, '   '))
                    self.main:text(table.concat(msg, '|n'))
                    local show = keyboard.isPressing(keyboard.code["Control"])
                    self.mark:show(show)
                    for _, l in ipairs(self.line) do
                        l:show(show)
                    end
                end
            end)
        end)
    end
    
    function ui:getRam()
        local cost = (collectgarbage("count") - ramCount) / 1024
        if (nil == self.costMax or self.costMax < cost) then
            self.costMax = cost
        end
        local avg = 0
        if (#self.costAvg < 100) then
            table.insert(self.costAvg, cost)
            avg = table.average(self.costAvg)
        else
            avg = table.average(self.costAvg)
            self.costAvg = { avg }
        end
        local fps = japi.DZ_GetFPS() * 0.01
        return {
            colour.hex(colour.gold, "FPS : " .. string.format(fps, 1)),
            colour.hex(colour.skyblue, "平均 : " .. math.format(avg, 3) .. ' MB'),
            colour.hex(colour.littlepink, "最大 : " .. math.format(self.costMax, 3) .. ' MB'),
            "当前 : " .. math.format(cost, 3) .. ' MB',
        }
    end
    
    function ui:getMsg()
        local data = class.debug()
        local txts = {}
        local count = { all = 0, max = J.HandleMax() }
        for i = 1, count.max do
            local h = 0x100000 + i
            local info = J.HandleDef(h)
            if (info and info.type) then
                if (false == table.includes(self.types, info.type)) then
                    table.insert(self.types, info.type)
                end
                if (nil == count[info.type]) then
                    count[info.type] = 0
                end
                count.all = count.all + 1
                count[info.type] = count[info.type] + 1
            end
        end
        table.insert(txts, ">>  内核")
        for _, v in ipairs(self.types) do
            table.insert(txts, (self.typesLabel[v] or v) .. " : " .. (count[v] or 0))
        end
        table.insert(txts, "模型漂浮字 : " .. mtg._count)
        table.insert(txts, ">>  Meta")
        for k, v in pairx(data.Meta) do
            table.insert(txts, k .. " : " .. v)
        end
        table.insert(txts, ">>  UI")
        for k, v in pairx(data.UI) do
            table.insert(txts, k .. " : " .. v)
        end
        table.insert(txts, ">>  Vast")
        for k, v in pairx(data.Vast) do
            table.insert(txts, k .. " : " .. v)
        end
        return txts
    end
end