--[[
## Nati's additions to DCS
]]
natidcs = natidcs or {}

do

    natidcs.ww2LandWinPicture = {
        debug = true,
        flag = nil,
        winPictureSet = nil,
        onLandListener = nil,
        airbase = nil,
        showLander = nil,
    }

    local textToBlue = function (text, seconds)
        trigger.action.outTextForCoalition(coalition.side.BLUE, text, seconds)
    end

    local getUnitUniqueId = function(unit)
        if (not unit) or not (unit.id_) then error('Cannot uniquelt identify unit') end
        return tostring(unit.id_)
    end

    local addUnitsToDictSet = function(dictSet, units)
        for i = 1, #units do
            local name = units[i]:getPlayerName() or units[i]:getName()
            dictSet:add(getUnitUniqueId(units[i]), name)
        end
    end

    local displayWinningSet = function ()
        if (not natidcs.ww2LandWinPicture.winPictureSet or natidcs.ww2LandWinPicture.winPictureSet:length() == 0) then
            textToBlue('WW2 Winning set is empty', 20)
        else
            textToBlue('WW2 Winning set is:\n'..natidcs.ww2LandWinPicture.winPictureSet:concat(), 45)
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
            local airBaseName = event.place and event.place:getName();

            if not natidcs.ww2LandWinPicture.debug and not playerName then return end
            if natidcs.ww2LandWinPicture.airbase and (not natidcs.ww2LandWinPicture.airbase == airBaseName) then return end

            if natidcs.ww2LandWinPicture.winPictureSet:has(getUnitUniqueId(landingUnit)) then
                if natidcs.ww2LandWinPicture.debug or natidcs.ww2LandWinPicture.showLander then
                    textToBlue((playerName and 'Player ' or 'Unit ')..(playerName or unitName)..' landed successfully at '..airBaseName..' and we are winning the day!', 60)
                end

                -- THE WIN:
                trigger.action.setUserFlag(natidcs.ww2LandWinPicture.flag, true)
                mist.removeEventHandler(natidcs.ww2LandWinPicture.onLandListener)
            end
        end
    end

    local addOnLandEventListener = function ()

        if (natidcs.ww2LandWinPicture.onLandListener) then return end

        natidcs.ww2LandWinPicture.onLandListener = mist.addEventHandler(onLand)

    end

    local takeWinPicture = function (flag, options)
        if not Natils then error('utilites for WW2 winning landing script was not loaded') end
        if (not flag) or (type(flag) ~= 'number') then error('missing flag argument or it\'s not a number') end

        local zoneName = 'WW2_WIN_LAND_PICTURE'

        if (options and type(options) == 'table') then
            if (not options.debug) then natidcs.ww2LandWinPicture.debug = false end
            if (options.zoneName and type(options.zoneName) == 'string') then zoneName = options.zoneName end
            if (options.airbase and type(options.airbase) == 'string') then natidcs.ww2LandWinPicture.airbase = options.airbase end
            if (options.showLander and type(options.showLander) == 'boolean') then natidcs.ww2LandWinPicture.showLander = options.showLander end
        end

        local zone = trigger.misc.getZone(zoneName)
        if not zone then textToBlue('Zone '..zoneName..'doen\'t exist for the winning trigger') return end

        natidcs.ww2LandWinPicture.winPictureSet = Natils.createDictSet('WIN Picture Units');

        local units = mist.getUnitsInZones(mist.makeUnitTable({'[blue][plane]'}), {zoneName})

        addUnitsToDictSet(natidcs.ww2LandWinPicture.winPictureSet, units)

        natidcs.ww2LandWinPicture.flag = flag

        if natidcs.ww2LandWinPicture.debug then
            displayWinningSet()
            textToBlue('Winning configurations:\n'..mist.utils.tableShow(natidcs.ww2LandWinPicture), 45)
        end

        addOnLandEventListener()

    end

    -- Exports:
    natidcs.ww2LandWinPicture.takeWinPicture = takeWinPicture
    natidcs.ww2LandWinPicture.displayWinningSet = displayWinningSet

end