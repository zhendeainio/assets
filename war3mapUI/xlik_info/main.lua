-- demo
local kit = "xlik_info"

---@class UI_LIK_INFO:UIKit
local ui = UIKit(kit)

function ui:onSetup()
    
    -- Echo 屏幕信息
    self.echo = UINative("UnitMessage", japi.DZ_FrameGetUnitMessage())
        :absolut(UI_ALIGN_LEFT_BOTTOM, 0.134, 0.18)
        :size(0, 0.36)
    
    -- Chat 居中聊天信息
    self.chat = UINative("ChatMessage", japi.DZ_FrameGetChatMessage())
        :absolut(UI_ALIGN_BOTTOM, 0, 0.22)
        :size(0.22, 0.16)
    
    self.mapNameBlack = UIBackdrop(kit, UIGame)
        :block(true)
        :absolut(UI_ALIGN_RIGHT_TOP, -0.005, -0.003)
        :size(0.07, 0.016)
        :texture(X_UI_BLACK)
    
    self.mapName = UIText(kit .. ":mn", self.mapNameBlack)
        :relation(UI_ALIGN_CENTER, self.mapNameBlack, UI_ALIGN_CENTER, 0, 0)
        :textAlign(TEXT_ALIGN_LEFT)
        :text(colour.hex(colour.gold, game.name))
    
    self.info = UIText(kit .. ":info", UIGame)
        :relation(UI_ALIGN_TOP, UIGame, UI_ALIGN_TOP, 0, -0.014)
        :textAlign(TEXT_ALIGN_CENTER)
        :fontSize(8)
        :text("")

end

function ui:updateInfo()
    self.info:text(table.concat(game.infoCenter, "|n"))
end