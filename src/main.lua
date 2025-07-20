local elua = require("elua")
local e = elua.new_elua()
local inst =
e
:load_enum("te0", {
    id0 = { name = "Hello", desc = "World", valid = true },
    id1 = { name = "John", desc = "Smith", valid = false },
})
:load_enum("te1", {
    yes = { meaning = 1 },
    no = { meaning = 2}
})
:load_struct("ts0", {
    x = "te0",
    y = "te1"
})
:load_struct("ts1", {
    a = "te0",
    b = "ts0"
})
:genenrate_states("ts1", function(state)
    return state.b.x.valid or state.a.valid
end)
:start({
    a = "id0",
    b = {
        x = "id1",
        y = "no"
    }
})
print(string.format("inst:get_current_state_id() = %s", inst:get_current_state_id()))
local state = e:get_state_data(inst:get_current_state_id())

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
print("CIRCLE:")
_dump_table(print, state)

function love.update(dt)
end

function love.draw()
    local y = 10
    local p = function(s)
        love.graphics.print(s, 10, y)
        y = y + 20
    end
    e:dump(p)
end

function love.keypressed(k)
    if k == "escape" then
        love.event.quit()
    end
end

