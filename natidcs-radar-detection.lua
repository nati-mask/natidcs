--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

do

    local function addPollingForUnits(units, func, interval)

        local scheduled = mist.scheduleFunction(function ()

            for i = 1, #units do func(units[i]) end

        end, {}, timer.getTime() + 10, interval);

    end

    local function addRadarDetectionPollingForUnits(detectingUnits, func, interval)

        addPollingForUnits(detectingUnits, function (detectingUnit)

            -- trigger.action.outText('Checking what '..detectingUnit:getTypeName()..' is detecting, radar enum: '..Controller.Detection.RADAR, 10)

            local controller = detectingUnit:getController();

            local detections = controller:getDetectedTargets(Controller.Detection.RADAR);

            for i = 1, #detections do func(detections[i], detectingUnit) end

        end, interval)

    end

    local function pollIsGroupsRadarDetectedBy(detectingUnitsNames, detectedGroupsNames, interval)

        if not mist then return end

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

        addRadarDetectionPollingForUnits(detectingUnits, function (unitDetection, detectingUnit)

            -- trigger.action.outText('The unit detection table is: '..mist.utils.tableShow(unitDetection), 30)
            local detectedUnit = unitDetection.object
            if (not detectedUnit) then return end

            for i = 1, #detectedGroupsNames do
                local detectedUnitGroup = detectedUnit:getGroup();
                if (detectedUnitGroup and detectedUnitGroup:getName() == detectedGroupsNames[i]) then
                    trigger.action.outText(
                        'Unit Radar detected! '..detectedUnit:getTypeName()..' ("'..detectedUnit:getName()..'")'..'\n'..
                        'within in allowed group: '..detectedGroupsNames[i],
                        interval
                    )
                    return false;
                end
            end

            -- local detectedUnit = detection.object;

            -- trigger.action.outText('The detected unit is: '..mist.utils.tableShow(detectedUnit), 30)

        end, interval)

    end

    natidcs.isGroupsRadarDetectedBy = pollIsGroupsRadarDetectedBy
end
