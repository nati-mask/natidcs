--[[
## Nati's additions to DCS
]]
natidcs = {}

do
    local missionUnitTypeCounters = {}

    local function unitsTypeCounterEmpty(typeCounter)
        for type, amount in pairs(typeCounter) do
            if amount > 0 then return false end
        end
        return true
    end

    local function unitsTypeCountersEqual(typeCounterA, typeCounterB)
        -- Since I never fount a safe way to count fields without for loop to count,
        -- then double comparison sounds like an efficient idea.
        for type, amount in pairs(typeCounterA) do
            if not typeCounterB[type] then return false end
            if typeCounterB[type] ~= amount then return false end
        end
        for type, amount in pairs(typeCounterB) do
            if not typeCounterA[type] then return false end
            if typeCounterA[type] ~= amount then return false end
        end
        return true
    end

    local function makeUnitsTypeCounter(unitsTable)

        local unitTypes = {}

        for i = 1, #unitsTable do

            local unitType = Unit.getTypeName(unitsTable[i])

            if (not unitTypes[unitType]) then
                unitTypes[unitType] = 1
            else
                unitTypes[unitType] = unitTypes[unitType] + 1
            end

        end

        return unitTypes
    end

    local function unitsTypeCounterString(unitTypesCounter, prefix)
        local typesString = prefix or 'Units in zone:'
        if unitsTypeCounterEmpty(unitTypesCounter) then return typesString..'\nCongratulations! Zone is clear!' end
        for type, amount in pairs(unitTypesCounter) do
            typesString = typesString..'\n'..type..': '..amount
        end
        return typesString
    end

    local function reportUnitsInZone(zoneName, zoneNameReadable)
        local readableName = zoneNameReadable or zoneName
        local zoneUnits = mist.getUnitsInZones(mist.makeUnitTable({'[red][vehicle]'}), {zoneName})
        local zoneUnitsTypeCounter = makeUnitsTypeCounter(zoneUnits);
        if not unitsTypeCountersEqual(zoneUnitsTypeCounter, missionUnitTypeCounters[zoneName]) then
            trigger.action.outText(unitsTypeCounterString(zoneUnitsTypeCounter, readableName..' units:'), 20)
            missionUnitTypeCounters[zoneName] = zoneUnitsTypeCounter;
        end
    end

    local function findZoneForDeadUnit(unit)
        for zoneName in pairs(missionUnitTypeCounters) do
            local zone = mist.DBs.zonesByName[zoneName];
            local unitPos = unit:getPosition().p

            if ((unitPos.x - zone.point.x)^2 + (unitPos.z - zone.point.z)^2)^0.5 <= zone.radius then
                return zoneName
            end
        end
        return nil
    end

    local function onUnitDead(event)
        if
            event.id == world.event.S_EVENT_DEAD
            and
            event.initiator
            and
            event.initiator:getCategory() == Object.Category.UNIT
        then

            local unitZoneName = findZoneForDeadUnit(event.initiator)
            -- trigger.action.outText('Type: '..event.initiator:getTypeName()..' just killed now!'..'\nZone: '..(unitZoneName or 'Unknown'), 10)
            reportUnitsInZone(unitZoneName);
        end
    end

    local function initUnitCountZones()
        local logString = 'Zones initializes for unit count:'
        for zoneName, zone in pairs(mist.DBs.zonesByName) do
            if zone.properties and zone.properties.COUNT_UNIT_TYPES then
                missionUnitTypeCounters[zoneName] = {}
                logString = logString..'\n - '..zoneName
            end
        end
        trigger.action.outText(logString, 15)
    end

    initUnitCountZones()

    natidcs.showUnitCounterAtUnitDead = onUnitDead

end

-- world.addEventHandler(handler)
mist.addEventHandler(natidcs.showUnitCounterAtUnitDead)