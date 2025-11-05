--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

if natidcs.radarDetection then error('Someone is trying to load NatiDCS radar detection twice') end

natidcs.radarDetection = {}

do

    -- TODO: Util!
    local function tableLength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end

    local function addPollingForUnits(self, func)

        local scheduledDetection

        scheduledDetection = mist.scheduleFunction(function ()

            for i = 1, #self.detectingUnits do
                local continue
                local success, result = pcall(function() return func(self.detectingUnits[i]) end)
                if success then
                    continue = result
                else
                    trigger.action.outText('Error in Radar Detection Script at scheduled function:\n'..result, 120)
                    continue = false
                end
                if continue == false then
                    -- trigger.action.outText('Stopping polling for units', 30)
                    self.logger:info('Stopping polling session for units')
                    mist.removeFunction(scheduledDetection)
                end
            end

        end, {}, timer.getTime() + 10, self.interval)

    end

    local function addRadarDetectionPollingForUnits(self, func)

        local deadUnits = {}

        self:addPollingForUnits(function (detectingUnit)

            if not detectingUnit then error('poll called on detecting unit that was never exists') end

            if (tableLength(deadUnits) == #self.detectingUnits) then
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

            -- TODO extract:
            local unitsSolver = {}
            for i = 1, #self.detectedGroupsNames do table.insert(unitsSolver, '[g]'..self.detectedGroupsNames[i]) end
            local allUnitsThatCanBeDetected = mist.makeUnitTable(unitsSolver)
            local angTexts = {}
            for i = 1, #allUnitsThatCanBeDetected do
                local unit = Unit.getByName(allUnitsThatCanBeDetected[i])
                if unit and unit:isExist() and unit:isActive() then
                    local unitPoint = unit:getPoint()
                    local radarPoint = detectingUnit:getPoint()
                    local ang = NatiMist.degAngleBetweenPoints(radarPoint, unitPoint)
                    table.insert(angTexts, 'Ang from radar: '..detectingUnit:getName()..' to '..unit:getName()..' is:\n'..ang)
                end
            end
            trigger.action.outText(table.concat(angTexts, '\n'), self.interval);


            local detections = controller:getDetectedTargets(Controller.Detection.RADAR)

            for i = 1, #detections do
                local continue = func(detections[i], detectingUnit)
                if continue == false then return false end
            end

        end, self.interval)

    end

    local function pollIsGroupsRadarDetectedBy(self)

        self.logger:info('Starting Detection polling in '..self.interval..'s for '..#self.detectingUnits..' detecting radar units')

        self:addRadarDetectionPollingForUnits(function (unitDetection, detectingUnit)

            -- Here we know a unit is detected:

            -- trigger.action.outText('The unit detection table is: '..mist.utils.tableShow(unitDetection), 30)
            local detectedUnit = unitDetection.object
            local requireType = nil

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

            for i = 1, #self.detectedGroupsNames do
                if detectedUnitGroupName == self.detectedGroupsNames[i] then
                    self.logger:info(
                        'Unit Radar detected! '..
                        (requireType and '(-- Type is known --) ' or '')..
                        detectedUnit:getTypeName()..' "'..detectedUnit:getName()..'"'..
                        (detectingUnit and (' by '..detectingUnit:getName()) or '')..
                        (self.flagNum and (' setting flag: '..self.flagNum..' to true.') or '')
                    )
                    if (self.flagNum) then trigger.action.setUserFlag(self.flagNum, true) end
                    if (self.onBlame) then self.onBlame(detectedUnit, detectingUnit) end
                    return false -- false is for: stop the polling!
                end
            end

        end, self.interval)

    end

    local function makeRadarPoller(detectingUnitsNames, detectedGroupsNames, options)

        if not mist then error('MIST is not loaded') end
        if not NatiMist then error('utilities built on MIST are not loaded') end

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
            error('Empty list of detecting units provided, no radar detection polling started', 30)
        end

        local interval = (options and type(options) == "table" and type(options.interval) == "number") and options.interval or nil
        if (not interval) then interval = #detectingUnits * 2 end
        if (interval < 2) then interval = 2 end

        return {
            logger = mist.Logger:new("Radar Detection Sctipt (Nati)", "info"),

            -- props:
            flagNum = (options and type(options) == 'table' and type(options.flagNum) == 'number') and options.flagNum or nil,
            onBlame = (options and type(options) == 'table' and type(options.onBlame) == 'function') and options.onBlame or nil,
            interval = interval,
            detectingUnits = detectingUnits,
            detectedGroupsNames = detectedGroupsNames,

            -- Methods:
            addRadarDetectionPollingForUnits = addRadarDetectionPollingForUnits,
            addPollingForUnits = addPollingForUnits,

            start = pollIsGroupsRadarDetectedBy
        }
    end

    natidcs.radarDetection.startRadarDetectionPolling = function(...)
        local arguments = {...}

        local success, result = pcall(function()
            ---@diagnostic disable-next-line: deprecated
            local radarDetectionPoller = makeRadarPoller(unpack(arguments))
            radarDetectionPoller:start()
            return radarDetectionPoller
        end)

        if not success then
            trigger.action.outText('Error in Radar Detection Script:\n'..result, 120)
        else
            return result -- radarDetectionPoller
        end
    end
end
