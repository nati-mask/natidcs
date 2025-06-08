-- Dead Log (Mist)
if not Natils then error('utilites for WW2 winning landing script was not loaded') end
if not mist then error('in order to run WW2 winning landing script you need to load mist') end

local unitTable = mist.makeUnitTable({
    '[g]Eagle-1',
    '[g]Eagle-2',
})

local bombersDead = {}

local bomberDeadTexts = {
    'That\'s not good, we just lost %s.\nWe still have %d bombers, hope they will do the work.',
    'What\'s going on? %s got destroyed!\nDefend our assets! %d bombers left!',
    'Where the hell are our fighters?!! %s destroyed now!\nWe got %d bombers left.',
    'GHQ is not kidding anymore. What is happenning? We lost %s in action.\n%d bombers left.',
    'Come on, this is not good, %s is crashing.\n%d bombers left.',
    'We lost %s.\nOnly %d bombers left.',
    '%s is dead.\nOnly %d bombers left.',
}

local bombersDeadCount = 0

local function onBombersDead(event)
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
        local deadBomberName = event.initiator:getName()

        -- trigger.action.outTextForCoalition(
        --     coalition.side.BLUE,
        --     (
        --         'Some unit is '..
        --         ((event.id == world.event.S_EVENT_UNIT_LOST) and 'lost ' or 'crashed ')
        --         ..deadBomberName..
        --         ' event id: '..event.id
        --     ),
        --     45
        -- )

        if not Natils.tableIncludesVal(unitTable, deadBomberName) then return end

        if (Natils.tableIncludesVal(bombersDead, deadBomberName)) then return end -- prevent double handling
        table.insert(bombersDead, deadBomberName)

        bombersDeadCount = bombersDeadCount + 1

        -- trigger.action.outTextForCoalition(coalition.side.BLUE, 'The unit is in the list:'..deadBomberName, 45)

        local stillAlive = 0;

        for _, bomberName in pairs(unitTable) do
            local bomber = Unit.getByName(bomberName)
            if bomber and bomber:isActive() and bomber:isExist() and (not Natils.tableIncludesVal(bombersDead, bomberName)) then
                stillAlive = stillAlive + 1
            end
        end

        local textToFormat = bomberDeadTexts[bombersDeadCount] or 'We lost %s.\nWe better RTB and inquire.'

        trigger.action.outTextForCoalition(coalition.side.BLUE, string.format(textToFormat, deadBomberName, stillAlive), 45)

    end
end

mist.addEventHandler(onBombersDead)
-- / Show unit dead