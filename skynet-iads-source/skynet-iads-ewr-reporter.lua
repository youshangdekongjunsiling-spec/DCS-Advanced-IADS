do

SkynetIADSEWRReporter = {}

local function normalizeHeading(deg)
    deg = deg % 360
    if deg < 0 then
        deg = deg + 360
    end
    return deg
end

local function normalizeDelta(delta)
    while delta > 180 do
        delta = delta - 360
    end
    while delta < -180 do
        delta = delta + 360
    end
    return delta
end

local function objectExists(obj)
    return obj and obj.isExist and obj:isExist()
end

local function get2dHeadingDeg(fromPoint, toPoint)
    local dx = toPoint.x - fromPoint.x
    local dz = toPoint.z - fromPoint.z
    if math.abs(dx) < 0.001 and math.abs(dz) < 0.001 then
        return 0
    end
    return normalizeHeading(math.deg(math.atan2(dx, dz)))
end

local function get2dDistanceMeters(fromPoint, toPoint)
    local dx = toPoint.x - fromPoint.x
    local dz = toPoint.z - fromPoint.z
    return math.sqrt(dx * dx + dz * dz)
end

local function getContactPoint(contact)
    if contact and contact.getPosition then
        local position = contact:getPosition()
        if position and position.p then
            return position.p
        end
    end
    local obj = contact and contact.getDCSRepresentation and contact:getDCSRepresentation() or nil
    if objectExists(obj) and obj.getPoint then
        return obj:getPoint()
    end
    return nil
end

local function isAirContact(contact)
    if not contact or not contact.getDesc then
        return false
    end
    local desc = contact:getDesc() or {}
    local category = desc.category
    return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
end

local function isPlayerAircraft(unit)
    if not objectExists(unit) then
        return false
    end
    local desc = unit:getDesc() or {}
    local category = desc.category
    return category == Unit.Category.AIRPLANE or category == Unit.Category.HELICOPTER
end

local function getContactDisplayType(contact)
    local typeName = contact and contact.getTypeName and contact:getTypeName() or "UNKNOWN"
    if typeName == nil or typeName == "" then
        typeName = "UNKNOWN"
    end
    return typeName
end

local function getContactHeadingDeg(contact)
    if not contact or not contact.getMagneticHeading then
        return 0
    end
    local heading = contact:getMagneticHeading()
    if heading == nil or heading < 0 then
        return 0
    end
    return normalizeHeading(heading)
end

local function getContactAltitudeAngels(contact)
    local feet = contact and contact.getHeightInFeetMSL and contact:getHeightInFeetMSL() or 0
    return math.max(0, math.floor((feet / 1000.0) + 0.5))
end

local function getAspectLabel(contactHeadingDeg, targetToPlayerHeadingDeg)
    local delta = normalizeDelta(contactHeadingDeg - targetToPlayerHeadingDeg)
    local absDelta = math.abs(delta)
    if absDelta <= 45 then
        return "HOT"
    end
    if absDelta >= 135 then
        return "COLD"
    end
    if delta > 0 then
        return "FLANK RIGHT"
    end
    return "FLANK LEFT"
end

function SkynetIADSEWRReporter:create(iads, options)
    local instance = {}
    setmetatable(instance, self)
    self.__index = self

    instance.iads = iads
    instance.intervalSeconds = (options and options.intervalSeconds) or 15
    instance.messageDurationSeconds = (options and options.messageDurationSeconds) or 8
    instance.maxContactsPerPlayer = (options and options.maxContactsPerPlayer) or 3
    instance.reportClean = (options and options.reportClean) == true
    instance.debugAllPlayers = (options and options.debugAllPlayers) == true
    instance.taskID = nil
    instance.lastSummaryByGroup = {}
    return instance
end

function SkynetIADSEWRReporter:getCoalition()
    if self.iads and self.iads.getCoalition then
        return self.iads:getCoalition()
    end
    return nil
end

function SkynetIADSEWRReporter:collectPlayerRecipients()
    local recipientsByGroup = {}
    local coalitionIds = {}
    if self.debugAllPlayers then
        coalitionIds = {
            coalition.side.RED,
            coalition.side.BLUE,
        }
    else
        local coalitionId = self:getCoalition()
        if coalitionId == nil then
            return {}
        end
        coalitionIds = { coalitionId }
    end

    for coalitionIndex = 1, #coalitionIds do
        local players = coalition.getPlayers(coalitionIds[coalitionIndex]) or {}
        for i = 1, #players do
            local unit = players[i]
            if isPlayerAircraft(unit) then
                local group = unit:getGroup()
                if group and group:isExist() then
                    local groupId = group:getID()
                    if recipientsByGroup[groupId] == nil then
                        recipientsByGroup[groupId] = {
                            groupId = groupId,
                            unit = unit
                        }
                    end
                end
            end
        end
    end

    local recipients = {}
    for _, recipient in pairs(recipientsByGroup) do
        table.insert(recipients, recipient)
    end
    return recipients
end

function SkynetIADSEWRReporter:collectReportableContacts()
    local contacts = self.iads and self.iads.getContacts and self.iads:getContacts() or {}
    local filtered = {}
    for i = 1, #contacts do
        local contact = contacts[i]
        if isAirContact(contact) and contact:isExist() and contact:isIdentifiedAsHARM() == false then
            table.insert(filtered, contact)
        end
    end
    return filtered
end

function SkynetIADSEWRReporter:formatContactLine(playerUnit, contact)
    local playerPos = playerUnit:getPoint()
    local contactPos = getContactPoint(contact)
    if not playerPos or not contactPos then
        return nil
    end

    local bearingDeg = get2dHeadingDeg(playerPos, contactPos)
    local distanceNm = mist.utils.metersToNM(get2dDistanceMeters(playerPos, contactPos))
    local contactHeadingDeg = getContactHeadingDeg(contact)
    local targetToPlayerHeadingDeg = get2dHeadingDeg(contactPos, playerPos)
    local aspectLabel = getAspectLabel(contactHeadingDeg, targetToPlayerHeadingDeg)
    local angels = getContactAltitudeAngels(contact)

    return string.format(
        "%s | A%d | Hdg %03d | BRAA %03d/%d | %s",
        getContactDisplayType(contact),
        angels,
        contactHeadingDeg,
        bearingDeg,
        math.floor(distanceNm + 0.5),
        aspectLabel
    ), distanceNm
end

function SkynetIADSEWRReporter:buildMessageForPlayer(playerUnit, contacts)
    local entries = {}
    for i = 1, #contacts do
        local line, distanceNm = self:formatContactLine(playerUnit, contacts[i])
        if line ~= nil then
            table.insert(entries, {
                line = line,
                distanceNm = distanceNm
            })
        end
    end

    table.sort(entries, function(a, b)
        return (a.distanceNm or math.huge) < (b.distanceNm or math.huge)
    end)

    if #entries == 0 then
        if self.reportClean then
            return "EWR Picture | CLEAN"
        end
        return nil
    end

    local lines = {"EWR Picture"}
    local limit = math.min(self.maxContactsPerPlayer, #entries)
    for i = 1, limit do
        lines[#lines + 1] = tostring(i) .. ". " .. entries[i].line
    end
    if #entries > limit then
        lines[#lines + 1] = string.format("+%d more", #entries - limit)
    end
    return table.concat(lines, "\n")
end

function SkynetIADSEWRReporter:broadcastTick()
    local contacts = self:collectReportableContacts()
    local recipients = self:collectPlayerRecipients()

    for i = 1, #recipients do
        local recipient = recipients[i]
        local message = self:buildMessageForPlayer(recipient.unit, contacts)
        if message ~= nil then
            trigger.action.outTextForGroup(recipient.groupId, message, self.messageDurationSeconds)
            self.lastSummaryByGroup[recipient.groupId] = message
        end
    end
end

function SkynetIADSEWRReporter._tick(params, time)
    local self = params and params.self or nil
    if not self or not self.iads then
        return nil
    end
    self:broadcastTick()
    return time + self.intervalSeconds
end

function SkynetIADSEWRReporter:start()
    if self.taskID ~= nil then
        return
    end
    self.taskID = mist.scheduleFunction(
        SkynetIADSEWRReporter._tick,
        {self = self},
        timer.getTime() + self.intervalSeconds,
        self.intervalSeconds
    )
    if self.iads and self.iads.printOutputToLog then
        self.iads:printOutputToLog("[EWRReporter] started | interval=" .. tostring(self.intervalSeconds) .. "s | topN=" .. tostring(self.maxContactsPerPlayer) .. " | debugAllPlayers=" .. tostring(self.debugAllPlayers))
    end
end

function SkynetIADSEWRReporter:stop()
    if self.taskID ~= nil then
        mist.removeFunction(self.taskID)
        self.taskID = nil
    end
end

trigger.action.outText("Skynet EWR Reporter module loaded", 10)

end
