-- 小地图
local kit = "xlik_minimap"

---@class UI_LikMinimap:UIKit
local ui = UIKit(kit)

function ui:onSetup()
    -- 小地图边框背景
    self.main = UIBackdrop(kit .. ':main', UIGame)
        :adaptive(true)
        :relation(UI_ALIGN_LEFT_BOTTOM, UIGame, UI_ALIGN_LEFT_BOTTOM, 0, 0)
        :size(0.207, 0.1541666667)
    
    local width = 0.122
    
    -- 小地图
    self.map = UINative('Minimap', japi.DZ_FrameGetMinimap())
        :relation(UI_ALIGN_LEFT_BOTTOM, UIGame, UI_ALIGN_LEFT_BOTTOM, 0.0036, 0.006)
        :size(width * 0.75, width)
    
    --- 小地图按钮
    -----@type table<number,UINative>
    self.btns = {}
    local offset = {
        { 0.0018, -0.005 },
        { 0.0022, -0.005 - 0.021 },
        { 0.0020, -0.005 - 0.021 - 0.018 },
        { 0.0023, -0.005 - 0.021 - 0.018 - 0.018 },
        { 0.0022, -0.005 - 0.021 - 0.018 - 0.018 - 0.025 },
    }
    for i = 0, 4 do
        self.btns[i] = UINative("MinimapButton" .. i, japi.DZ_FrameGetMinimapButton(i))
            :relation(UI_ALIGN_LEFT_TOP, self.map, UI_ALIGN_RIGHT_TOP, offset[i + 1][1], offset[i + 1][2])
            :size(0.013, 0.013)
    end
    
    --- 默认皮肤
    local p = PlayerLocal()
    async.call(p, function()
        if (p:isPlaying()) then
            self.main:texture("bg/" .. game.skin)
        end
    end)
end