--!strict
-- Pixel rectangles in ScreenGui's safe area, shared with touch/combat/revive controls.
local Layout = {}
export type Rect = {X: number, Y: number, W: number, H: number}
export type Result = {Scale: number, Compact: boolean, Short: boolean, Small: boolean, MapDefault: boolean, Panels: {[string]: Rect}}
function Layout.Calculate(width: number, height: number, preference: number, touch: boolean): Result
    width, height = math.max(280, width), math.max(280, height)
    local compact = touch or width < 1000 or height < 650
    local short = height < 500 and width > height
    local small = width < 500 and height < 650
    local scale = math.min(math.clamp(preference, 0.75, 1.5), (width - 36) / (if compact then 360 else 900), (height - 28) / 400)
    if compact then scale = math.min(1, scale) end
    local gap = 12
    local panels: {[string]: Rect} = {}
    local function at(name: string, x: number, y: number, w: number, h: number)
        panels[name] = {X = x, Y = y, W = w * scale, H = h * scale}
    end
    local leftWidth = if compact then 186 else 246
    local moneyWidth = if compact then 174 else 224
    at("Area", gap, gap, leftWidth, 40)
    at("Squad", gap, gap + 48 * scale, leftWidth, if compact then 52 else 84)
    at("Economy", width - gap - moneyWidth * scale, gap, moneyWidth, 78)
    at("Menu", width - gap - 84 * scale, gap + 86 * scale, 84, 48)
    at("MapToggle", width - gap - 84 * scale, gap + 142 * scale, 84, 48)
    if touch then
        panels.Menu.W, panels.Menu.H = 84, 48
        panels.Menu.X = width - gap - 84
        panels.MapToggle.W, panels.MapToggle.H = 84, 48
        panels.MapToggle.X, panels.MapToggle.Y = width - gap - 84, panels.Menu.Y + 60
    end
    if short and width >= 500 then
        panels.Menu.X, panels.Menu.Y = (width - 180) / 2, gap
        panels.MapToggle.X, panels.MapToggle.Y = (width - 180) / 2 + 96, gap
    end
    local healthWidth = if compact then 200 else 246
    if compact and not short then healthWidth = math.min(200, (width - 36) / scale - 186) end
    local healthHeight = if touch and short then 60 else 86
    local healthY = if touch then height - 174 - healthHeight * scale else height - gap - healthHeight * scale
    at("Health", gap, healthY, healthWidth, healthHeight)
    if compact then
        local gearWidth = if short then 220 else 186
        local gearX = if short then (width - gearWidth * scale) / 2 else width - gap - gearWidth * scale
        local controlsTop = height - math.max(85 + 155 * math.min(1, (width - 24) / 370, (height - 24) / 300), 180 + 60 * math.min(1, (width - 24) / 370, (height - 24) / 300))
        local gearY = if short or not touch then height - gap - 92 * scale else math.max((if small then panels.Menu.Y + panels.Menu.H else panels.MapToggle.Y + panels.MapToggle.H) + 12, controlsTop - 12 - 92 * scale)
        at("Equipment", gearX, gearY, gearWidth, 92)
        at("Scooter", gearX, gearY, gearWidth, 92)
        local activityWidth = if short then math.min(240, (width - 2 * (leftWidth * scale + gap + 12)) / scale) else math.min(260, (width - 120 * scale - 24) / scale)
        at("Activity", if short then (width - activityWidth * scale) / 2 else gap, gap + 112 * scale, activityWidth, 64)
    else
        at("Equipment", width - gap - 224 * scale, height - gap - 100 * scale, 224, 100)
        at("Scooter", (width - 260 * scale) / 2, height - gap - 100 * scale, 260, 100)
        at("Activity", width - gap - 260 * scale, 218 * scale, 260, 64)
    end
    local mapSize = if compact then 150 else 176
    local mapY = if compact then gap + 196 * scale else healthY - gap - mapSize * scale
    at("Map", gap, mapY, mapSize, mapSize)
    at("StopFishing", panels.Activity.X, panels.Activity.Y + panels.Activity.H + 8, 150, 56)
    local controlScale = math.min(1, (width - 24) / 370, (height - 24) / 300)
    panels.RideControls = {X = width - gap - 174 * controlScale, Y = height - gap - 155 * controlScale, W = 174 * controlScale, H = 155 * controlScale}
    panels.CombatControls = {X = width - gap - 174 * controlScale, Y = height - 85 - 155 * controlScale, W = 174 * controlScale, H = 155 * controlScale}
    panels.RideActions = {X = width - gap - 168 * controlScale, Y = height - 180 - 60 * controlScale, W = 168 * controlScale, H = 60 * controlScale}
    at("Revive", (width - 170 * scale) / 2, if short then 24 + 176 * scale else math.max(200 * scale, height - 450 * scale), 170, 66)
    return {Scale = scale, Compact = compact, Short = short, Small = small, MapDefault = not compact, Panels = panels}
end
return Layout
