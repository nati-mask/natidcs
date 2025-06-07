--[[
## Nati's additions to DCS
]]
Natils = Natils or {}

do

    local includesVal = function (t, val)
        for _, tVal in pairs(t) do
            if val == tVal then return true end
        end
        return false
    end

    local includesKey = function (t, key)
        for k in pairs(t) do
            if (k == key) then return true end
        end
        return false
    end

    local countKeysInTable = function (t)
        local keysnum = 0;
        for k in pairs(t) do keysnum = keysnum + 1 end
        return keysnum
    end

    local createDictSet = function (setName)
        return {
            name = setName or 'unknown',
            dict = {},
            add = function(self, key, val)
                if not key then return end
                if (type(key) ~= 'string') then error('Set key can only be a string') end
                if includesKey(self.dict, key) then return end
                self.dict[key] = val or 'unknown'
            end,
            has = function(self, key)
                if not key then return false end
                if (type(key) ~= 'string') then error('You can only check for string key in the set') end
                return includesKey(self.dict, key)
            end,
            get = function(self, key)
                return self.dict[key]
            end,
            length = function(self)
                return countKeysInTable(self.dict)
            end,
            concat = function(self, sep)
                local text = ''
                local aSep = sep or '\n'
                local aSepLen = string.len(aSep)
                for k,val in pairs(self.dict) do
                    text = text..k..': '..val..aSep
                end
                return string.sub(text, 1, -1 - aSepLen)
            end
        }
    end

    Natils.createDictSet = createDictSet

    Natils.tableIncludesVal = function(t, val)
        if (type(t) ~= 'table') then error('tableIncludesVal can run only on tables but received a '..type(t)) end
        return includesVal(t, val)
    end


end

-- local set1 = Natils.createDictSet('Testy')

-- print('is this including: '..tostring(Natils.tableIncludesVal({ 'aab', 'foo', '12' }, 12)))

-- print(table.concat({ 'foo', 'bar' }, ', '))

-- print(set1:has('a'));
-- set1:add('a', 'moshiko')
-- set1:add('b', 'tamam')
-- set1:add('b', 'keif')
-- print(set1:has('a'));

-- print(set1:get('b'));
-- print(set1:get('c'));
-- print('\n'..set1.name..' set now is:\n'..set1:concat())
