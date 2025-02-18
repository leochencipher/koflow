local InlineTranslator = {}

function InlineTranslator:new()
    local translator = {}
    setmetatable(translator, self)
    self.__index = self
    return translator
end

function InlineTranslator:init()
    -- 初始化翻译器
    self.ui = require("ui/uimanager")
    self.cache = {}
    self.sqlite3 = require("lsqlite3")
    self.db = self.sqlite3.open("dictionary.db")
    return true
end

function InlineTranslator:translateWord(word)
    -- 先检查缓存
    local lowered_word = word:lower()
    if self.cache[lowered_word] then
        return self.cache[lowered_word]
    end

    -- 从数据库查询翻译和词频
    if self.db then
        local stmt = self.db:prepare("SELECT translation, base_freq FROM dictionary WHERE word = ? COLLATE NOCASE")
        stmt:bind_values(lowered_word)
        
        local translation = nil
        local base_freq = nil
        if stmt:step() == self.sqlite3.ROW then
            translation = stmt:get_value(0)
            base_freq = stmt:get_value(1) or 0
            
            -- 根据词频决定是否翻译
            if math.random() < base_freq then
                -- 更新词频
                local new_freq = math.min(base_freq * 1.2, 1.0)
                local update_stmt = self.db:prepare("UPDATE dictionary SET base_freq = ? WHERE word = ? COLLATE NOCASE")
                update_stmt:bind_values(new_freq, lowered_word)
                update_stmt:step()
                update_stmt:finalize()
                
                -- 缓存结果
                self.cache[lowered_word] = translation
                return translation
            end
        end
        stmt:finalize()
    end

    return word
end

function InlineTranslator:processText(text)
    -- 使用正则表达式匹配英文单词
    local result = text:gsub("([a-zA-Z]+)", function(word)
        local translation = self:translateWord(word)
        if translation ~= word then
            -- 添加特殊标记用于点击交互
            return string.format("%s<click-translation id='%s'>%s</click-translation>", 
                word,
                word,
                translation
            )
        end
        return word
    end)
    return result
end

function InlineTranslator:handleTranslationClick(word_id)
    -- 处理翻译点击事件
    local translation_element = self.ui:getElementById(word_id)
    if translation_element then
        translation_element.visible = not translation_element.visible
        
        -- 如果隐藏翻译，则降低词频
        if not translation_element.visible then
            local lowered_word = word_id:lower()
            local stmt = self.db:prepare("SELECT base_freq FROM dictionary WHERE word = ? COLLATE NOCASE")
            stmt:bind_values(lowered_word)
            
            if stmt:step() == self.sqlite3.ROW then
                local current_freq = stmt:get_value(0) or 0
                local new_freq = math.max(current_freq * 0.5, 0.00001)
                
                local update_stmt = self.db:prepare("UPDATE dictionary SET base_freq = ? WHERE word = ? COLLATE NOCASE")
                update_stmt:bind_values(new_freq, lowered_word)
                update_stmt:step()
                update_stmt:finalize()
                
                -- 更新缓存
                if self.cache[lowered_word] then
                    self.cache[lowered_word] = nil
                end
            end
            stmt:finalize()
        end
        
        self.ui:refresh()
    end
end

function InlineTranslator:onReaderReady()
    -- 当阅读器准备就绪时的回调
    self:init()
end

return InlineTranslator