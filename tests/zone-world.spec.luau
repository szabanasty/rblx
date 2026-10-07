--!nonstrict
return function(loadMovement,loadObjective,GameConfig,ZoneWorldConfig,Validation)
    local M=require("../RuntimeMocks")
    local world=M.World()
    local player=world.Player(1,0)
    local root=player.Character.HumanoidRootPart
    local cframe={}
    local frameMeta={__mul=function(a) return a end}
    function cframe.new(position) return setmetatable({Position=position,Rotation="identity"},frameMeta) end
    root.CFrame=cframe.new(root.Position)
    local grounded=true
    function world.Workspace:Raycast(origin,direction)
        if direction.Y==-7 and grounded then return {Instance={CanCollide=true},Position=M.V(origin.X,0,origin.Z)} end
        return nil
    end
    local movement=loadMovement(world.Game,M.Vector3,cframe,M.Params,M.Enum,world.Clock,function() end)
    local riding=false
    movement:Init({Config={Game=GameConfig},Validation=Validation,Services={Scooter={GetTelemetry=function() return {Riding=riding} end}}})
    movement:Start()
    local checks=0
    local function check(ok,msg) assert(ok,msg);checks+=1 end
    check(movement:GetPosition(player)==nil,"new root receives grace without activity eligibility")
    world.Tick(1.1)
    check(movement:GetPosition(player)~=nil,"stationary character becomes eligible")
    root.Position=M.V(2,3,0);world.Tick(0.2)
    check(movement:GetPosition(player)~=nil,"ordinary walking accepted")
    root.Position=M.V(200,3,0)
    check(movement:GetPosition(player)==nil and root.CFrame.Position.X==2,"teleport corrected to last approved root")
    root.Position=root.CFrame.Position;world.Tick(3.1)
    check(movement:GetPosition(player)~=nil,"player recovers after short restriction without kick")
    -- Several individually small shifts still exceed the rolling velocity budget.
    root.Position=M.V(8,3,0);world.Tick(0.2)
    root.Position=M.V(15,3,0);world.Tick(0.2)
    root.Position=M.V(23,3,0);world.Tick(0.2)
    check(movement:GetPosition(player)==nil,"sustained speed spoof cannot hide in per-tick tolerance")
    root.Position=root.CFrame.Position;world.Tick(3.1);grounded=false
    world.Tick(0.2);world.Tick(3.2)
    check(movement:GetPosition(player)==nil,"sustained unsupported flight rejected")
    grounded=true;root.Position=M.V(0,3,0);movement:AllowTeleport(player,root.Position);world.Tick(1.1)
    riding=true;root.Position=M.V(10,3,0);world.Tick(0.2)
    check(movement:GetPosition(player)~=nil,"validated seat transition accepts server spawn offset")
    root.Position=M.V(26,3,0);world.Tick(0.2)
    check(movement:GetPosition(player)~=nil,"server-owned riding uses the vehicle motion budget")
    riding=false;root.Position=M.V(28,3,0);world.Tick(0.2)
    check(movement:GetPosition(player)~=nil,"ordinary dismount resets rolling foot budget without false teleport flag")
    root.Position=M.V(28,-15,0)
    check(movement:GetPosition(player)==nil and root.CFrame.Position.Y==3,"falling into the river restores last grounded position instead of an airborne point")
    -- Objective uses verified players, multiplayer membership, contest and a server timer.
    world=M.World()
    local a,b,c=world.Player(1,1050),world.Player(2,1055),world.Player(3,1150)
    local paid={}
    local objective=loadObjective(world.Game,M.Vector3,world.Clock)
    local state={}
    local ctx={Config={World=ZoneWorldConfig},Feedback=function() end,Services={}}
    ctx.Services.Movement={GetPosition=function(_,p) return p.Character.HumanoidRootPart.Position end}
    ctx.Services.State={IsAllowed=function(_,p) return not state[p] end}
    ctx.Services.Scooter={GetTelemetry=function() return {Riding=false} end}
    ctx.Services.Squad={GetId=function(_,p) return if p==c then "enemy" else "team" end}
    ctx.Services.Economy={Credit=function(_,p,amount,_,key) assert(not paid[key]);paid[key]=amount;return true end,Reward=function() return true end}
    objective:Init(ctx);objective:Start()
    for _=1,60 do world.Tick(0.5) end
    local count=0
    for _,amount in paid do count+=1;check(amount==ZoneWorldConfig.Objective.Reward,"objective reward comes from config") end
    check(count==2 and objective:GetSnapshot().Cooldown>0,"both present squad members rewarded once")
    for _=1,20 do world.Tick(0.5) end
    local after=0;for _ in paid do after+=1 end
    check(after==2,"cooldown prevents repeated point farming")
    world.Tick(180)
    c.Character.HumanoidRootPart.Position=M.V(1050,3,0)
    world.Tick(0.5)
    check(objective:GetSnapshot().Contested and objective:GetSnapshot().Progress==0,"other squad contests and resets hold")
    c.Character.HumanoidRootPart.Position=M.V(1150,3,0);state[b]=true
    world.Tick(0.5)
    check(objective:GetSnapshot().Progress==0,"downed/invalid member cannot satisfy squad objective")
    print("Zone movement/objective checks passed: "..checks)
end
