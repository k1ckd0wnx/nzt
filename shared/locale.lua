-- Shared Locale System
Locales = {}
CurrentLocale = nil

-- Load locale function
function LoadLocale(locale)
    local resourceName = GetCurrentResourceName()
    local localePath = ('locales/%s.lua'):format(locale)
    
    -- Try to load the locale file
    local localeData = LoadResourceFile(resourceName, localePath)
    if not localeData then
        print(("^1[Casino] Failed to load locale file: %s^0"):format(localePath))
        return false
    end
    
    -- Execute the locale file
    local localeFunc, err = load(localeData, localePath)
    if not localeFunc then
        print(("^1[Casino] Failed to parse locale file %s: %s^0"):format(localePath, err))
        return false
    end
    
    local success, result = pcall(localeFunc)
    if not success then
        print(("^1[Casino] Failed to execute locale file %s: %s^0"):format(localePath, result))
        return false
    end
    
    -- Store the locale data
    Locales[locale] = result
    CurrentLocale = result
    
    print(("^2[Casino] Loaded locale: %s^0"):format(locale))
    return true
end

-- Get localized text function
function _L(key, ...)
    if not CurrentLocale then
        return key
    end
    
    -- Split the key by dots to access nested tables
    local keys = {}
    for k in key:gmatch("[^%.]+") do
        table.insert(keys, k)
    end
    
    local value = CurrentLocale
    for _, k in ipairs(keys) do
        if type(value) == "table" and value[k] then
            value = value[k]
        else
            -- Fallback to key if not found
            return key
        end
    end
    
    -- If we have arguments, format the string
    if ... then
        local args = {...}
        return string.format(value, table.unpack(args))
    end
    
    return value
end

-- Get localized text with fallback
function _LF(key, fallback, ...)
    local result = _L(key, ...)
    if result == key then
        return fallback or key
    end
    return result
end

-- Initialize locale system
function InitializeLocale()
    local locale = Config and Config.Locale or 'en'
    
    -- Try to load the configured locale
    if not LoadLocale(locale) then
        print(("^3[Casino] Falling back to English locale^0"))
        -- Fallback to English
        if not LoadLocale('en') then
            print(("^1[Casino] Failed to load any locale! Text will not be translated.^0"))
        end
    end
end