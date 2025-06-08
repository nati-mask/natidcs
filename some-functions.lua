-- Plane Unique ID:
local plane = Unit.getByName('Test-1-1')
trigger.action.outTextForCoalition(coalition.side.BLUE, 'Plane Unique ID:' .. plane.id_, 60)

-- Set Airbase coalition:
local maupertusAirbase = Airbase.getByName('Maupertus')
maupertusAirbase:autoCapture(false)
local maupertusAirbase = Airbase.getByName('Maupertus')
maupertusAirbase:setCoalition(coalition.side.BLUE)
