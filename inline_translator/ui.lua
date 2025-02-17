local UIManager = require("ui/uimanager")
local Menu = require("ui/widget/menu")
local InfoMessage = require("ui/widget/infomessage")

local InlineTranslatorUI = {}

function InlineTranslatorUI:init()
    self.menu_items = {
        {text = "启用翻译", checked = true},
        {text = "翻译缓存", sub_item = true},
        {text = "清除缓存", callback = function()
            -- TODO: 实现清除缓存的功能
            UIManager:show(InfoMessage:new({
                text = "缓存已清除"
            }))
        end},
    }
    return true
end

function InlineTranslatorUI:addToMainMenu(menu_items)
    menu_items.inline_translator = {
        text = "内联翻译",
        sub_item = self.menu_items
    }
end

return InlineTranslatorUI