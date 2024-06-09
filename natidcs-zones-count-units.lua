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
        local typesStringTbl = {}
        if unitsTypeCounterEmpty(unitTypesCounter) then
            table.insert(typesStringTbl, 'Congratulations! Zone is clear!')
        else
            for type, amount in pairs(unitTypesCounter) do
                table.insert(typesStringTbl, type..': '..amount)
            end
        end
        table.sort(typesStringTbl)
        return (prefix or 'Units in zone:')..'\n'..table.concat(typesStringTbl, '\n')
    end

    local function countAndReportUnitsInZone(zoneName)
        local zoneUnits = mist.getUnitsInZones(mist.makeUnitTable({'[red][vehicle]'}), {zoneName})
        local zoneUnitsTypeCounter = makeUnitsTypeCounter(zoneUnits);
        if not unitsTypeCountersEqual(zoneUnitsTypeCounter, missionUnitTypeCounters[zoneName]) then
            trigger.action.outText(unitsTypeCounterString(zoneUnitsTypeCounter, zoneName..' remaining units:'), 30)
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
            countAndReportUnitsInZone(unitZoneName);
        end
    end

    local function populateMenuForCountUnitsInZones(zonesByName)
        for zoneName in pairs(zonesByName) do
            missionCommands.addCommand('Units at '..zoneName, nil, function()
                if unitsTypeCounterEmpty(missionUnitTypeCounters[zoneName]) then
                    countAndReportUnitsInZone(zoneName);
                else
                    trigger.action.outText(unitsTypeCounterString(missionUnitTypeCounters[zoneName], zoneName..' remaining units:'), 30)
                end
            end)
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

    populateMenuForCountUnitsInZones(missionUnitTypeCounters)

    natidcs.showUnitCounterAtUnitDead = onUnitDead

end

-- world.addEventHandler(handler)
mist.addEventHandler(natidcs.showUnitCounterAtUnitDead)