local Button={}

local widget = require("widget")
local colors = require("colorsRGB")

function Button:new(o)
    o = o or {}
    setmetatable(o, self)
    self._index = self

    o.size = o.size or 30
    local button = widget.newButton{
        group = o.group,
        x = o.x,
        y = o.y,
        width = 3*o.size,
        height = o.size,
        label = "",
        defaultFile = "assets/images/button.png",
        overFile = "assets/images/button_selected.png",
        onRelease = o.onEvent
    }
    -- button:
    button.name = o.name
    button.cost = tonumber(o.text)

    local filename = "assets/images/"..o.name.."_left.png"
    local icon  = display.newImageRect(filename,0.7*o.size,0.7*o.size);
    icon.x =button.x - 0.8*o.size
    icon.y  = button.y
    button.icon = icon
    local text = display.newText(o.text,0,0,"assets/fonts/Bangers.ttf",0.7*o.size)
    text:setFillColor(colors.RGB("black"));
    text.x = button.x +0.7* o.size
    text.y = button.y + 0.05 * o.size

end

return Button