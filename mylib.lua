local mylib = {}

local db = require("db")
local colors = require("colorsRGB")

-----------------------------------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------------------------------

function mylib.team(o)
    assert(o.left or o.right, "Object should have either 'left' or 'right' property")
    return o.left and "left" or "right"
end

function mylib.enemy(o)
    assert(o.left or o.right, "Object should have either 'left' or 'right' property")
    return o.left and "right" or "left"
end

function mylib.distanceSq(a,b)
    return (a.x-b.x)^2 + (a.y-b.y)^2
end

function mylib.distance(a,b)
    return math.sqrt( mylib.distanceSq(a,b) )
end

function mylib.safe_atan2(y,x)
    local angle = math.atan2(y,x)
    if angle< 0 then 
        angle = angle + 2*math.pi
    end
    return angle
end

-----------------------------------------------------------------------------------------
-- Game Entities
-----------------------------------------------------------------------------------------
function mylib.destroy(group) 
    display.remove(group.image)
    group:remove(group.image)
    group.image = nil

    display.remove(group.healthBar)
    group:remove(group.healthBar)
    group.healthBar = nil
end


function mylib.base (o)
    local group = display.newGroup()
    group.x = o.x or (o.left and 0 or display.contentWidth)
    group.y = o.y or display.contentCenterY
    o.name = o.name or "base"

    local filename = "./assets/images/base_"..mylib.team(o).."_defence.png"
    local size = db[o.name].size
    local image = display.newImageRect(filename,size,size)
    group:insert(image)

    group.coins = 200
    group.lastCoinDrop = 0
    group.coinsText = o.coinsText
    group.nextAmoeba = "histolytica"

    group.name = o.name -- used for debugging
    group.base = true -- used by entity system to filter entities

    group.size = size

    group.health = db[group.name].health
    group.healthBar = display.newRect(group, 0, -size/2, size, 5)
    group.healthBar.strokeWidth = 1
    group.healthBar:setFillColor(0,1,0)
    group.healthBar:setStrokeColor(colors.RGB("white"))

    group[mylib.team(o)] = true

    group.destroy = mylib.destroy
    return group
end

function mylib.spawn (o)
    local group = display.newGroup()
    group.x = o.x or display.contentCenterX
    group.y = o.y or display.contentCenterY

    group.dx = (mylib.team(o)=="left" and 1 or -1)
    group.dy = 0
    local filename = "./assets/images/".. o.name.."_"..mylib.team(o)..".png"
    local size = db[o.name].size
    local image = display.newImageRect(filename,size,size)
    group:insert(image)
    group.image = image

    group.name = o.name     -- debugging
    group[o.name] = true    -- entity system
    group[mylib.team(o)] = true
    group.size = size

    group.health = db[group.name].health
    group.healthBar = display.newRect(group, 0, -size/2, size, 5)
    group.healthBar.strokeWidth = 1
    group.healthBar:setFillColor(0,1,0)
    group.healthBar:setStrokeColor(colors.RGB("white"))

    group.fireCooldown = db[group.name].fireRate
    group.fireRate = db[group.name].fireRate
    group.destroy = mylib.destroy

    return group
end

function mylib.spawnLaser(o)
    local group = display.newGroup()
    group.x = o.x or display.contentCenterX
    group.y = o.y or display.contentCenterY

    group.dx = (mylib.team(o)=="left" and 1 or -1)
    group.dy = 0

    local filename = "./assets/images/laser_"..mylib.team(o)..".png"
    local size = db[o.name].size
    local image = display.newImageRect(filename,size,size)
    group:insert(image)
    group.image = image

    return group
end

return mylib