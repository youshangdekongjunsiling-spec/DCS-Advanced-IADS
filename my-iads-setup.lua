-- Minimal mission-specific Skynet setup for quick validation.
-- Load order in Mission Editor:
-- 1. mist_4_5_126.lua
-- 2. Skynet-IADS\demo-missions\skynet-iads-compiled.lua
-- 3. EA18G_EW_Script_improved_by_flyingsampig.lua
-- 4. my-iads-setup.lua

do

local IADS_NAME = "RED"
local EW_PREFIX = "EW"
local SAM_PREFIX = "SAM"
local JAMMER_UNIT_NAME = "Growler"
local ENABLE_RADIO_MENU = true
local JAMMER_POLL_INTERVAL = 5

if not SkynetIADS then
    trigger.action.outText("my-iads-setup: SkynetIADS not loaded, init aborted", 10)
    return
end

redIADS = SkynetIADS:create(IADS_NAME)

-- Keep debug output minimal for first validation.
local iadsDebug = redIADS:getDebugSettings()
iadsDebug.warnings = true
iadsDebug.IADSStatus = false
iadsDebug.contacts = false
iadsDebug.radarWentLive = false
iadsDebug.radarWentDark = false
iadsDebug.jammerProbability = false
iadsDebug.harmDefence = true

redIADS:addEarlyWarningRadarsByPrefix(EW_PREFIX)
redIADS:addSAMSitesByPrefix(SAM_PREFIX)

if ENABLE_RADIO_MENU then
    redIADS:addRadioMenu()
end

redIADS:activate()

local function tryConnectJammer(_, time)
    local activeJammer = _G.redIADSJammer
    if activeJammer and activeJammer.emitter and activeJammer.emitter:isExist() then
        return time + JAMMER_POLL_INTERVAL
    end

    local jammerSource = Unit.getByName(JAMMER_UNIT_NAME)
    if jammerSource and jammerSource:isExist() then
        local jammer = SkynetIADSJammer:create(jammerSource, redIADS)
        jammer:masterArmOn()
        _G.redIADSJammer = jammer
        _G.redIADSJammerWaitingNotified = false
        trigger.action.outText("my-iads-setup: jammer connected -> " .. JAMMER_UNIT_NAME, 10)
    elseif not _G.redIADSJammerWaitingNotified then
        _G.redIADSJammerWaitingNotified = true
        trigger.action.outText("my-iads-setup: IADS active, waiting for jammer unit -> " .. JAMMER_UNIT_NAME, 10)
    end

    return time + JAMMER_POLL_INTERVAL
end

trigger.action.outText("my-iads-setup: IADS active, jammer polling enabled", 10)
timer.scheduleFunction(tryConnectJammer, {}, timer.getTime() + 1)

end
