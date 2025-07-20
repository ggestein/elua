local elua = require("elua")
local e = elua.new_elua()
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
:dump(print)

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

