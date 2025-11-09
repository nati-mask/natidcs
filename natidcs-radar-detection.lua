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
    local function seqContainsValue(tbl, value, map)
        for i = 1, #tbl do
            if map and type(map) == 'function' then
                if map(tbl[i]) == value then return true end
            else
                if tbl[i] == value then return true end
            end
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

    local function getAllUnitsRadarIsDetecting(self, detectingUnit)

        if (
            not detectingUnit or
            not detectingUnit:isActive() or
            not detectingUnit:isExist()
        ) then
            return {}, true
        end

        local controller = detectingUnit:getController()
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
                    if (self.minAngle ~= nil) then
                        if (getRadarAngleToUnit(detectingUnit, detectedUnit) >= self.minAngle) then
                            table.insert(detectedUnits, detectedUnit)
                        end
                    else
                        table.insert(detectedUnits, detectedUnit)
                    end
                end
            end
        end

        return detectedUnits, false
    end

    local function debugRadarAngles(self, detectingUnit, units)
        if (not detectingUnit) then return end
        local angTexts = {}
        for i = 1, #units do
            local unit = units[i]
            local ang = getRadarAngleToUnit(detectingUnit, unit)
            if (ang) then
                table.insert(angTexts, 'Ang from radar: '..detectingUnit:getName()..' to '..unit:getName()..' is:\n'..ang)
            end
        end
        trigger.action.outText(table.concat(angTexts, '\n'), self.interval - 0.25);
    end

    local function thePollFunction(self, cbForSingleDetectingUnit)

        for _, radarDetection in pairs(self.detectionTable) do
            if radarDetection:length() > 0 then
                trigger.action.outText('Radar Detection for: '..radarDetection.name..'\n'..radarDetection:concat(), self.interval - 0.25);
            end
        end

        for i = 1, #self.detectingUnits do
            local continue = cbForSingleDetectingUnit(self.detectingUnits[i])
            if continue == false then return false end
        end
    end

    local function addPollingForDetectingUnits(self, cbForSingleDetectingUnit)

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

    local function addRadarPolling(self, cbForSingleDetectedUnit)

        local deadUnits = {}

        self:addPollingForDetectingUnits(function (detectingUnit)

            if not detectingUnit then error('poll called on detecting unit that was never exists') end

            if (tableLength(deadUnits) >= #self.detectingUnits) then
                return false -- stop the polling
            end

            -- trigger.action.outText(
            --     'Checking what '..detectingUnit:getTypeName()
            --     ..' "'..detectingUnit:getName()..'"'..
            --     ' is detecting, radar enum: '..Controller.Detection.RADAR, 10
            -- )

            local unitsDetected, radarIsDead = self:getAllUnitsRadarIsDetecting(detectingUnit)

            if radarIsDead then
                deadUnits[detectingUnit:getName()] = true -- "Set" like
            end

            local possibleDetectedUnits = self:getPossibleDetectedUnits()

            if (self.debug) then self:debugRadarAngles(detectingUnit, possibleDetectedUnits) end

            for i = 1, #possibleDetectedUnits do
                local unit = possibleDetectedUnits[i]
                if (
                    unit and
                    not seqContainsValue(
                        unitsDetected,
                        unit:getName(),
                        function (detectedUnit) return detectedUnit:getName() end
                    )
                ) then
                    self.detectionTable[detectingUnit:getName()]:remove(unit:getName())
                end
            end

            for i = 1, #unitsDetected do
                local detectedUnit = unitsDetected[i]
                local continue = cbForSingleDetectedUnit(detectedUnit, detectingUnit)
                if continue == false then return false end
            end

        end, self.interval)

    end

    local function start(self)

        local firstUnitDetected = false;

        self.logger:info('Starting Detection polling in '..self.interval..'s for '..#self.detectingUnits..' detecting radar units')

        self:addRadarPolling(function (detectedUnit, detectingUnit)

            -- A unit is detected!

            self.detectionTable[detectingUnit:getName()]:add(
                detectedUnit:getName(),
                '°'..string.sub(tostring(getRadarAngleToUnit(detectingUnit, detectedUnit)), 1, 8)..
                ((detectedUnit:getPlayerName() and ' ('..detectedUnit:getPlayerName()..')') or ''),
                true
            )

            if (not self.countinous) then
                self.logger:info(
                    'Unit Radar detected! '..
                    detectedUnit:getTypeName()..' "'..detectedUnit:getName()..'"'..
                    ((detectedUnit:getPlayerName() and ' ('..detectedUnit:getPlayerName()..')') or '')..
                    (detectingUnit and (' by '..detectingUnit:getName()) or '')..
                    (self.flagNum and (' setting flag: '..self.flagNum..' to true.') or '')
                )
            end

            if (not firstUnitDetected and self.flagNum) then trigger.action.setUserFlag(self.flagNum, true) end
            if (not firstUnitDetected and self.onBlame) then self.onBlame(detectedUnit, detectingUnit) end
            if (not self.countinous) then return false end -- false is for: stop the polling!

            firstUnitDetected = true

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
                detectionTable[detectingUnitsName] = Natils.createDictSet(detectingUnitsName)
            end
        end

        if #detectingUnits == 0 then
            error('No existing detecting units (radars) provided', 30)
        end

        local interval = (options and type(options) == "table" and type(options.interval) == "number") and options.interval or nil
        if (not interval) then interval = #detectingUnits * 2 end
        if (interval < 2) then interval = 2 end

        local minAngle = nil
        if (
            options and type(options) == 'table' and
            type(options.minAngle) == 'number' and
            options.minAngle >= -90 and
            options.minAngle <= 90
        ) then
            minAngle = options.minAngle
        end

        return {
            logger = mist.Logger:new("Radar Detection Sctipt (Nati)", "info"),

            -- props:
            debug = (options and type(options) == 'table' and type(options.debug) == 'boolean') and options.debug or false,
            countinous = (options and type(options) == 'table' and type(options.countinous) == 'boolean') and options.countinous or false,
            flagNum = (options and type(options) == 'table' and type(options.flagNum) == 'number') and options.flagNum or nil,
            onBlame = (options and type(options) == 'table' and type(options.onBlame) == 'function') and options.onBlame or nil,
            interval = interval,
            minAngle = minAngle,
            detectingUnits = detectingUnits,
            detectedGroupsNames = detectedGroupsNames,
            detectionTable = detectionTable,

            -- Methods:
            debugRadarAngles = debugRadarAngles,
            getAllUnitsRadarIsDetecting = getAllUnitsRadarIsDetecting,
            getPossibleDetectedUnits = getPossibleDetectedUnits,
            addRadarPolling = addRadarPolling,
            addPollingForDetectingUnits = addPollingForDetectingUnits,
            thePollFunction = thePollFunction,

            start = start
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
