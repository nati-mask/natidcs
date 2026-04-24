--[[
## Nati's additions to DCS
]]

natidcs = natidcs or {}

if natidcs.startClass then error('Someone is trying to load NatiDCS laser on groups twice') end

natidcs.radarDetection = {}

do

    local function start(self)
    end

    local function makeClass(arg1)
        return {
            start
        }
    end

    natidcs.startClass = function(...)
        local arguments = {...}

        local success, class = pcall(function()
            ---@diagnostic disable-next-line: deprecated
            local radarDetectionPoller = makeClass(unpack(arguments))
            radarDetectionPoller:start()
            return radarDetectionPoller
        end)

        if not success then
            trigger.action.outText('Error in Radar Detection Script:\n'..class, 120)
        else
            return class -- Optional, in order to call setters and actions
        end
    end
end