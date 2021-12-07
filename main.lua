-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------

local rng = require("rng")
local colors = require("colorsRGB")
local mylib = require("mylib")
local Button = require("Button")
local db = require("db")
local tiny = require("tiny")

-----------------------------------------------------------------------------------------
-- identifiers
-----------------------------------------------------------------------------------------

local entities = {}
local lasers = {}
local world = tiny.world()

-----------------------------------------------------------------------------------------
-- Screen Layout
-----------------------------------------------------------------------------------------

local backGroup = display.newGroup()
local mainGroup = display.newGroup()
local uiGroup = display.newGroup()

local background = display.newImageRect(backGroup,"./assets/images/background.png" ,1136,640)

background.x = display.contentCenterX
background.y = display.contentCenterY

display.setStatusBar(display.HiddenStatusBar)


local coinLeft = display.newImageRect(uiGroup,"./assets/images/coin.png",30, 30)
coinLeft.x = 0
coinLeft.y = 30

local coinLeftText = display.newText(uiGroup, "0", 100, 200, "./assets/fonts/Bangers.ttf")
coinLeftText:setFillColor(colors.RGB("black"))
coinLeftText.anchorX = 0
coinLeftText.x = coinLeft.x 
coinLeftText.y = coinLeft.y


local coinRight = display.newImageRect(uiGroup,"./assets/images/coin.png",30, 30)

coinRight.x = display.contentWidth
coinRight.y = 30

local coinRightText = display.newText(uiGroup, "0", 100, 200, "./assets/fonts/Bangers.ttf")

coinRightText.anchorX = display.contentWidth
coinRightText:setFillColor(colors.RGB("black"))
coinRightText.x = coinRight.x 
coinRightText.y = coinRight.y

local bases = {}
bases['left'] = mylib.base {left = true, coinsText=coinLeftText}
bases['right'] = mylib.base {right = true, coinsText=coinRightText}

local function spawn(o)
    local base = bases[mylib.team(o)]
    if base.coins < db[o.name].cost then return end

    print("spawn ".. o.name)
    base.coins = base.coins - db[o.name].cost
    local entity = mylib.spawn(o)
    entity.x = base.x - rng.random(-5,5)
    entity.y = base.y + rng.random(-100, 100)

    table.insert( entities, entity )
    world:addEntity(entity)
end

local histolyticaButton = Button:new{ group = uiGroup, name = "histolytica",
    text=db["histolytica"].cost,
    x=display.contentCenterX -150, y=display.contentHeight-40,
    onEvent = function() spawn {name="histolytica", left = true} end
}

local fowleriButton = Button:new{ group = uiGroup, name = "fowleri", 
    text=db["fowleri"].cost,
    x=display.contentCenterX, y=display.contentHeight-40,
    onEvent = function() spawn {name="fowleri", left = true} end
}

local proteusButton = Button:new{ group = uiGroup, name = "proteus", 
    text=db["proteus"].cost,
    x=display.contentCenterX+ 150, y=display.contentHeight-40,
    onEvent = function() spawn {name="proteus", left = true} end
}


-----------------------------------------------------------------------------------------
-- gather Resources System <- Base
-----------------------------------------------------------------------------------------

table.insert( entities, bases['left'])
table.insert( entities, bases['right'])

world:addEntity(bases['left'])
world:addEntity(bases['right'])

local gatherResourcesSystem = tiny.processingSystem()
gatherResourcesSystem.filter = tiny.requireAll("base")

function gatherResourcesSystem:process(e, dt)
    e.lastCoinDrop = e.lastCoinDrop + dt
    -- print("At base " .. mylib.team(e) .. " at time " .. e.lastCoinDrop)
    if e.lastCoinDrop > db[mylib.team(e)].skill then 
        e.lastCoinDrop = 0
        e.coins = e.coins +  10--(e.left and 10 or 0)
        e.coinsText.text = tostring(e.coins)
    end
end

world:addSystem(gatherResourcesSystem)

-----------------------------------------------------------------------------------------
-- Movement System <- Base
-----------------------------------------------------------------------------------------
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAny("histolytica", "fowleri", "proteus")
function movementSystem:process(entity, _)
    -- find closest enemy entity
    local closestEnemy
    local minDistSq = math.huge
    for _,other in pairs(entities) do
        if mylib.enemy(entity) == mylib.team(other) then
            local distSq = mylib.distanceSq(entity, other)
            if distSq<minDistSq then
                closestEnemy = other
                minDistSq = distSq
            end
        end
    end
    -- update direction
    local dist = math.sqrt(minDistSq)
    if dist < entity.size/2 then return end
    
    local targetAngle = mylib.safe_atan2(closestEnemy.y-entity.y, closestEnemy.x-entity.x)
    entity.image.rotation = 180/math.pi * targetAngle

    local speed = db[entity.name].speed
    entity.dx = speed * math.cos(targetAngle)
    entity.dy = speed * math.sin(targetAngle)

    -- update position
    entity.x = entity.x + entity.dx
    entity.y = entity.y + entity.dy

end
world:addSystem(movementSystem)

-----------------------------------------------------------------------------------------
-- AISystem <- Base (right)
-----------------------------------------------------------------------------------------
local aiSystem = tiny.processingSystem()
aiSystem.filter = tiny.requireAll("base", "right")

function aiSystem:process(entity, _)
    local amoeba = entity.nextAmoeba
    if entity.coins >= db[amoeba].cost then
        spawn {name=amoeba, left=entity.left, right=entity.right}
        local x = rng.random()
        local upper_lim = 0
        for i,p in ipairs(db.ai) do
            upper_lim = upper_lim + p
            if x <= upper_lim then
                entity.nextAmoeba = db.amoeba[i]
                break
            end
        end 
    end
end
world:addSystem(aiSystem)

-----------------------------------------------------------------------------------------
-- healthSystem <- Base and amoeba
-----------------------------------------------------------------------------------------
local healthSystem = tiny.processingSystem()
healthSystem.filter = tiny.requireAny("base", "histolytica", "fowleri", "proteus")
function healthSystem:process(entity, _)
    if entity.health<0 then
        entity.health = 0
        entity.dead = true
    end
    local relHealth = entity.health / db[entity.name].health
    entity.healthBar.width = relHealth * entity.size
    entity.healthBar:setFillColor(1-relHealth,relHealth^2,0)

end
world:addSystem(healthSystem)

-----------------------------------------------------------------------------------------
-- meleeSystem <- Base and amoeba
-----------------------------------------------------------------------------------------
local meleeSystem = tiny.processingSystem()
meleeSystem.filter = tiny.requireAny("base", "histolytica", "fowleri", "proteus")
function meleeSystem:process(entity, _)
    for _,other in pairs(entities) do
        if mylib.enemy(entity) == mylib.team(other) then
            local dist = mylib.distance(entity, other)
            if dist <= entity.size/2 + other.size/2 then
                entity.health = entity.health -
                    db[other.name].attack / db[entity.name].defense

                other.health = other.health -
                    db[entity.name].attack / db[other.name].defense
                
            end
        end
    end
end
world:addSystem(meleeSystem)

-----------------------------------------------------------------------------------------
-- laserSystem <- amoeba left and right
-----------------------------------------------------------------------------------------
local laserSystem = tiny.processingSystem()
laserSystem.filter = tiny.requireAny("histolytica", "fowleri", "proteus")
function laserSystem:process(entity, _)
    for _,other in pairs(entities) do
        
    end

end


-----------------------------------------------------------------------------------------
-- game loop
-----------------------------------------------------------------------------------------
world:refresh()
rng.randomseed(666)

print("Entity world has" .. world:getEntityCount().. " entities and" .. world:getSystemCount() .. " systems")

local function gameLoop()
    --print("Entity world has" .. world:getEntityCount().. " entities and" .. world:getSystemCount() .. " systems")

    world:update(1)

    for k = #entities, 1, -1 do
        local entity = entities[k]
        if entity.dead and not entity.base then
            world:removeEntity(entity)
            entity:destroy()
            display.remove(entity)
            
            table.remove(entities, k) 
            entity = nil
        end
    end
end

local gameLoopTimer = timer.performWithDelay(10, gameLoop, 0)