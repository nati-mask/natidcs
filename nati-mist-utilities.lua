--[[
## Nati's additions to DCS
]]
NatiMist = NatiMist or {}

do
    if not mist then error('in order to run Nati extensions to MIST scripts you need to load MIST') end

    -- Based on MIST getUnitsInZones
    -- but supports real time zones (including moving) not from MIST DBs
    local getUnitsInZones = function(unit_names, zone_names, zone_type)
        zone_type = zone_type or 'cylinder'
        if zone_type == 'c' or zone_type == 'cylindrical' or zone_type == 'C' then
            zone_type = 'cylinder'
        end
        if zone_type == 's' or zone_type == 'spherical' or zone_type == 'S' then
            zone_type = 'sphere'
        end

        assert(zone_type == 'cylinder' or zone_type == 'sphere', 'invalid zone_type: ' .. tostring(zone_type))

        local units = {}
        local zones = {}
        
        if zone_names and type(zone_names) == 'string' then
            zone_names = {zone_names}
        end
        for k = 1, #unit_names do
            
            local unit = Unit.getByName(unit_names[k]) or StaticObject.getByName(unit_names[k])
            if unit and unit:isExist() == true then
                units[#units + 1] = unit
            end
        end


        for k = 1, #zone_names do
            local zone = trigger.misc.getZone(zone_names[k])
            if zone then
                zones[#zones + 1] = {radius = zone.radius, x = zone.point.x, y = zone.point.y, z = zone.point.z, verts = zone.verticies}
            end
        end

        local in_zone_units = {}
        for units_ind = 1, #units do
            local lUnit = units[units_ind]
            local unit_pos = lUnit:getPosition().p
            local lCat = Object.getCategory(lUnit)
            for zones_ind = 1, #zones do
                if zone_type == 'sphere' then	--add land height value for sphere zone type
                    local alt = land.getHeight({x = zones[zones_ind].x, y = zones[zones_ind].z})
                    if alt then
                        zones[zones_ind].y = alt
                    end
                end

                if unit_pos and ((lCat == 1 and lUnit:isActive() == true) or lCat ~= 1) then -- it is a unit and is active or it is not a unit
                    if zones[zones_ind].verts  then
                        if mist.pointInPolygon(unit_pos, zones[zones_ind].verts) then
                            in_zone_units[#in_zone_units + 1] = lUnit
                        end

                    else
                        if zone_type == 'cylinder' and (((unit_pos.x - zones[zones_ind].x)^2 + (unit_pos.z - zones[zones_ind].z)^2)^0.5 <= zones[zones_ind].radius) then
                            in_zone_units[#in_zone_units + 1] = lUnit
                            break
                        elseif zone_type == 'sphere' and (((unit_pos.x - zones[zones_ind].x)^2 + (unit_pos.y - zones[zones_ind].y)^2 + (unit_pos.z - zones[zones_ind].z)^2)^0.5 <= zones[zones_ind].radius) then
                            in_zone_units[#in_zone_units + 1] = lUnit
                            break
                        end
                    end
                end
            end
        end
        return in_zone_units
    end

    local function degAngleBetweenPoints(pointNearAngle, pointInFrontOfAngle)
        local dist = mist.utils.get3DDist(pointInFrontOfAngle, pointNearAngle)
        local heightsDelta = pointInFrontOfAngle.y - pointNearAngle.y
        if math.abs(heightsDelta) > dist then error('error in calc angle between points') end
        local angRad = math.asin(heightsDelta / dist)
        return mist.utils.toDegree(angRad)
    end


    NatiMist.getUnitsInZones = getUnitsInZones
    NatiMist.degAngleBetweenPoints = degAngleBetweenPoints

end
