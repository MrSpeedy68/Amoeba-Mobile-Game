local db = {
    histolytica = 
        {size=30, cost=10, speed=4, radius=15, health=100, attack=1, defense=1, fireRate=5},
    fowleri = 
        {size=35, cost=25, speed=2, radius=15, health=200, attack=2, defense=2, fireRate=10},
    proteus = 
        {size=40, cost=50, speed=1, radius=20, health=300, attack=5, defense=5, fireRate=8},
}
db.base = { size=50, health=1000, attack=1, defense=1}
db.left = {skill = 25}
db.right = {skill = 25}

db.amoeba = {"histolytica", "fowleri", "proteus"}

db.ai = { 0.50, 0.30, 0.20}
return db