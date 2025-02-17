local InlineTranslator = {}

function InlineTranslator:new()
    local translator = {}
    setmetatable(translator, self)
    self.__index = self
    return translator
end

function InlineTranslator:loadDictionary()
    local dictionary = {}
    local file = io.open("target.csv", "r")
    if not file then
        return {}
    end

    -- 跳过标题行
    file:read()

    for line in file:lines() do
        local word, _, _, translation = line:match("([^,]*),([^,]*),([^,]*),([^,]*)")
        if word and translation and translation ~= "" then
            dictionary[word:lower()] = translation
        end
    end

    file:close()
    return dictionary
end

function InlineTranslator:init()
    -- 初始化翻译器
    self.ui = require("ui/uimanager")
    self.cache = {}
    self.dictionary = self:loadDictionary()
    return true
end

function InlineTranslator:translateWord(word)
    -- 先检查缓存
    if self.cache[word:lower()] then
        return self.cache[word:lower()]
    end

    -- 从词典中查找翻译
    local translation = self.dictionary[word:lower()]
    if translation then
        -- 缓存结果
        self.cache[word:lower()] = translation
        return translation
    end

    return word
end

function InlineTranslator:processText(text)
    -- 使用正则表达式匹配英文单词
    local result = text:gsub("([a-zA-Z]+)", function(word)
        local translation = self:translateWord(word)
        if translation ~= word then
            return word .. "(" .. translation .. ")"
        end
        return word
    end)
    return result
end

function InlineTranslator:onReaderReady()
    -- 当阅读器准备就绪时的回调
    self:init()
end

return InlineTranslator