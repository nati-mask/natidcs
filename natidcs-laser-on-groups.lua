--[[
## Nati's additions to DCS
]]

natidcs = natidcs or {}

if natidcs.startLaserOnGroup then error('Someone is trying to load NatiDCS laser on groups twice') end

natidcs.radarDetection = {}

do

    local function onDeadUnit()
    end


    local function deadUnitsListener(event)
        if
            (
                event.id == world.event.S_EVENT_UNIT_LOST
                or
                event.id == world.event.S_EVENT_CRASH
            )
            and
            (
                event.initiator
                and
                event.initiator:getCategory() == Object.Category.UNIT
            )
        then
        end
    end

    local function start(self)
    end

    local function laserOnGroupConstructor(lasingGroupName, lasedGroupName, options)
        local laser
        local lasingUnits = NatiMist.getUnitsInGroups({ lasingGroupName });
        local lasedUnits = NatiMist.getUnitsInGroups({ lasedGroupName });
        return {
            start
        }
    end

    natidcs.startLaserOnGroup = function(...)

        if not mist then error('MIST is not loaded') end
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
            trigger.action.outText('Error in Laser on groups Script:\n'..laserOnGroup, 120)
        else
            return laserOnGroup -- the instance
        end
    end
end