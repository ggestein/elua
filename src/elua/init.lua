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
local Instance = {}
Instance.__index = Instance

local function _dump_table(p, t, indent)
    indent = indent or 0
    local pf = ""
    for i = 0, indent do
        pf = pf.."   "
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            p(string.format("%s%s: {", pf, k))
            _dump_table(p, v, indent + 1)
            p(string.format("%s}", pf))
        else
            p(string.format("%s%s: %s", pf, k, v))
        end
    end
end

local function _match_table(t0, t1)
    for k, v in pairs(t0) do
        local v1 = t1[k]
        if type(v) ~= type(v1) then
            return false
        end
        local t = type(v)
        if t == "table" then
            if not _match_table(v, v1) then
                return false
            end
        elseif v ~= v1 then
            return false
        end
    end
    return true
end

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
    ret._i = {}
    local idx = 0
    for k, v in pairs(e) do
        ret._i[k] = idx
        ret[idx] = {
            _k = k,
            _v = v
        }
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
    local idx = 0
    for k, v in pairs(s) do
        ret._i[k] = idx
        local g
        if type(v) == "string" then
            g = _gen_getter_named(ctx, v)
        elseif type(v) == "table" then
            g = _gen_enum_getter_range(v)
        end
        ret[idx] = {
            _k = k,
            _v = g
        }
        idx = idx + 1
    end
    ret._c = idx
    return ret
end

local function _walk_struct(s, fn, ks)
    ks = ks or {}
    for i = 0, s:struct_count() - 1 do
        local k = s:struct_get_key(i)
        ks[#ks + 1] = k
        local v = s:struct_get_value(i)
        if v.is_enum then
            fn(ks, v)
        elseif v.is_struct then
            _walk_struct(v, fn, ks)
        end
        ks[#ks] = nil
    end
end

local function _expand_start_val(s, val)
    if s.is_enum then
        local i = s:k2i(val)
        return s:enum_get_value(i)
    elseif s.is_struct then
        local ret = {}
        pcall(function()
            _walk_struct(s, function(ks, e)
                local p = val
                local prp = nil
                local rp = ret
                for _, v in ipairs(ks) do
                    p = p[v]
                    prp = rp
                    local nrp = rp[v]
                    if nrp == nil then
                        nrp = {}
                        rp[v] = nrp
                    end
                    rp = nrp
                end
                local i = e:k2i(p)
                local v = e:enum_get_value(i)
                prp[ks[#ks]] = v
            end)
        end)
        return ret
    end
end

-- Enums
function Enum:enum_count()
    return self._c
end
function Enum:k2i(k)
    return self._i[k]
end
function Enum:enum_get_key(i)
    return self[i]._k
end
function Enum:enum_get_value(i)
    return self[i]._v
end

-- Structs
function Struct:struct_count()
    return self._c
end
function Struct:k2i(k)
    return self._i[k]
end
function Struct:struct_get_key(i)
    return self[i]._k
end
function Struct:struct_get_value(i)
    return self[i]._v()
end
function Struct:enum_count()
    local p = 1
    for i = 0, self:struct_count() - 1 do
        local c = self:struct_get_value(i)
        p = p * c:enum_count()
    end
    return p
end
function Struct:enum_get_value(i)
    local r = {}
    for idx = 0, self:struct_count() - 1 do
        local v = self:struct_get_value(idx)
        local k = self:struct_get_key(idx)
        local m = v:enum_count()
        if m > 0 then
            local rmd = i % m
            i = (i - rmd) / m
            r[k] = v:enum_get_value(rmd)
        end
    end
    return r
end

-- Instance
function Instance:get_current_state_id()
    return self.cur_state_id
end

function Instance:input(i)
    print(string.format("Instance.input: %s", i))
end

function Instance:get_game()
    return self.g
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

function Elua:genenrate_states(n, fn)
    local ne = {}
    local core = self._e[n] or self._s[n]
    for i = 0, core:enum_count() - 1 do
        local v = core:enum_get_value(i)
        if (not fn) or fn(v) then
            ne[i] = v
        end
    end
    self._b = _wrap_enum(ne)
    self._cs = n
    return self
end

function Elua:start(start_val)
    local ret = {}
    ret.cur_state_id = 9527
    local s = self._e[self._cs] or self._s[self._cs]
    local exp = _expand_start_val(s, start_val)
    for i = 0, self._b:enum_count() - 1 do
        local v = self._b:enum_get_value(i)
        if _match_table(v, exp) then
            ret.cur_state_id = i
            break
        end
    end
    ret.g = self
    setmetatable(ret, Instance)
    return ret
end

function Elua:get_state_data(id)
    return self._b:enum_get_value(id)
end

function Elua:dump(p)
    p("******** ENUMS ********")
    for k, v in pairs(self._e) do
        local c = v:enum_count()
        p(string.format("=== %s(%s) - %s ===", k, tostring(v), c))
        for i = 0, c - 1 do
            local ik = v:enum_get_key(i)
            p(string.format("[%s] %s", i, ik))
            local ct = v:enum_get_value(i)
            for k0, v0 in pairs(ct) do
                p(string.format(" - %s = %s", k0, v0))
            end
        end
    end
    p("******** STRUCTS ********")
    for k, v in pairs(self._s) do
        local c = v:struct_count()
        local ec = v:enum_count()
        p(string.format("+++ %s(%s) - %s - %s+++", k, tostring(v), c, ec))
        for i = 0, c - 1 do
            local k = v:struct_get_key(i)
            local g = v:struct_get_value(i)
            p(string.format("[%s] %s(%s%s): %s", i, k, g.is_enum and "E" or "", g.is_struct and "S" or "", tostring(g)))
        end
        for i = 0, ec - 1 do
            local ev = v:enum_get_value(i)
            p(">>>")
            _dump_table(p, ev)
        end
    end
    p("******** BUILD ********")
    local ec = self._b:enum_count()
    p(string.format("TOTAL STATE COUNT: %s", ec))
    for i = 0, ec - 1 do
        local ev = self._b:enum_get_value(i)
        p(">>>")
        _dump_table(p, ev)
    end
end

return elua
