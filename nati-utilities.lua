local natils = {}

natils.createSet = function (setName)
    print('This will be set!')
    return {
        name = setName or 'unknown',
        things = {},
        addOne = function(self, thing)
            if not (self and thing) then error("Don't call 'addOne' statically") end
            print('Adding to ' .. self.name .. '...')
            self.things[#self.things + 1] = thing
            print('On '.. self.name ..' Now we are: '..table.concat(self.things, ', '))
        end
    }
end

local set1 = natils.createSet('Set 1')
local set2 = natils.createSet('Set 2')

set1:addOne('PurrPurr')
set1:addOne('Plaffie')

set2:addOne('Just')
