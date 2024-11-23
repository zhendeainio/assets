---@type UI_LikPlate
local ui = UIKit("xlik_plate")
function ui:updateWarehouse()
    async.loc(function()
        local p = PlayerLocal()
        --- 仓存显示
        local qty = #(p:warehouseSlot())
        local cell
        if (qty >= self.warehouseMAX) then
            cell = "仓库  " .. colour.hex(colour.red, qty .. "/" .. self.warehouseMAX)
        else
            cell = "仓库  " .. qty .. "/" .. self.warehouseMAX
        end
        self.warehouseCell:text(cell)
        --- 资源显示
        local r = p:worth()
        for i, k in ipairs(self.warehouseResAllow) do
            self.warehouseRes[i]:text(colour.hex(self.warehouseResOpt[k].color, math.floor(r[k] or 0)))
        end
        --- 仓库物品控制
        local storage = p:warehouseSlot():storage()
        for i = 1, self.warehouseMAX do
            ---@type Item
            local it = storage[i]
            if (false == class.isObject(it, ItemClass)) then
                self.warehouseButton[i]:show(false)
            else
                local texture = it:icon()
                local text = ''
                local border = "btn/border-white"
                local maskValue = 0
                local charge = math.floor(it:charges())
                if (charge > 0) then
                    local tw = math.max(0.008, string.len(tostring(charge)) * 0.004)
                    self.warehouseCharges[i]
                        :size(tw, 0.008)
                        :text(charge)
                        :show(true)
                else
                    self.warehouseCharges[i]:show(false)
                end
                self.warehouseButton[i]:texture(texture)
                self.warehouseButton[i]:border(border)
                self.warehouseButton[i]:maskRatio(maskValue)
                self.warehouseButton[i]:text(text)
                self.warehouseButton[i]:show(true)
            end
        end
    end)
end