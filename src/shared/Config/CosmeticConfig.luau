--!strict
return table.freeze({
    Colors = {Orange = {230, 158, 52}, Mint = {62, 208, 171}, Violet = {149, 99, 236}, Blue = {70, 153, 235}, Red = {221, 77, 96}},
    Categories = {Color = 100, Grips = 75, Deck = 100, Lights = 125, Wheels = 100, Decals = 75, Effects = 150},
    Styles = {Street = {Price = 150, Color = {62, 71, 95}}, Tech = {Price = 250, Color = {60, 145, 183}}, Sunset = {Price = 250, Color = {185, 109, 80}}},
    Tags = {rookie = {DisplayName = "ROOKIE", Price = 0}, city = {DisplayName = "CITY RIDER", Price = 250}, zone = {DisplayName = "ZONE RUNNER", Price = 500}},
    -- Add only owned/licensed uploaded assets. Empty IDs intentionally produce no sound/animation.
    Audio = {Music = "", Fire = "", Hit = "", UI = "", Scooter = "", Fishing = ""},
    Animations = {Ride = "", Downed = "", Revive = "", Fish = ""},
})
