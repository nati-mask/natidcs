--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

do
    local function onSwitchPositionUpTo(unit, switchId, switchPosition)
        local switchValue = unit:getDrawArgumentValue(switchId)
        trigger.action.outText('Switch '..switchId..' on "'..unit:getName()..'" value is '..switchValue, 5)
        -- if val == switchPosition then
        -- end
    end

    local function showUnitSwitchValue(unitName, switchId, switchPosition)
        local unit = Unit.getByName(unitName)
        onSwitchPositionUpTo(unit, switchId, switchPosition)
    end

    natidcs.showUnitSwitchValue = showUnitSwitchValue

end
