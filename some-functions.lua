-- Plane Unique ID:
local plane = Unit.getByName('Test-1-1')
trigger.action.outTextForCoalition(coalition.side.BLUE, 'Plane Unique ID:' .. plane.id_, 60)
