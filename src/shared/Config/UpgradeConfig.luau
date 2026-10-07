--!strict
local categories = {
    Motor = {Name = "Silnik", BasePrice = 125, Effects = {TopSpeed = 2, Acceleration = 0.25}},
    Controller = {Name = "Kontroler", BasePrice = 125, Effects = {Acceleration = 0.2, Handling = 8}},
    Battery = {Name = "Bateria", BasePrice = 100, Enabled = true, Effects = {Battery = 25}},
    Brakes = {Name = "Hamulce", BasePrice = 100, Effects = {Braking = 1.5}},
    Tires = {Name = "Opony", BasePrice = 100, Effects = {Handling = 8, Stability = 0.1}},
    Suspension = {Name = "Zawieszenie", BasePrice = 125, Effects = {Jump = 0.5, Stability = 0.15}},
    Steering = {Name = "Sterowanie", BasePrice = 100, Effects = {Handling = 12}},
    Acceleration = {Name = "Przyspieszenie", BasePrice = 150, Effects = {Acceleration = 0.5}},
}
return table.freeze({
    Categories = categories, MaxLevel = 5, PriceGrowth = 2,
    ShopOrder = {"Motor", "Controller", "Battery", "Brakes", "Tires", "Suspension"},
    RequiredLevel = 1, RequiredLevelStep = 3,
})
