-- Minimal mission-specific Skynet setup for quick validation.
-- Load order in Mission Editor:
-- 1. mist_4_5_126.lua
-- 2. skynet-iads-compiled-ea18g.lua
-- 3. advanced_jammer_simulation.lua
-- 4. EA18G_EW_Script_improved_by_flyingsampig.lua
-- 5. my-iads-setup.lua
-- Mobile patrol is already integrated into skynet-iads-compiled-ea18g.lua.
-- Source is kept separately only for reading/editing:
-- Skynet-IADS\skynet-iads-source\skynet-iads-mobile-patrol.lua
-- EWR reporter is also integrated into skynet-iads-compiled-ea18g.lua.
-- Source is kept separately only for reading/editing:
-- Skynet-IADS\skynet-iads-source\skynet-iads-ewr-reporter.lua
-- Sibling coordination is also integrated into skynet-iads-compiled-ea18g.lua.
-- Source is kept separately only for reading/editing:
-- Skynet-IADS\skynet-iads-source\skynet-iads-sibling-coordination.lua

do

local IADS_NAME = "RED"
local EW_PREFIXES = { "EW", "MEW" }
local SAM_PREFIXES = { "SAM", "MSAM" }
local MOBILE_EW_PREFIX = "MEW"
local MOBILE_SAM_PREFIX = "MSAM"
local JAMMER_UNIT_NAME = "Growler"
local ENABLE_RADIO_MENU = true
local JAMMER_POLL_INTERVAL = 5
local ENABLE_MOBILE_PATROL = true
local ENABLE_EWR_REPORTER = true
local ENABLE_SIBLING_COORDINATION = true
local ENABLE_TACTICAL_RUNTIME_DEBUG = true
local TACTICAL_RUNTIME_DEBUG_DURATION_SECONDS = 8
local MobilePatrolModule = SkynetIADSMobilePatrol or MobileIADSPatrol
local EWRReporterModule = SkynetIADSEWRReporter
local SiblingCoordinationModule = SkynetIADSSiblingCoordination
local EWR_REPORT_INTERVAL_SECONDS = 15
local EWR_REPORT_DURATION_SECONDS = 8
local EWR_REPORT_MAX_CONTACTS = 3
local EWR_REPORT_CLEAN = false
local EWR_REPORT_DEBUG_ALL_PLAYERS = true
local SIBLING_FAMILIES = {
    {
        name = "MSAM ambush pair 1",
        members = { "MSAM-1", "MSAM-2" },
        mode = "ambush", -- ambush | denial
        primary = "MSAM-1",
        denialAlertDistanceNm = 25,
        passiveAction = "relocate",
    },
    {
        name = "MSAM ambush pair 2",
        members = { "MSAM-3", "MSAM-4" },
        mode = "ambush", -- ambush | denial
        primary = "MSAM-3",
        denialAlertDistanceNm = 25,
        passiveAction = "relocate",
    },
}

if not SkynetIADS then
    trigger.action.outText("my-iads-setup: SkynetIADS not loaded, init aborted", 10)
    return
end

_G.SkynetRuntimeDebug = {
    enabled = ENABLE_TACTICAL_RUNTIME_DEBUG,
    duration = TACTICAL_RUNTIME_DEBUG_DURATION_SECONDS,
}

_G.SkynetRuntimeDebugNotify = function(message)
    local debugConfig = _G.SkynetRuntimeDebug
    if debugConfig and debugConfig.enabled and message then
        trigger.action.outText("[SKYNET DBG] " .. tostring(message), debugConfig.duration or 8)
    end
end

redIADS = SkynetIADS:create(IADS_NAME)
redIADS:setUpdateInterval(1)

-- Keep debug output minimal for first validation.
local iadsDebug = redIADS:getDebugSettings()
iadsDebug.warnings = true
iadsDebug.IADSStatus = false
iadsDebug.contacts = false
iadsDebug.radarWentLive = false
iadsDebug.radarWentDark = false
iadsDebug.jammerProbability = false
iadsDebug.harmDefence = true

local function startsWithAnyPrefix(value, prefixes)
    for i = 1, #prefixes do
        if string.find(value, prefixes[i], 1, true) == 1 then
            return true
        end
    end
    return false
end

local function groupHasUnitWithAnyPrefix(group, prefixes)
    if not group or not group:isExist() then
        return false
    end
    local okUnits, units = pcall(function()
        return group:getUnits()
    end)
    if okUnits and units then
        for i = 1, #units do
            local unit = units[i]
            if unit and unit:isExist() and startsWithAnyPrefix(unit:getName(), prefixes) then
                return true
            end
        end
    end
    return false
end

local function describeGroupUnits(group)
    if not group or not group:isExist() then
        return "group missing"
    end
    local parts = {}
    local okUnits, units = pcall(function()
        return group:getUnits()
    end)
    if okUnits and units then
        for i = 1, #units do
            local unit = units[i]
            if unit and unit:isExist() then
                local unitName = unit:getName() or ("unit" .. i)
                local typeName = "unknown"
                local okDesc, desc = pcall(function()
                    return unit:getDesc()
                end)
                if okDesc and desc and desc.typeName then
                    typeName = desc.typeName
                end
                parts[#parts + 1] = unitName .. ":" .. typeName
            end
        end
    end
    if #parts == 0 then
        return "no live units"
    end
    return table.concat(parts, " | ")
end

local function countMobileGroupCandidates(prefix)
    local count = 0
    local names = {}
    for groupName, _ in pairs(mist.DBs.groupsByName) do
        local group = Group.getByName(groupName)
        if group and group:isExist() and (string.find(groupName, prefix, 1, true) == 1 or groupHasUnitWithAnyPrefix(group, { prefix })) then
            count = count + 1
            names[#names + 1] = groupName
        end
    end
    return count, table.concat(names, ", ")
end

local function countMobileUnitCandidates(prefix)
    local count = 0
    local names = {}
    for unitName, _ in pairs(mist.DBs.unitsByName) do
        if string.find(unitName, prefix, 1, true) == 1 then
            local unit = Unit.getByName(unitName)
            if unit and unit:isExist() then
                count = count + 1
                names[#names + 1] = unitName
            end
        end
    end
    return count, table.concat(names, ", ")
end

local function getRegisteredSAMNamesByPrefix(iads, prefix)
    local names = {}
    local samSites = iads:getSAMSites()
    for i = 1, #samSites do
        local samSite = samSites[i]
        local groupName = samSite:getDCSName()
        local group = Group.getByName(groupName)
        if string.find(groupName, prefix, 1, true) == 1 or groupHasUnitWithAnyPrefix(group, { prefix }) then
            names[#names + 1] = groupName
        end
    end
    return table.concat(names, ", ")
end

local function addEarlyWarningRadarsByPrefixes(iads, prefixes)
    iads:deactivateEarlyWarningRadars()
    iads.earlyWarningRadars = {}
    for unitName, _ in pairs(mist.DBs.unitsByName) do
        if startsWithAnyPrefix(unitName, prefixes) then
            local unit = Unit.getByName(unitName)
            if unit and unit:isExist() then
                iads:addEarlyWarningRadar(unitName)
            end
        end
    end
end

local function addSAMSitesByPrefixes(iads, prefixes)
    iads:deativateSAMSites()
    iads.samSites = {}
    local matchedCandidates = 0
    local registeredCount = 0
    local matchedNames = {}
    local registeredNames = {}
    local failedNames = {}
    local failedDetails = {}
    for groupName, _ in pairs(mist.DBs.groupsByName) do
        local group = Group.getByName(groupName)
        if group and group:isExist() and (startsWithAnyPrefix(groupName, prefixes) or groupHasUnitWithAnyPrefix(group, prefixes)) then
            matchedCandidates = matchedCandidates + 1
            matchedNames[#matchedNames + 1] = groupName
            local beforeCount = #iads.samSites
            iads:addSAMSite(groupName)
            if #iads.samSites > beforeCount then
                registeredCount = registeredCount + 1
                registeredNames[#registeredNames + 1] = groupName
            else
                failedNames[#failedNames + 1] = groupName
                failedDetails[#failedDetails + 1] = groupName .. " -> " .. describeGroupUnits(group)
            end
        end
    end
    return matchedCandidates, registeredCount, table.concat(matchedNames, ", "), table.concat(registeredNames, ", "), table.concat(failedNames, ", "), failedDetails
end

addEarlyWarningRadarsByPrefixes(redIADS, EW_PREFIXES)
local matchedSAMCandidates, registeredSAMSites, matchedSAMNames, registeredSAMNames, failedSAMNames, failedSAMDetails = addSAMSitesByPrefixes(redIADS, SAM_PREFIXES)
local mobileSAMCandidateCount, mobileSAMCandidateNames = countMobileGroupCandidates(MOBILE_SAM_PREFIX)
local mobileEWCandidateCount, mobileEWCandidateNames = countMobileUnitCandidates(MOBILE_EW_PREFIX)

if ENABLE_RADIO_MENU then
    redIADS:addRadioMenu()
end

redIADS:activate()

if ENABLE_MOBILE_PATROL and MobilePatrolModule then
    _G.redIADSMobilePatrol = MobilePatrolModule.create(redIADS, {
        checkInterval = 1,
    })
    local registeredSAM, registeredEW = _G.redIADSMobilePatrol:registerByPrefixes(MOBILE_SAM_PREFIX, MOBILE_EW_PREFIX, {
        checkInterval = 1,
    })
    local registeredMobileSAMNames = getRegisteredSAMNamesByPrefix(redIADS, MOBILE_SAM_PREFIX)
    _G.redIADSMobilePatrol:start()
    trigger.action.outText("my-iads-setup: mobile patrol active | MSAM=" .. registeredSAM .. " | MEW=" .. registeredEW, 10)
    if registeredMobileSAMNames ~= "" then
        trigger.action.outText("my-iads-setup: registered MSAM sites -> " .. registeredMobileSAMNames, 15)
    end
    if registeredSAM == 0 and mobileSAMCandidateCount > 0 then
        trigger.action.outText("my-iads-setup: MSAM candidates found but patrol registration failed | likely unsupported by Skynet or no route points | " .. mobileSAMCandidateNames, 15)
    end
    if registeredEW == 0 and mobileEWCandidateCount > 0 then
        trigger.action.outText("my-iads-setup: MEW candidates found but patrol registration failed | likely no route points | " .. mobileEWCandidateNames, 15)
    end
elseif ENABLE_MOBILE_PATROL then
    trigger.action.outText("my-iads-setup: mobile patrol module missing | reselect latest skynet-iads-compiled-ea18g.lua in Mission Editor", 15)
end

if ENABLE_SIBLING_COORDINATION and SiblingCoordinationModule then
    _G.redIADSSiblingCoordination = SiblingCoordinationModule.create(redIADS, {
        checkInterval = 1,
        defaultPassiveAction = "hold_dark",
        defaultMode = "ambush",
        defaultDenialAlertDistanceNm = 25,
    })
    local registeredSiblingFamilies, registeredSiblingMembers = _G.redIADSSiblingCoordination:registerFamilies(SIBLING_FAMILIES)
    if registeredSiblingFamilies > 0 then
        _G.redIADSSiblingCoordination:start()
        trigger.action.outText("my-iads-setup: sibling coordination active | families=" .. registeredSiblingFamilies .. " | members=" .. registeredSiblingMembers, 10)
    elseif #SIBLING_FAMILIES > 0 then
        trigger.action.outText("my-iads-setup: sibling coordination configured but no valid families registered", 10)
    end
elseif ENABLE_SIBLING_COORDINATION then
    trigger.action.outText("my-iads-setup: sibling coordination module missing | reselect latest skynet-iads-compiled-ea18g.lua in Mission Editor", 15)
end

if ENABLE_EWR_REPORTER and EWRReporterModule then
    _G.redIADSEWRReporter = EWRReporterModule:create(redIADS, {
        intervalSeconds = EWR_REPORT_INTERVAL_SECONDS,
        messageDurationSeconds = EWR_REPORT_DURATION_SECONDS,
        maxContactsPerPlayer = EWR_REPORT_MAX_CONTACTS,
        reportClean = EWR_REPORT_CLEAN,
        debugAllPlayers = EWR_REPORT_DEBUG_ALL_PLAYERS
    })
    _G.redIADSEWRReporter:start()
    trigger.action.outText("my-iads-setup: EWR reporter active | interval=" .. EWR_REPORT_INTERVAL_SECONDS .. "s | topN=" .. EWR_REPORT_MAX_CONTACTS .. " | debugAllPlayers=" .. tostring(EWR_REPORT_DEBUG_ALL_PLAYERS), 10)
elseif ENABLE_EWR_REPORTER then
    trigger.action.outText("my-iads-setup: EWR reporter module missing | reselect latest skynet-iads-compiled-ea18g.lua in Mission Editor", 15)
end

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
trigger.action.outText("my-iads-setup: SAM candidates=" .. matchedSAMCandidates .. " | registered=" .. registeredSAMSites, 10)
if matchedSAMNames ~= "" then
    trigger.action.outText("my-iads-setup: SAM matched -> " .. matchedSAMNames, 15)
end
if registeredSAMNames ~= "" then
    trigger.action.outText("my-iads-setup: SAM registered -> " .. registeredSAMNames, 15)
end
if failedSAMNames ~= "" then
    trigger.action.outText("my-iads-setup: SAM unsupported/failed -> " .. failedSAMNames, 15)
end
if failedSAMDetails and #failedSAMDetails > 0 then
    for i = 1, #failedSAMDetails do
        local detail = failedSAMDetails[i]
        trigger.action.outText("my-iads-setup: unsupported detail | " .. detail, 20)
        if redIADS and redIADS.printOutputToLog then
            redIADS:printOutputToLog("[Setup] unsupported detail | " .. detail)
        end
    end
end
timer.scheduleFunction(tryConnectJammer, {}, timer.getTime() + 1)

end
