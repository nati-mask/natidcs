--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

if natidcs.radarDetection then error('Someone is trying to load NatiDCS radar detection twice') end

natidcs.radarDetection = {}

do

    -- TODO: Utils:
    local function tableLength(T)
        local count = 0
        for _ in pairs(T) do count = count + 1 end
        return count
    end
    local function seqContainsValue(tbl, value)
        for i = 1, #tbl do
            if tbl[i] == value then return true end
        end
        return false
    end

    -- Will return unit objects pointers, including dead units!
    local function getPossibleDetectedUnits(self)
        local units = {}
        local unitsSolver = {}
        for i = 1, #self.detectedGroupsNames do table.insert(unitsSolver, '[g]'..self.detectedGroupsNames[i]) end
        local possibleDetectedUnits = mist.makeUnitTable(unitsSolver)
        for i = 1, #possibleDetectedUnits do
            local unit = Unit.getByName(possibleDetectedUnits[i])
            if (unit) then table.insert(units, unit) end
        end
        return units
    end

    local function getRadarAngleToUnit(radarUnit, unit)
        if (not radarUnit or not unit) then error('checking angle between falsey units') end
        if radarUnit:isExist() and radarUnit:isActive() and unit:isExist() and unit:isActive() then
            local radarPoint = radarUnit:getPoint()
            local unitPoint = unit:getPoint()
            return NatiMist.degAngleBetweenPoints(radarPoint, unitPoint)
        else
            return nil
        end
    end

    local function getAllUnitsRadarIsDetecting(self, radarUnit)
        local controller = radarUnit:getController()
        if (not controller) then error('There is no DCS controller for Radar Unit') end

        local detections = controller:getDetectedTargets(Controller.Detection.RADAR)

        local detectedUnits = {}

        for i = 1, #detections do
            local detectedUnit = detections[i].object
            if (
                detectedUnit and
                detectedUnit['getGroup'] and
                detectedUnit:isActive() and
                detectedUnit:isExist()
            ) then
                local detectedUnitGroup = detectedUnit:getGroup()
                if (
                    detectedUnitGroup and
                    seqContainsValue(self.detectedGroupsNames, detectedUnitGroup:getName())
                ) then
                    table.insert(detectedUnits, detectedUnit)
                end
            end
        end

        return detectedUnits
    end

    local function thePollFunction(self, cbForSingleDetectingUnit)

        for _, radarDetection in pairs(self.detectionTable) do
            trigger.action.outText('Radar Detection for: '..radarDetection.name..'\n'..radarDetection:concat(), self.interval);
        end


        for i = 1, #self.detectingUnits do
            local continue = cbForSingleDetectingUnit(self.detectingUnits[i])
            if continue == false then return false end
        end
    end

    local function addPollingForUnits(self, cbForSingleDetectingUnit)

        local scheduledDetection

        scheduledDetection = mist.scheduleFunction(function ()

            local continue
            local success, result = pcall(function() return self:thePollFunction(cbForSingleDetectingUnit) end)
            if success then
                continue = result
            else
                trigger.action.outText('Error in Radar Detection Script at scheduled function:\n'..result, 120)
                continue = false
            end
            if continue == false then
                -- trigger.action.outText('Stopping polling for units', 30)
                self.logger:info('Stopped radar detection for units')
                if (self.debug) then
                    trigger.action.outText('Stopped radar detection for units:\n'..result, 60)
                end
                mist.removeFunction(scheduledDetection)
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

            if (
                not detectingUnit:isActive() or
                not detectingUnit:isExist()
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
            local allUnitsThatCanBeDetected = self:getPossibleDetectedUnits()
            local angTexts = {}
            for i = 1, #allUnitsThatCanBeDetected do
                local unit = allUnitsThatCanBeDetected[i]
                local ang = getRadarAngleToUnit(detectingUnit, unit)
                if (ang) then
                    table.insert(angTexts, 'Ang from radar: '..detectingUnit:getName()..' to '..unit:getName()..' is:\n'..ang)
                end
            end
            trigger.action.outText(table.concat(angTexts, '\n'), self.interval);

            local unitsDetected = self:getAllUnitsRadarIsDetecting(detectingUnit)
            for i = 1, #unitsDetected do
                local unit = unitsDetected[i]
                self.detectionTable[detectingUnit:getName()]:add(unit:getName(), getRadarAngleToUnit(detectingUnit, unit))
                local continue = func(unit, detectingUnit)
                if continue == false then return false end
            end

        end, self.interval)

    end

    local function pollIsGroupsRadarDetectedBy(self)

        self.logger:info('Starting Detection polling in '..self.interval..'s for '..#self.detectingUnits..' detecting radar units')

        self:addRadarDetectionPollingForUnits(function (detectedUnit, detectingUnit)

            -- A unit is detected!
            self.logger:info(
                'Unit Radar detected! '..
                detectedUnit:getTypeName()..' "'..detectedUnit:getName()..'"'..
                (detectingUnit and (' by '..detectingUnit:getName()) or '')..
                (self.flagNum and (' setting flag: '..self.flagNum..' to true.') or '')
            )
            if (self.flagNum) then trigger.action.setUserFlag(self.flagNum, true) end
            if (self.onBlame) then self.onBlame(detectedUnit, detectingUnit) end
            if (not self.countinous) then return false end -- false is for: stop the polling!

        end, self.interval)

    end

    local function makeRadarPoller(detectingUnitsNames, detectedGroupsNames, options)

        if not mist then error('MIST is not loaded') end
        if not Natils then error('simple utilities for DCS (Natils) are not loaded') end
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
        local detectionTable = {}

        for i = 1, #detectingUnitsNames do
            local detectingUnitsName = detectingUnitsNames[i]
            local unit = Unit.getByName(detectingUnitsName)
            if (unit) then
                table.insert(detectingUnits, unit)
                detectionTable[detectingUnitsName] = Natils.createDictSet('Detection('..detectingUnitsName..')')
            end
        end

        if #detectingUnits == 0 then
            error('No existing detecting units (radars) provided', 30)
        end

        local interval = (options and type(options) == "table" and type(options.interval) == "number") and options.interval or nil
        if (not interval) then interval = #detectingUnits * 2 end
        if (interval < 2) then interval = 2 end

        return {
            logger = mist.Logger:new("Radar Detection Sctipt (Nati)", "info"),

            -- props:
            countinous = (options and type(options) == 'table' and type(options.countinous) == 'boolean') and options.countinous or false,
            flagNum = (options and type(options) == 'table' and type(options.flagNum) == 'number') and options.flagNum or nil,
            onBlame = (options and type(options) == 'table' and type(options.onBlame) == 'function') and options.onBlame or nil,
            interval = interval,
            detectingUnits = detectingUnits,
            detectedGroupsNames = detectedGroupsNames,
            detectionTable = detectionTable,

            -- Methods:
            getAllUnitsRadarIsDetecting = getAllUnitsRadarIsDetecting,
            getPossibleDetectedUnits = getPossibleDetectedUnits,
            addRadarDetectionPollingForUnits = addRadarDetectionPollingForUnits,
            addPollingForUnits = addPollingForUnits,
            thePollFunction = thePollFunction,

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
