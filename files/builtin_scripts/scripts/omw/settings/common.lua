local storage = require('openmw.storage')

local contextSection = storage.playerSection or storage.globalSection
local groupSectionKey = 'OmwSettingGroups'
local groupSection = contextSection(groupSectionKey)
groupSection:removeOnExit()

local function validateSettingOptions(options)
    if type(options.key) ~= 'string' then
        error('Setting must have a key')
    end
    if type(options.saveOnly) ~= 'boolean' then
        error('Setting must be save only or not')
    end
    if type(options.renderer) ~= 'string' then
        error('Setting must have a renderer')
    end
    if type(options.name) ~= 'string' then
        error('Setting must have a name localization key')
    end
    if type(options.description) ~= 'string' then
        error('Setting must have a descripiton localization key')
    end
end

local function validateGroupOptions(options)
    if type(options.key) ~= 'string' then
        error('Group must have a key')
    end
    local conventionPrefix = "Settings"
    if options.key:sub(1, conventionPrefix:len()) ~= conventionPrefix then
        print(("Group key %s doesn't start with %s"):format(options.key, conventionPrefix))
    end
    if type(options.page) ~= 'string' then
        error('Group must belong to a page')
    end
    if type(options.l10n) ~= 'string' then
        error('Group must have a localization context')
    end
    if type(options.name) ~= 'string' then
        error('Group must have a name localization key')
    end
    if type(options.description) ~= 'string' then
        error('Group must have a description localization key')
    end
    if type(options.settings) ~= 'table' then
        error('Group must have a table of settings')
    end
    for _, opt in ipairs(options.settings) do
        validateSettingOptions(opt)
    end
end

local function registerSetting(options)
    return {
        key = options.key,
        saveOnly = options.saveOnly,
        default = options.default,
        renderer = options.renderer,
        argument = options.argument,

        name = options.name,
        description = options.description,
    }
end

local function registerGroup(options)
    validateGroupOptions(options)
    if groupSection:get(options.key) then
        error(('Group with key %s was already registered'):format(options.key))
    end
    local group = {
        key = options.key,
        page = options.page,
        l10n = options.l10n,
        name = options.name,
        description = options.description,

        settings = {},
    }
    local valueSection = contextSection(options.key)
    for _, opt in ipairs(options.settings) do
        local setting = registerSetting(opt)
        if group.settings[setting.key] then
            error(('Duplicate setting key %s'):format(options.key))
        end
        group.settings[setting.key] = setting
        if not valueSection:get(setting.key) then
            valueSection:set(setting.key, setting.default)
        end
    end
    groupSection:set(group.key, group)
end

return {
    getSection = function(global, key)
        return (global and storage.globalSection or storage.playerSection)(key)
    end,
    setGlobalEvent = 'OMWSettingsGlobalSet',
    groupSectionKey = groupSectionKey,
    onLoad = function(saved)
        if not saved then return end
        for groupKey, settings in pairs(saved) do
            local section = contextSection(groupKey)
            for key, value in pairs(settings) do
                section:set(key, value)
            end
        end
    end,
    onSave = function()
        local saved = {}
        for groupKey, group in pairs(groupSection:asTable()) do
            local section = contextSection(groupKey)
            saved[groupKey] = {}
            for key, value in pairs(section:asTable()) do
                if group.settings[key].saveOnly then
                    saved[groupKey][key] = value
                end
            end
        end
        groupSection:reset()
        return saved
    end,
    registerGroup = registerGroup,
    validateGroupOptions = validateGroupOptions,
}