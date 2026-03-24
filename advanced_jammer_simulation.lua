AdvancedJammerSimulation = AdvancedJammerSimulation or {}

do
    local sim = AdvancedJammerSimulation

    local function clamp(value, minValue, maxValue)
        if value < minValue then return minValue end
        if value > maxValue then return maxValue end
        return value
    end

    local function dbToLinear(db)
        return 10 ^ (db / 10)
    end

    local function linearToDb(linear)
        return 10 * math.log10(math.max(linear, 1e-12))
    end

    local function sigmaFromHPBW(hpbwDeg)
        return hpbwDeg / (2 * math.sqrt(2 * math.log(2)))
    end

    local function angleDeltaDeg(a, b)
        local d = math.abs(a - b) % 360
        if d > 180 then
            d = 360 - d
        end
        return d
    end

    local function get3dDistance(pos1, pos2)
        local dx = pos1.x - pos2.x
        local dy = (pos1.y or 0) - (pos2.y or 0)
        local dz = pos1.z - pos2.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end

    local function get2dDistance(pos1, pos2)
        local dx = pos1.x - pos2.x
        local dz = pos1.z - pos2.z
        return math.sqrt(dx * dx + dz * dz)
    end

    local function objectExists(obj)
        return obj and obj.isExist and obj:isExist()
    end

    local function getObjectName(obj)
        if not obj then return "unknown" end
        if obj.getName then
            local ok, name = pcall(function() return obj:getName() end)
            if ok and name then
                return name
            end
        end
        return "unknown"
    end

    local function makeTemplate(displayName, hpbwDeg, floorDb, sidelobes)
        return {
            displayName = displayName,
            hpbwDeg = hpbwDeg,
            floorDb = floorDb,
            floorLinear = dbToLinear(floorDb),
            sigmaMain = sigmaFromHPBW(hpbwDeg),
            sidelobes = sidelobes
        }
    end

    sim.CONFIG = {
        sigmoidK = 0.5,
        referenceRangeKm = 100.0,
        nmToKm = 1.852,
        jammerModes = {
            broadcast = 23.0,
            sector = 27.0,
            spot = 45.0
        },
        channelModel = {
            alq99ChannelCount = 1,
            alq99ChannelPower = 2,
            alq249ChannelCount = 2,
            alq249ChannelPower = 5
        }
    }

    sim.TEMPLATES = {
        omni_search = makeTemplate("Omni Search Radar", 24.0, -3.0, {
            {angleDeg = 15.0, amplitudeDb = -1.0, widthDeg = 18.0, symmetric = true},
            {angleDeg = 30.0, amplitudeDb = -2.0, widthDeg = 20.0, symmetric = true},
            {angleDeg = 45.0, amplitudeDb = -3.0, widthDeg = 22.0, symmetric = true},
            {angleDeg = 60.0, amplitudeDb = -4.0, widthDeg = 24.0, symmetric = true},
            {angleDeg = 75.0, amplitudeDb = -5.0, widthDeg = 26.0, symmetric = true},
            {angleDeg = 90.0, amplitudeDb = -6.0, widthDeg = 28.0, symmetric = true}
        }),
        legacy_fcr_wide = makeTemplate("Legacy Fire Control Radar", 10.0, -18.0, {
            {angleDeg = 12.0, amplitudeDb = -5.0, widthDeg = 8.0, symmetric = true},
            {angleDeg = 24.0, amplitudeDb = -8.0, widthDeg = 8.0, symmetric = true},
            {angleDeg = 36.0, amplitudeDb = -11.0, widthDeg = 8.0, symmetric = true},
            {angleDeg = 48.0, amplitudeDb = -14.0, widthDeg = 8.0, symmetric = true},
            {angleDeg = 60.0, amplitudeDb = -17.0, widthDeg = 8.0, symmetric = true},
            {angleDeg = 72.0, amplitudeDb = -20.0, widthDeg = 8.0, symmetric = true},
            {angleDeg = 84.0, amplitudeDb = -23.0, widthDeg = 8.0, symmetric = true}
        }),
        mid_fcr_compact = makeTemplate("Mid-Generation Fire Control Radar", 3.2, -36.0, {
            {angleDeg = 6.0, amplitudeDb = -9.0, widthDeg = 3.2, symmetric = true},
            {angleDeg = 12.0, amplitudeDb = -14.0, widthDeg = 3.2, symmetric = true},
            {angleDeg = 18.0, amplitudeDb = -19.0, widthDeg = 3.2, symmetric = true},
            {angleDeg = 24.0, amplitudeDb = -24.0, widthDeg = 3.2, symmetric = true},
            {angleDeg = 30.0, amplitudeDb = -30.0, widthDeg = 3.2, symmetric = true}
        }),
        aesa_fcr_narrow = makeTemplate("AESA Fire Control Radar", 1.2, -50.0, {
            {angleDeg = 2.5, amplitudeDb = -18.0, widthDeg = 1.2, symmetric = true},
            {angleDeg = 5.0, amplitudeDb = -28.0, widthDeg = 1.2, symmetric = true},
            {angleDeg = 8.0, amplitudeDb = -38.0, widthDeg = 1.2, symmetric = true},
            {angleDeg = 12.0, amplitudeDb = -46.0, widthDeg = 1.2, symmetric = true}
        })
    }

    sim.RADARS = {
        ["1L13 EWR"] = {templateKey = "omni_search", powerCoeffDb = 5.0},
        ["2S6 Tunguska"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 15.0},
        ["55G6 EWR"] = {templateKey = "omni_search", powerCoeffDb = 10.0},
        ["Buk SR 9S18M1"] = {templateKey = "omni_search", powerCoeffDb = 30.0},
        ["Dog Ear radar"] = {templateKey = "omni_search", powerCoeffDb = 20.0},
        ["EWR P-37 BAR LOCK"] = {templateKey = "omni_search", powerCoeffDb = 15.0},
        ["FPS-117"] = {templateKey = "omni_search", powerCoeffDb = 40.0},
        ["FPS-117 Dome"] = {templateKey = "omni_search", powerCoeffDb = 35.0},
        ["Gepard"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 13.0},
        ["HEMTT_C-RAM_Phalanx"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 3.0},
        ["HQ-7_STR_SP"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 15.0},
        ["Hawk sr"] = {templateKey = "omni_search", powerCoeffDb = 8.0},
        ["Hawk tr"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 10.0},
        ["Kub 1S91 str"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 15.0},
        ["Kub STR"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 20.0},
        ["NASAMS_Radar_MPQ64F1"] = {templateKey = "omni_search", powerCoeffDb = 20.0},
        ["Osa 9A33 ln"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 11.0},
        ["P-19 st"] = {templateKey = "omni_search", powerCoeffDb = 3.0},
        ["Patriot str"] = {templateKey = "aesa_fcr_narrow", powerCoeffDb = 50.0},
        ["RLS_19J6"] = {templateKey = "omni_search", powerCoeffDb = 35.0},
        ["RPC_5N62V"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 20.0},
        ["Roland ADS"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 14.0},
        ["Roland Radar"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 14.0},
        ["S-300PS 40B6M tr"] = {templateKey = "aesa_fcr_narrow", powerCoeffDb = 45.0},
        ["S-300PS 40B6MD sr"] = {templateKey = "omni_search", powerCoeffDb = 30.0},
        ["S-300PS 40B6MD sr_19J6"] = {templateKey = "omni_search", powerCoeffDb = 14.0},
        ["S-300PS 5H63C 30H6_tr"] = {templateKey = "aesa_fcr_narrow", powerCoeffDb = 45.0},
        ["S-300PS 64H6E sr"] = {templateKey = "omni_search", powerCoeffDb = 35.0},
        ["SA-11 Buk LN 9A310M1"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 35.0},
        ["SA-11 Buk SR 9S18M1"] = {templateKey = "omni_search", powerCoeffDb = 30.0},
        ["SA-17 Buk M1-2 LN"] = {templateKey = "aesa_fcr_narrow", powerCoeffDb = 39.0},
        ["SNR_75V"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 10.0},
        ["Strela-1 9P31"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 5.0},
        ["Strela-10M3"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 6.0},
        ["Tor 9A331"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 19.0},
        ["Tunguska_2S6"] = {templateKey = "mid_fcr_compact", powerCoeffDb = 15.0},
        ["ZSU-23-4 Shilka"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 8.0},
        ["p-19 s-125 sr"] = {templateKey = "omni_search", powerCoeffDb = 4.0},
        ["rapier_fsa_blindfire_radar"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 15.0},
        ["snr s-125 tr"] = {templateKey = "legacy_fcr_wide", powerCoeffDb = 8.0}
    }

    sim.DEFAULT_RADAR = {templateKey = "omni_search", powerCoeffDb = 20.0}

    function sim.getRadarProfile(radarTypeName)
        return sim.RADARS[radarTypeName] or sim.DEFAULT_RADAR
    end

    function sim.getLoadoutStats(alq99Count, alq249Count)
        alq99Count = tonumber(alq99Count) or 0
        alq249Count = tonumber(alq249Count) or 0

        local channelModel = sim.CONFIG.channelModel
        local totalChannels =
            (alq99Count * channelModel.alq99ChannelCount) +
            (alq249Count * channelModel.alq249ChannelCount)
        local totalPower =
            (alq99Count * channelModel.alq99ChannelCount * channelModel.alq99ChannelPower) +
            (alq249Count * channelModel.alq249ChannelCount * channelModel.alq249ChannelPower)
        local referencePower = channelModel.alq99ChannelCount * channelModel.alq99ChannelPower

        local gainDb = -120.0
        local enabled = false
        if totalPower > 0 and referencePower > 0 then
            gainDb = linearToDb(totalPower / referencePower)
            enabled = true
        end

        return {
            alq99 = alq99Count,
            alq249 = alq249Count,
            totalChannels = totalChannels,
            totalPower = totalPower,
            gainDb = gainDb,
            enabled = enabled
        }
    end

    function sim.computeRangeLossDb(rangeKm, isRadar)
        local ref = sim.CONFIG.referenceRangeKm
        if rangeKm <= 0 then
            rangeKm = ref
        end
        if isRadar then
            return 40.0 * math.log10(rangeKm / ref)
        end
        return 20.0 * math.log10(rangeKm / ref)
    end

    function sim.computeAltitudeBonusDb(jammerAltitudeM)
        if (jammerAltitudeM or 0) <= 0 then
            return 0.0
        end
        return jammerAltitudeM / 1000.0
    end

    function sim.sigmoidProbability(jsrDb, k)
        k = tonumber(k) or sim.CONFIG.sigmoidK
        return 1.0 / (1.0 + math.exp(-k * jsrDb))
    end

    function sim.getTemplateGainDb(templateKey, angleDeg)
        local template = sim.TEMPLATES[templateKey] or sim.TEMPLATES[sim.DEFAULT_RADAR.templateKey]
        local sum = math.exp(-(angleDeg * angleDeg) / (2 * template.sigmaMain * template.sigmaMain))

        for _, sidelobe in ipairs(template.sidelobes) do
            local amplitudeLinear = dbToLinear(sidelobe.amplitudeDb)
            local sigma = sigmaFromHPBW(sidelobe.widthDeg or template.hpbwDeg)
            local posDelta = angleDeltaDeg(angleDeg, sidelobe.angleDeg)
            sum = sum + amplitudeLinear * math.exp(-(posDelta * posDelta) / (2 * sigma * sigma))
            if sidelobe.symmetric and sidelobe.angleDeg ~= 0 then
                local negDelta = angleDeltaDeg(angleDeg, -sidelobe.angleDeg)
                sum = sum + amplitudeLinear * math.exp(-(negDelta * negDelta) / (2 * sigma * sigma))
            end
        end

        return linearToDb(math.max(sum, template.floorLinear))
    end

    function sim.resolveRadarTargetObject(radarUnit)
        if not objectExists(radarUnit) or not radarUnit.getRadar then
            return nil
        end
        local ok, radarOn, trackedObject = pcall(function()
            local on, tracked = radarUnit:getRadar()
            return on, tracked
        end)
        if ok and radarOn and objectExists(trackedObject) and trackedObject.getPoint then
            return trackedObject
        end
        return nil
    end

    function sim.findNearestVisibleEnemyAircraft(radarUnit)
        if not objectExists(radarUnit) then
            return nil, nil
        end

        local radarPos = radarUnit:getPoint()
        local radarCoalition = radarUnit:getCoalition()
        local patterns = nil
        if radarCoalition == coalition.side.RED then
            patterns = {"[blue][plane]", "[blue][helicopter]"}
        elseif radarCoalition == coalition.side.BLUE then
            patterns = {"[red][plane]", "[red][helicopter]"}
        else
            return nil, nil
        end

        local nearestUnit = nil
        local nearestDistance = nil
        for _, unitName in ipairs(mist.makeUnitTable(patterns)) do
            local unit = Unit.getByName(unitName)
            if objectExists(unit) then
                local unitPos = unit:getPoint()
                if land.isVisible(radarPos, unitPos) then
                    local distance = get3dDistance(radarPos, unitPos)
                    if nearestDistance == nil or distance < nearestDistance then
                        nearestDistance = distance
                        nearestUnit = unit
                    end
                end
            end
        end

        return nearestUnit, nearestDistance
    end

    function sim.resolveReferenceTarget(radarUnit)
        local trackedTarget = sim.resolveRadarTargetObject(radarUnit)
        if objectExists(trackedTarget) then
            return trackedTarget, get3dDistance(radarUnit:getPoint(), trackedTarget:getPoint()), "tracked"
        end

        local nearestUnit, nearestDistance = sim.findNearestVisibleEnemyAircraft(radarUnit)
        if objectExists(nearestUnit) and nearestDistance then
            return nearestUnit, nearestDistance, "nearest_visible_enemy"
        end

        return nil, nil, "fallback_self"
    end

    function sim.computeOffBoresightAngleDeg(radarPos, targetPos, jammerPos)
        if not radarPos or not targetPos or not jammerPos then
            return 0.0
        end

        local targetDx = targetPos.x - radarPos.x
        local targetDz = targetPos.z - radarPos.z
        local jammerDx = jammerPos.x - radarPos.x
        local jammerDz = jammerPos.z - radarPos.z

        local targetLen = math.sqrt(targetDx * targetDx + targetDz * targetDz)
        local jammerLen = math.sqrt(jammerDx * jammerDx + jammerDz * jammerDz)
        if targetLen <= 0 or jammerLen <= 0 then
            return 0.0
        end

        local cosTheta = ((targetDx * jammerDx) + (targetDz * jammerDz)) / (targetLen * jammerLen)
        cosTheta = clamp(cosTheta, -1.0, 1.0)
        return math.deg(math.acos(cosTheta))
    end

    function sim.evaluateScenario(params)
        local radarProfile = sim.getRadarProfile(params.radarTypeName)
        local loadout = sim.getLoadoutStats(params.alq99Count, params.alq249Count)
        local jammerModePowerDb = sim.CONFIG.jammerModes[params.jammerMode] or sim.CONFIG.jammerModes.spot
        local altitudeBonusDb = sim.computeAltitudeBonusDb(params.jammerAltitudeM or 0.0)
        local templateGainDb = sim.getTemplateGainDb(radarProfile.templateKey, params.angleDeg or 0.0)

        local jammerRangeKm = math.max((params.jammerRangeM or 0.0) / 1000.0, 0.1)
        local targetRangeKm = math.max((params.targetRangeM or params.jammerRangeM or 0.0) / 1000.0, 0.1)

        local effectiveJammerPowerDb =
            jammerModePowerDb +
            loadout.gainDb +
            (params.extraGainDb or 0.0) +
            altitudeBonusDb

        local jammerLossDb = sim.computeRangeLossDb(jammerRangeKm, false)
        local targetLossDb = sim.computeRangeLossDb(targetRangeKm, true)
        local jsrDb =
            (effectiveJammerPowerDb + templateGainDb - jammerLossDb) -
            (radarProfile.powerCoeffDb - targetLossDb)

        local probability = 0.0
        if params.losOk then
            probability = sim.sigmoidProbability(jsrDb, params.sigmoidK)
        end

        return {
            radarTypeName = params.radarTypeName,
            templateKey = radarProfile.templateKey,
            powerCoeffDb = radarProfile.powerCoeffDb,
            jammerMode = params.jammerMode,
            angleDeg = params.angleDeg or 0.0,
            jammerRangeM = params.jammerRangeM,
            targetRangeM = params.targetRangeM,
            losOk = params.losOk,
            loadoutGainDb = loadout.gainDb,
            loadoutTotalPower = loadout.totalPower,
            loadoutTotalChannels = loadout.totalChannels,
            altitudeBonusDb = altitudeBonusDb,
            jammerModePowerDb = jammerModePowerDb,
            templateGainDb = templateGainDb,
            effectiveJammerPowerDb = effectiveJammerPowerDb,
            jsrDb = jsrDb,
            probability = probability,
            probabilityPercent = probability * 100.0
        }
    end

    function sim.evaluateUnits(params)
        local jammerUnit = params.jammerUnit
        local radarUnit = params.radarUnit
        if not objectExists(jammerUnit) or not objectExists(radarUnit) then
            return nil
        end

        local jammerPos = jammerUnit:getPoint()
        local radarPos = radarUnit:getPoint()
        local jammerRangeM = get3dDistance(jammerPos, radarPos)
        local losOk = land.isVisible(radarPos, jammerPos)

        local targetObject, targetRangeM, targetSource = sim.resolveReferenceTarget(radarUnit)
        local targetPos = targetObject and targetObject:getPoint() or jammerPos
        if not targetRangeM or targetRangeM <= 0 then
            targetRangeM = jammerRangeM
        end

        local angleDeg = sim.computeOffBoresightAngleDeg(radarPos, targetPos, jammerPos)
        local result = sim.evaluateScenario({
            radarTypeName = radarUnit:getTypeName(),
            jammerMode = params.jammerMode or "spot",
            alq99Count = params.alq99Count or 0,
            alq249Count = params.alq249Count or 0,
            jammerAltitudeM = jammerPos.y or 0.0,
            jammerRangeM = jammerRangeM,
            targetRangeM = targetRangeM,
            angleDeg = angleDeg,
            losOk = losOk,
            extraGainDb = params.extraGainDb or 0.0,
            sigmoidK = params.sigmoidK or sim.CONFIG.sigmoidK
        })

        result.radarUnitName = getObjectName(radarUnit)
        result.targetObjectName = getObjectName(targetObject)
        result.targetSource = targetSource
        return result
    end

    sim.VERSION = "2026-03-19"
    if not sim._loadMessageSent then
        sim._loadMessageSent = true
        if env and env.info then
            env.info(string.format(
                "[AJS] Advanced Jammer Simulation loaded | version=%s | k=%.2f | ref=%.0fkm | modes=%.0f/%.0f/%.0f",
                sim.VERSION,
                sim.CONFIG.sigmoidK,
                sim.CONFIG.referenceRangeKm,
                sim.CONFIG.jammerModes.broadcast,
                sim.CONFIG.jammerModes.sector,
                sim.CONFIG.jammerModes.spot
            ), false)
        end
        if trigger and trigger.action and trigger.action.outText then
            trigger.action.outText(
                string.format(
                    "Advanced Jammer Simulation loaded | k=%.2f | ref %.0fkm | mode power B%.0f / S%.0f / P%.0f",
                    sim.CONFIG.sigmoidK,
                    sim.CONFIG.referenceRangeKm,
                    sim.CONFIG.jammerModes.broadcast,
                    sim.CONFIG.jammerModes.sector,
                    sim.CONFIG.jammerModes.spot
                ),
                10
            )
        end
    end
end
