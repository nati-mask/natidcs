--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

if natidcs.radarDetection then error('Someone is trying to load NatiDCS radar detection twice') end

natidcs.radarDetection = {}

do

    -- TODO: Cleanup:
    local testUnit
    local testPoint

    local logger

    -- TODO: Util!
    local function tableLength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end

    local function addPollingForUnits(units, func, interval)

        local scheduledDetection

        scheduledDetection = mist.scheduleFunction(function ()

            -- trigger.action.outText('Do Polling for '..#units..' units', interval)

            for i = 1, #units do
                local continue
                local success, result = pcall(function() return func(units[i]) end)
                if success then
                    continue = result
                else
                    trigger.action.outText('Error in Radar Detection Script at scheduled function:\n'..result, 120)
                    continue = false
                end
                if continue == false then
                    -- trigger.action.outText('Stopping polling for units', 30)
                    logger:info('Stopping polling session for units')
                    mist.removeFunction(scheduledDetection)
                end
            end

        end, {}, timer.getTime() + 10, interval)

    end

    local function addRadarDetectionPollingForUnits(detectingUnits, func, interval)

        local deadUnits = {}

        addPollingForUnits(detectingUnits, function (detectingUnit)

            if (tableLength(deadUnits) == #detectingUnits) then
                return false -- stop the polling
            end

            local controller = detectingUnit:getController()

            if (
                not detectingUnit:isActive() or
                not detectingUnit:isExist() or
                not controller
            ) then
                deadUnits[detectingUnit:getName()] = true -- "Set" like
                return
            end

            -- trigger.action.outText(
            --     'Checking what '..detectingUnit:getTypeName()
            --     ..' "'..detectingUnit:getName()..'"'..
            --     ' is detecting, radar enum: '..Controller.Detection.RADAR, 10
            -- )

            if testPoint and testUnit and testUnit:isExist() and testUnit:isActive() then
                local unitPoint = testUnit:getPoint()
                local dist = mist.utils.get3DDist(unitPoint, testPoint)
                local height = unitPoint.y
                -- trigger.action.outText('Test Unit: '..testUnit:getName()..' is here:\n'..mist.utils.tableShow(unitPoint), 5)
                local angRad = math.asin(height / dist)
                trigger.action.outText('Distance: '..dist..' Height: '..height..' Ang: '..mist.utils.toDegree(angRad), 5)
            end

            local detections = controller:getDetectedTargets(Controller.Detection.RADAR)

            for i = 1, #detections do
                local continue = func(detections[i], detectingUnit)
                if continue == false then return false end
            end

        end, interval)

    end

    local function pollIsGroupsRadarDetectedBy(detectingUnitsNames, detectedGroupsNames, flagNum, requireType, interval)

        if not mist then error('MIST is not loaded') end
        if not logger then logger = mist.Logger:new("Radar Detection Sctipt (Nati)", "info") end

        if not detectingUnitsNames or type(detectingUnitsNames) ~= 'table' then
            error('Missing Detecting Units (Radar) Names')
        end

        if not detectingUnitsNames or type(detectingUnitsNames) ~= 'table' then
            error('Missing Detecting Units (Radar) Names')
        end

        if not detectedGroupsNames or type(detectedGroupsNames) ~= 'table' then
            error('Missing Detected Groups Names')
        end

        local detectingUnits = {}

        for i = 1, #detectingUnitsNames do
            local unit = Unit.getByName(detectingUnitsNames[i])
            if (unit) then detectingUnits[#detectingUnits + 1] = unit end
        end

        if #detectingUnits == 0 then
            trigger.action.outText('Error: Empty list of detecting units provided, no radar detection polling started', 30)
            return
        end

        if (not interval) then interval = #detectingUnits * 2 end
        if (interval < 2) then interval = 2 end

        logger:info('Starting Detection in '..interval..'s for '..#detectingUnits..' detecting radar units')

        addRadarDetectionPollingForUnits(detectingUnits, function (unitDetection, detectingUnit)

            -- trigger.action.outText('The unit detection table is: '..mist.utils.tableShow(unitDetection), 30)
            local detectedUnit = unitDetection.object

            -- If unit is broken or out somehow, continue
            if (
                not detectedUnit or
                not detectedUnit['getGroup'] or
                not detectedUnit:isActive() or
                not detectedUnit:isExist()
            ) then return end

            local detectedUnitGroup = detectedUnit:getGroup()
            if not detectedUnitGroup then return end
            local detectedUnitGroupName = detectedUnitGroup:getName()

            -- TODO (still unused):
            if requireType then
                if not unitDetection.type then return end
            end

            for i = 1, #detectedGroupsNames do
                if detectedUnitGroupName == detectedGroupsNames[i] then
                    logger:info(
                        'Unit Radar detected! '..
                        (requireType and '(-- Type is known --) ' or '')..
                        detectedUnit:getTypeName()..' "'..detectedUnit:getName()..'"'..
                        (detectingUnit and (' by '..detectingUnit:getName()) or '')..
                        ' Jumping flag: '..(flagNum or 'UNSET')
                    )
                    if (flagNum) then trigger.action.setUserFlag(flagNum, true) end
                    return false -- false is for: stop the polling!
                end
            end

        end, interval)

    end

    natidcs.radarDetection.setTestUnit = function(unitName)
        if (testUnit) then error('NatiDCS Radar: there is already a test unit') end
        testUnit = Unit.getByName(unitName)
    end

    natidcs.radarDetection.isGroupsRadarDetectedBy = function(...)
        local arguments = {...}
        -- trigger.action.outText('Arguments:\n'..mist.utils.tableShow(arguments), 10)

        -- local ab = Airbase.getByName('Holmsley South')
        -- testPoint = ab:getPoint()

        -- trigger.action.outText('Test Airbase:\n'..mist.utils.tableShow(testPoint), 180)

        ---@diagnostic disable-next-line: deprecated
        local success, result = pcall(function() return pollIsGroupsRadarDetectedBy(unpack(arguments)) end)

        if not success then
            trigger.action.outText('Error in Radar Detection Script:\n'..result, 120)
        end
    end
end
