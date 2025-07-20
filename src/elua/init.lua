local elua = {}

local Elua = {}
Elua.__index = Elua
local Enum = {
    is_enum = true
}
Enum.__index = Enum
local Struct = {
    is_struct = true
}
Struct.__index = Struct

function elua.new_elua()
    local ret = {
        _e = {},
        _s = {}
    }
    setmetatable(ret, Elua)
    return ret
end

local function _wrap_enum(e)
    local ret = {}
    setmetatable(ret, Enum)
    ret._t = e
    ret._i = {}
    local idx = 0
    for k, v in pairs(e) do
        ret._i[idx] = k
        idx = idx + 1
    end
    ret._c = idx
    return ret
end

local function _gen_getter_named(ctx, n)
    local ret
    return function()
        if not ret then
            ret = ctx:get_enum(n)
            if not ret then
                ret = ctx._s[n]
            end
        end
        return ret
    end
end

local function _gen_enum_getter_range(r)
    local f = r[1]
    local t = r[2]
    local e = {}
    for i = f, t do
        e[i - f] = i
    end
    local ret = _wrap_enum(e)
    return function()
        return ret
    end
end

local function _wrap_struct(ctx, s)
    local ret = {}
    setmetatable(ret, Struct)
    ret._i = {}
    ret._t = {}
    local idx = 0
    for k, v in pairs(s) do
        ret._i[idx] = k
        idx = idx + 1
        local g
        if type(v) == "string" then
            g = _gen_getter_named(ctx, v)
        elseif type(v) == "table" then
            g = _gen_enum_getter_range(v)
        end
        ret._t[k] = g
    end
    ret._c = idx
    return ret
end

-- Enums
function Enum:count()
    return self._c
end
function Enum:i2k(i)
    return self._i[i]
end
function Enum:get(k)
    return self._t[k]
end

-- Structs
function Struct:count()
    return self._c
end
function Struct:i2k(i)
    return self._i[i]
end
function Struct:get(k)
    return self._t[k]
end

-- Elua
function Elua:load_enum(n, e)
    self._e[n] = _wrap_enum(e)
    return self
end
function Elua:get_enum(n)
    return self._e[n]
end

function Elua:load_struct(n, s)
    self._s[n] = _wrap_struct(self, s)
    return self
end

function Elua:dump(p)
    p("******** ENUMS ********")
    for k, v in pairs(self._e) do
        local c = v:count()
        p(string.format("=== %s(%s) - %s ===", k, tostring(v), c))
        for i = 0, c - 1 do
            local k = v:i2k(i)
            p(string.format("[%s] %s", i, k))
            local ct = v:get(k)
            for k0, v0 in pairs(ct) do
                p(string.format(" - %s = %s", k0, v0))
            end
        end
    end
    p("******** STRUCTS ********")
    for k, v in pairs(self._s) do
        local c = v:count()
        p(string.format("+++ %s(%s) - %s +++", k, tostring(v), c))
        for i = 0, c - 1 do
            local k = v:i2k(i)
            local gf = v:get(k)
            local g = gf()
            p(string.format("[%s] %s(%s%s): %s", i, k, g.is_enum and "E" or "", g.is_struct and "S" or "", tostring(g)))
        end
    end
end

return elua
