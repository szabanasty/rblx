--!nonstrict
return function(loadGui,loadHud,loadUI,loadCombat,loadRevive,Layout,ScooterConfig,EquipmentConfig,ZoneConfig,WorldConfig,CombatConfig)
    local Mock=require("../GuiMocks")
    local M=require("../RuntimeMocks")
    local checks=0
    local function check(ok,message) assert(ok,message);checks+=1 end
    for _,touch in {false,true} do
        local world=Mock.World(if touch then 320 else 1366,if touch then 568 else 768,touch)
        local gui=loadGui(world.Instance,world.UDim2,world.Color3,world.Enum,world.UDim)
        local hud=loadHud(function() return gui end,{Parent={GuiFactory="Gui"}},world.Color3,world.UDim2,world.UDim,world.Enum)
        local modules={GuiFactory="Gui",ZoneMenus="Menus",ZoneHud="Hud",HudLayout="Layout"}
        local script={Parent={Parent={Modules=modules}}}
        local menus={Build=function() end}
        local function requires(key) return ({Gui=gui,Hud=hud,Layout=Layout,Menus=menus})[key] end
        local ui=loadUI(world.Game,requires,script,world.UDim2,world.UDim,world.Color3,world.Vector2,world.Enum,world.Task)
        local sent,values={},{}
        local ctx={Config={Scooters=ScooterConfig,Equipment=EquipmentConfig,Zones=ZoneConfig,World=WorldConfig,Combat=CombatConfig},Controllers={UIController=ui,
            InputController={SetMenuOpen=function(_,value) values.Menu=value end}},Send=function(name,payload) table.insert(sent,{Name=name,Payload=payload}) end}
        ui:Init(ctx);ui:SetInputHandlers({Set=function(name,value) values[name]=value end});ui:Start()
        local snapshot={Ready=true,Money=1234,Level=3,XP=25,XPToNextLevel=100,Settings={UIScale=1},SaveMode="StudioMemory",Status="Ready",
            PlayerState={State="SAFE",AreaId="SafeZone",AreaName="SAFE ZONE",CurrentHealth=75,MaxHealth=100,CurrentStreak=2,CombatSeconds=0,DownedSeconds=0},
            Equipment={Slot="PRIMARY",EquipmentId="spark",Ammo=8,Capacity=12,ReloadSeconds=0},Squad={Members={}},Telemetry={Riding=false,Speed=0,Battery=75,ScooterId="kukirin_g2"},
            Fishing={Active=false,Inventory={},Limit=60,Revision=0},Objective={Progress=0,Cooldown=0,Contested=false},Kills=2,Deaths=1,Assists=0,Revives=0,
            OwnedScooters={"kukirin_g2"},ScooterUpgrades={},OwnedEquipment={},EquippedLoadout={},Cosmetics={},Players={},Leaderboard={}}
        ui:Update(snapshot)
        check(world.Find("EconomyHUD").Visible and world.Find("HealthHUD").Visible,"independent ready panels shown")
        check(world.Find("Money").Text=="$ 1234" and world.Find("Ammo").Text=="08 / 12","actual HUD paints server values")
        check(not world.Find("ScooterHUD").Visible,"speed hidden on foot")
        snapshot.PlayerState.AreaId="CombatZone";snapshot.PlayerState.State="ALIVE"
        ui:Update(snapshot);check(world.Find("ActivityHUD").Visible,"objective appears in combat district")
        snapshot.Telemetry.Riding=true;snapshot.Telemetry.Speed=32
        ui:Update(snapshot);check(world.Find("ScooterHUD").Visible and not world.Find("EquipmentHUD").Visible,"riding replaces equipment card")
        local throttle=world.Button("GAZ");local pointer={UserInputType=world.Enum.UserInputType.Touch}
        throttle.InputBegan:Fire(pointer);check(values.Throttle,"pedal begins with its pointer")
        ui:Open();check(values.Menu and not values.Throttle and not world.Find("ScooterHUD").Visible,"menu immediately releases pedal and hides gameplay cards")
        ui:Close();check(not values.Menu,"menu restores input mode")
        ui:Open();ui:ToggleMap();check(world.Find("Minimap").Visible==touch,"map toggles from responsive default through open menu")
        ui:Open();ui:ToggleMap();check(world.Find("Minimap").Visible~=touch,"map toggles back even though menu temporarily hides it")
        snapshot.Telemetry.Riding=false
        ui:Update(snapshot);ui:SetReviveAvailable(true)
        check(not world.Find("EquipmentHUD").Visible,"revive target reserves clear button space")
        ui:SetReviveAvailable(false)
        local combat=loadCombat(world.Game,requires,script,world.Enum,world.UDim2,world.Color3,world.Vector2,M.Vector3,M.Params,os)
        ctx.Controllers.CombatController=combat;combat:Init(ctx);combat:Start()
        snapshot.PlayerState.State="SAFE";snapshot.PlayerState.AreaId="SafeZone"
        combat:Update(snapshot);world.Input.InputBegan:Fire({KeyCode=world.Enum.KeyCode.R},false)
        check(sent[#sent].Name=="Reload","SAFE permits reload input before an encounter")
        local count=#sent;combat:Fire();check(#sent==count,"out-of-combat fire intent suppressed")
        snapshot.PlayerState.AreaId="CombatZone";snapshot.PlayerState.State="ALIVE"
        combat:Update(snapshot);combat:SetAim(true);check(world.Camera.FieldOfView==55,"aim uses temporary FOV")
        ui:Open();world.Run.RenderStepped:Fire(0.1)
        check(world.Camera.FieldOfView==70,"menu clears aiming on next render without waiting for server snapshot")
        ui:Close()
        local revive=loadRevive(world.Game,requires,script,world.Enum,world.UDim2,world.Vector2,M.Vector3,world.Task,os)
        ctx.Controllers.ReviveController=revive;revive:Init(ctx);revive:Start()
        snapshot.Squad.Members={{UserId=2,Name="Friend",Position={X=5,Y=3,Z=0},State={State="DOWNED"}}}
        revive:Update(snapshot);world.Input.InputBegan:Fire({KeyCode=world.Enum.KeyCode.E},false);world.Run.Heartbeat:Fire()
        check(sent[#sent].Name=="HoldRevive" and sent[#sent].Payload.TargetId==2,"nearest teammate emits only target intent")
        ui:Open();world.Run.Heartbeat:Fire();check(sent[#sent].Name=="CancelRevive","menu cancels hold without waiting for a snapshot")
        ui:Close();snapshot.PlayerState.State="RESPAWNING";revive:Update(snapshot)
        check(not world.Button("PRZYTRZYMAJ E\nOCUĆ").Visible,"respawning player cannot start a revive input")
        snapshot.PlayerState.HealthReady=false;ui:Update(snapshot)
        check(world.Find("Health").Text=="ODRADZANIE…","loaded profile does not display health as ready while avatar respawns")
        snapshot.Status="SaveFailed";ui:Update(snapshot)
        check(string.find(world.Find("Level").Text,"PROBLEM Z ZAPISEM",1,true),"persistence failure remains visible without a debug box")
        snapshot.Ready=false;ui:Update(snapshot)
        check(not world.Find("HealthHUD").Visible and not world.Find("Minimap").Visible,"unloaded profile hides stale gameplay")
    end
    print("Actual HUD/controller API-boundary checks passed: "..checks.." (no Roblox renderer)")
end
