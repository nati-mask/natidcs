--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

if natidcs.ww2LandWinPicture then return end

do

    if not Natils then error('utilites for WW2 winning landing script was not loaded') end
    if not mist then error('in order to run WW2 winning landing script you need to load MIST') end
    if not NatiMist then error('utilites for WW2 winning landing script based on MIST was not loaded') end

    natidcs.ww2LandWinPicture = {
        debug = true,
        flag = nil,
        winPictureSet = Natils.createDictSet('WIN Picture Units'),
        onLandListener = nil,
        airbases = nil,
        showLander = nil,
    }

    local textToBlue = function (text, seconds)
        trigger.action.outTextForCoalition(coalition.side.BLUE, text, seconds)
    end

    local getUnitUniqueId = function(unit)
        if (not unit) or not (unit.id_) then error('Cannot uniquely identify unit') end
        return tostring(unit.id_)
    end

    local addUnitsToDictSet = function(dictSet, units)
        for i = 1, #units do
            local name = units[i]:getPlayerName() or units[i]:getName()
            dictSet:add(getUnitUniqueId(units[i]), name)
        end
    end

    local displayWinningSet = function ()
        if (not natidcs.ww2LandWinPicture.winPictureSet or (natidcs.ww2LandWinPicture.winPictureSet:length() == 0)) then
            textToBlue('WW2 Winning set is empty', 20)
        else
            textToBlue('WW2 Winning set is:\n'..natidcs.ww2LandWinPicture.winPictureSet:concat(), 45)
        end
    end

    local validateZones = function (zones)
        if type(zones) ~= 'table' then error('zones table has to be a table') end
        for i = 1, #zones do
            local zone = trigger.misc.getZone(zones[i])
            if not zone then error('Zone "'..zones[i]..'" doesn\'t exist for the winning trigger') end
        end
    end

    local validateAirbases = function (airbases)
        if not airbases then return end
        if type(airbases) ~= 'table' then error('airbases table has to be a table (list)') end
        for i = 1, #airbases do
            local airBase = Airbase.getByName(airbases[i])
            if not airBase then error('Airbase "'..airbases[i]..'" doesn\'t exist for the winning trigger') end
        end
    end

    local onLand = function (event)
        if
            event.id == world.event.S_EVENT_LAND
            and
            event.initiator
            and
            event.initiator:getCategory() == Object.Category.UNIT
        then
            local landingUnit = event.initiator
            local playerName = landingUnit:getPlayerName()
            local unitName = landingUnit:getName()
            local airBaseName = event.place and event.place:getName()

            local airBasesValid, validationAirbasesErrMsg = pcall(validateAirbases, natidcs.ww2LandWinPicture.airbases)
            if not airBasesValid then
                textToBlue(validationAirbasesErrMsg, 60)
                return
            end
            local airBasesToLand = natidcs.ww2LandWinPicture.airbases

            if not natidcs.ww2LandWinPicture.debug and not playerName then return end

            if natidcs.ww2LandWinPicture.winPictureSet:has(getUnitUniqueId(landingUnit)) then

                if airBasesToLand and (not Natils.tableIncludesVal(airBasesToLand, airBaseName)) then
                    if natidcs.ww2LandWinPicture.debug then
                        textToBlue((playerName and 'Player ' or 'Unit ')..(playerName or unitName)..' landed alive at '..airBaseName..' but this is not the correct airport.\nNeed to land at '..table.concat(airBasesToLand, ' or '), 60)
                    end
                    return
                end

                if natidcs.ww2LandWinPicture.debug or natidcs.ww2LandWinPicture.showLander then
                    textToBlue((playerName and 'Player ' or 'Unit ')..(playerName or unitName)..' landed alive at '..airBaseName..' and we are winning the day!', 60)
                end

                -- THE WIN:
                trigger.action.setUserFlag(natidcs.ww2LandWinPicture.flag, true)
                mist.removeEventHandler(natidcs.ww2LandWinPicture.onLandListener)
                natidcs.ww2LandWinPicture.onLandListener = nil

            end
        end
    end

    local addOnLandEventListener = function ()

        if (natidcs.ww2LandWinPicture.onLandListener) then
            if natidcs.ww2LandWinPicture.debug then textToBlue('Called setWin() but landing trigger already exists', 60) end
            return
        end

        if natidcs.ww2LandWinPicture.debug then
            displayWinningSet()
        end

        natidcs.ww2LandWinPicture.onLandListener = mist.addEventHandler(onLand)

    end

    local updateWinPicture = function (flag, options)

        if (not flag) or (type(flag) ~= 'number') then error('missing flag argument or it\'s not a number') end

        local zones = { 'WW2_WIN_LAND_PICTURE' }

        if (options and type(options) == 'table') then
            if (not options.debug) then natidcs.ww2LandWinPicture.debug = false end
            if (options.zones and type(options.zones) == 'table') then zones = options.zones end

            if (options.airbase and type(options.airbase) == 'string') then natidcs.ww2LandWinPicture.airbases = { options.airbase } end
            if (options.airbase and type(options.airbase) == 'table') then natidcs.ww2LandWinPicture.airbases = options.airbase end
            if (options.airbases and type(options.airbases) == 'table') then natidcs.ww2LandWinPicture.airbases = options.airbases end
            if (options.showLander and type(options.showLander) == 'boolean') then natidcs.ww2LandWinPicture.showLander = options.showLander end
        end

        local zonesValid, validationZonesErrMsg = pcall(validateZones, zones)
        if not zonesValid then
            textToBlue(validationZonesErrMsg, 60)
            return
        end

        local units = NatiMist.getUnitsInZones(mist.makeUnitTable({'[blue][plane]'}), zones)

        addUnitsToDictSet(natidcs.ww2LandWinPicture.winPictureSet, units)

        natidcs.ww2LandWinPicture.flag = flag

        if natidcs.ww2LandWinPicture.debug then
            displayWinningSet()
            textToBlue('Winning configurations:\n'..mist.utils.tableShow(natidcs.ww2LandWinPicture), 45)
        end

    end

    -- Exports:
    natidcs.ww2LandWinPicture.updateWinPicture = updateWinPicture
    natidcs.ww2LandWinPicture.setWin = addOnLandEventListener
    natidcs.ww2LandWinPicture.displayWinningSet = displayWinningSet

end
