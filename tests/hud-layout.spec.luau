--!nonstrict
return function(Layout)
    local checks = 0
    local function check(value, message) assert(value, message); checks += 1 end
    local function intersects(a, b)
        return a.X < b.X + b.W - 0.01 and b.X < a.X + a.W - 0.01
            and a.Y < b.Y + b.H - 0.01 and b.Y < a.Y + a.H - 0.01
    end
    local views = {{1920,1080}, {1366,768}, {1024,768}, {900,600}, {844,390}, {740,360}, {640,360}, {568,320}, {390,844}, {360,640}, {320,568}, {320,480}}
    for _, view in views do
        for _, preference in {0.75, 1, 1.5} do
            for _, touch in {false, true} do
                local width, height = view[1], view[2]
                local result = Layout.Calculate(width,height,preference,touch)
                local label = width .. "x" .. height .. "/" .. preference .. "/" .. tostring(touch)
                for name, rect in result.Panels do
                    check(rect.W > 0 and rect.H > 0 and rect.X >= 0 and rect.Y >= 0 and rect.X + rect.W <= width + 0.01 and rect.Y + rect.H <= height + 0.01, label .. " out of bounds: " .. name)
                end
                for _, mode in {"Equipment", "Scooter", "Revive", "Fishing"} do
                    local names = {"Area", "Squad", "Economy", "Menu", "Health"}
                    if result.MapDefault then table.insert(names,"Map") elseif not result.Small then table.insert(names,"MapToggle") end
                    if mode == "Revive" then table.insert(names,"Revive")
                    else
                        table.insert(names,if mode == "Scooter" then "Scooter" else "Equipment")
                        table.insert(names,"Activity")
                    end
                    if mode == "Fishing" then table.insert(names,"StopFishing") end
                    if touch and mode ~= "Fishing" and mode ~= "Revive" then
                        table.insert(names,if mode == "Scooter" then "RideControls" else "CombatControls")
                        if mode == "Scooter" then table.insert(names,"RideActions") end
                    end
                    for i = 1, #names do for j = i + 1, #names do
                        check(not intersects(result.Panels[names[i]], result.Panels[names[j]]), label .. " / " .. mode .. " collision: " .. names[i] .. " + " .. names[j])
                    end end
                end
                if touch then
                    check(result.Panels.Menu.H >= 44 and result.Panels.MapToggle.H >= 44,"menu touch targets stay large")
                    local nativeMove = {X=0,Y=height-170,W=160,H=170}
                    check(not intersects(result.Panels.Health,nativeMove),label.." health covers native movement")
                end
            end
        end
    end
    print("HUD responsive rectangle checks passed: " .. checks .. " (12 viewports, 3 scales, touch/desktop, 4 modes)")
end
