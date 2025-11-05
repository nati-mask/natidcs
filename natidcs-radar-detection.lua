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

            trigger.action.outText('Do Polling for '..#self.detectingUnits..' units', self.interval)

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

        trigger.action.outText('Polling now...', 20)

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

            if self.testUnit and self.testUnit:isExist() and self.testUnit:isActive() then
                local unitPoint = self.testUnit:getPoint()
                local radarPoint = detectingUnit:getPoint()
                local ang = NatiMist.degAngleBetweenPoints(radarPoint, unitPoint)
                trigger.action.outText('Ang to: '..detectingUnit:getName()..' is: '..ang, self.interval)
            end

            local detections = controller:getDetectedTargets(Controller.Detection.RADAR)

            for i = 1, #detections do
                local continue = func(detections[i], detectingUnit)
                if continue == false then return false end
            end

        end, self.interval)

    end

    local function pollIsGroupsRadarDetectedBy(self)

        self.logger:info('Starting Detection polling in '..self.interval..'s for '..#self.detectingUnits..' detecting radar units')

        trigger.action.outText('Starting...', 16)

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

    local setTestUnit = function(self, unitName)
        if (self.testUnit) then error('NatiDCS Radar: there is already a test unit') end
        self.testUnit = Unit.getByName(unitName)
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
            testUnit = nil,
            detectingUnits = detectingUnits,
            detectedGroupsNames = detectedGroupsNames,

            -- Methods:
            setTestUnit = setTestUnit,
            addRadarDetectionPollingForUnits = addRadarDetectionPollingForUnits,
            addPollingForUnits = addPollingForUnits,

            start = pollIsGroupsRadarDetectedBy
        }
    end

    natidcs.radarDetection.startRadarDetectionPolling = function(...)
        local arguments = {...}
        trigger.action.outText('Polling with self poller! Arguments:\n'..mist.utils.tableShow(arguments), 10)

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
