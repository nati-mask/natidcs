--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

do

    local function addPollingForUnits(units, func, interval)

        local scheduledDetection

        scheduledDetection = mist.scheduleFunction(function ()

            for i = 1, #units do
                local continue = func(units[i])
                if continue == false then
                    trigger.action.outText('Stopping detection polling', 30)
                    mist.removeFunction(scheduledDetection)
                end
            end

        end, {}, timer.getTime() + 10, interval);

    end

    local function addRadarDetectionPollingForUnits(detectingUnits, func, interval)

        addPollingForUnits(detectingUnits, function (detectingUnit)

            trigger.action.outText(
                'Checking what '..detectingUnit:getTypeName()
                ..' "'..detectingUnit:getName()..'"'..
                ' is detecting, radar enum: '..Controller.Detection.RADAR, 10
            )

            local controller = detectingUnit:getController();

            local detections = controller:getDetectedTargets(Controller.Detection.RADAR);

            for i = 1, #detections do
                local continue = func(detections[i], detectingUnit)
                if continue == false then return false end
            end

        end, interval)

    end

    local function pollIsGroupsRadarDetectedBy(detectingUnitsNames, detectedGroupsNames, requireType, interval)

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

            if requireType then
                if not unitDetection.type then return end
            end

            for i = 1, #detectedGroupsNames do
                if detectedUnitGroupName == detectedGroupsNames[i] then
                    trigger.action.outText(
                        'Unit Radar detected! '..
                        (requireType and '(-- Type is known --) ' or '')..
                        detectedUnit:getTypeName()..' "'..detectedUnit:getName()..'"',
                        interval
                    )
                    return false; -- false is for: stop the polling!
                end
            end

            -- local detectedUnit = detection.object;

            -- trigger.action.outText('The detected unit is: '..mist.utils.tableShow(detectedUnit), 30)

        end, interval)

    end

    natidcs.isGroupsRadarDetectedBy = pollIsGroupsRadarDetectedBy
end
