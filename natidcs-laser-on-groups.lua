--[[
## Nati's additions to DCS
]]

natidcs = natidcs or {}

if natidcs.startLaserOnGroup then error('Someone is trying to load NatiDCS laser on groups twice') end

natidcs.radarDetection = {}

do

    local function isUnitAlive(unit)
        return unit and unit:isExist() and unit:isActive()
    end

    local function getLivingUnits(groupNames)
        local allUnits = NatiMist.getUnitsInGroups(groupNames)
        local livingUnits = {}
        for _, unit in ipairs(allUnits) do
            if isUnitAlive(unit) then
                table.insert(livingUnits, unit)
            end
        end
        return livingUnits
    end

    local function isUnitInTable(unitTable, unit)
        if not unit then return false end
        local unitId = Natils.getUnitUniqueId(unit)
        for _, tableUnit in ipairs(unitTable) do
            if Natils.getUnitUniqueId(tableUnit) == unitId then
                return true
            end
        end
        return false
    end

    local function getFirstInTable(t)
        if type(t) ~= 'table' or #t == 0 then
            return nil
        end
        return t[1]
    end

    local function onDeadUnit(self, unit)
        local deadUnitIsRelevant = false

        if isUnitInTable(self:getLasingUnits(), unit) then
            self:resetLasingUnits()
            trigger.action.outText('Lasing unit "'..unit:getName()..'" was destroyed', 20)
            deadUnitIsRelevant = true
        end

        if isUnitInTable(self:getLasedUnits(), unit) then
            self:resetLasedUnits()
            trigger.action.outText('Unit with laser on"'..unit:getName()..'" was destroyed', 20)
            deadUnitIsRelevant = true
        end

        if deadUnitIsRelevant then
            self:manageLaserDesignation()
        end
    end

    local function deadUnitsListener(self, event)
        if (self.finishing) then return end
        if
            (
                event.id == world.event.S_EVENT_DEAD
                or
                event.id == world.event.S_EVENT_UNIT_LOST
                or
                event.id == world.event.S_EVENT_CRASH
            )
            and
            (
                event.initiator
                and
                event.initiator.getCategory
                and
                event.initiator:getCategory() == Object.Category.UNIT
            )
        then
            self:onDeadUnit(event.initiator)
        end
    end

    local function manageLaserDesignation(self)
        local lasingUnit = getFirstInTable(self:getLasingUnits())
        local lasedUnit = getFirstInTable(self:getLasedUnits())

        if not lasingUnit then
            trigger.action.outText('JTAC Group "'..self:getLasingGroupName()..' was destroyed.', 20)
            return self:finish()
        end

        if not lasedUnit then
            trigger.action.outText('Target group was destroyed!', 20)
            return self:finish()
        end

        local laserData = self:getLaserData()

        if
            (
                not laserData.lasingUnitId
                or not laserData.lasedUnitId
                or (laserData.lasedUnitId ~= Natils.getUnitUniqueId(lasedUnit))
                or (laserData.lasingUnitId ~= Natils.getUnitUniqueId(lasingUnit))
            )
        then
            if laserData.laser then
                laserData.laser:destroy()
            end
            local laserCode = self:getLaserCode()

            -- Yes the source is a Unit, the target is a Point.
            local laserSpot = Spot.createLaser(lasingUnit, {x = 0, y = 1, z = 0}, lasedUnit:getPoint(), laserCode)

            trigger.action.outText(
                'JTAC "'..lasingUnit:getName()
                ..'" is lasing on "'..lasedUnit:getName()
                ..'" with laser code: '..tostring(laserCode)
                ..' with adjustments.'
            , 30)
            self:setLaserData(lasingUnit, lasedUnit, laserSpot)
        end

    end

    local function finish(self)
        self.finishing = true

        -- Destroy laser if it exists
        local laserData = self:getLaserData()
        if laserData.laser then
            laserData.laser:destroy()
        end

        if self.eventHandlerId then
            mist.removeEventHandler(self.eventHandlerId)
            self.eventHandlerId = nil
        end
    end

    local function start(self)
        self:manageLaserDesignation()

        self.eventHandlerId = mist.addEventHandler(function (event)
            local success, result = pcall(function()
                return self:deadUnitsListener(event)
            end)

            if not success then
                trigger.action.outText('Error in unit dead event handler:\n'..tostring(result), 120)
            end
        end)
    end

    local function laserOnGroupConstructor(lasingGroupName, lasedGroupName, laserCode, options)
        local laserData = { lasingUnitId = nil, lasedUnitId = nil, laser = nil }

        if type(laserCode) ~= 'number' or laserCode < 0 then
            error('laserCode must be a non-negative number, got: ' .. tostring(laserCode))
        end

        local lasedUnits = getLivingUnits({ lasedGroupName });
        if not lasedUnits or #lasedUnits == 0 then
            error('No living units found in target group: ' .. lasedGroupName)
        end

        local lasingUnits = getLivingUnits({ lasingGroupName });
        if not lasingUnits or #lasingUnits == 0 then
            error('No living units found in JTAC group: ' .. lasingGroupName)
        end

        return {
            lasingUnits = lasingUnits,
            lasedUnits = lasedUnits,
            setLaserData = function(self, lasingUnit, lasedUnit, newSpotLaser)
                laserData.lasingUnitId = Natils.getUnitUniqueId(lasingUnit)
                laserData.lasedUnitId = Natils.getUnitUniqueId(lasedUnit)
                laserData.laser = newSpotLaser
            end,
            getLaserData = function() return laserData end,
            getLaserCode = function() return laserCode end,
            eventHandlerId = nil,
            finishing = false,
            getLasingGroupName = function() return lasingGroupName end,
            getLasingUnits = function() return lasingUnits end,
            getLasedUnits = function() return lasedUnits end,
            resetLasingUnits = function() lasingUnits = getLivingUnits({ lasingGroupName }) end,
            resetLasedUnits = function() lasedUnits = getLivingUnits({ lasedGroupName }) end,
            onDeadUnit = onDeadUnit,
            deadUnitsListener = deadUnitsListener,
            manageLaserDesignation = manageLaserDesignation,
            start = start,
            finish = finish
        }
    end

    natidcs.startLaserOnGroup = function(...)

        if not mist then error('MIST is not loaded') end
        if not Natils then error('general utilities are not loaded') end
        if not NatiMist then error('utilities built on MIST are not loaded') end

        local arguments = {...}

        local success, laserOnGroup = pcall(function()
            ---@diagnostic disable-next-line: deprecated
            local laserOnGroupInstance = laserOnGroupConstructor(unpack(arguments))
            laserOnGroupInstance:start()
            return laserOnGroupInstance
        end)

        if not success then
            -- Here "laserOnGroup" is the error
            trigger.action.outText('Error in Laser on groups Script:\n'..tostring(laserOnGroup), 120)
        else
            return laserOnGroup -- the instance
        end
    end
end