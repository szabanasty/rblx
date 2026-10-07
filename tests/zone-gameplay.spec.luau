--!nonstrict
return function(loadEquipment,loadCombat,loadRewards,loadRevive,StateRules,Schema,GameConfig,CombatConfig,EquipmentConfig,PvPRewardConfig)
    local M=require("../RuntimeMocks")
    local world=M.World()
    local a,b,c=world.Player(1,120),world.Player(2,140),world.Player(3,143)
    local profiles,records={},{}
    for _,player in {a,b,c} do profiles[player]=Schema.new(player.UserId,GameConfig);records[player]=StateRules.New(100);records[player].Ready=true;records[player].Area="CombatZone" end
    local team=false
    local ctx={Config={Game=GameConfig,Combat=CombatConfig,Equipment=EquipmentConfig,PvPRewards=PvPRewardConfig},StateRules=StateRules,
        Services={},Notify=function() end,Feedback=function() end,Remotes={Feedback={FireAllClients=function() end}}}
    ctx.Services.PlayerData={GetProfile=function(_,p) return profiles[p] end,MarkDirty=function() end}
    ctx.Services.State={GetRecord=function(_,p) return records[p] end,
        IsAllowed=function(_,p,kind) return StateRules.CanAct(records[p],kind,world.Now()) end,
        Tag=function(_,p) records[p].TaggedUntil=world.Now()+CombatConfig.CombatTagSeconds end,Changed=function() end}
    ctx.Services.Movement={GetPosition=function(_,p) return p.Character.HumanoidRootPart.Position end}
    ctx.Services.World={IsNear=function() return true end}
    ctx.Services.Scooter={GetTelemetry=function() return {Riding=false} end,Despawn=function() end}
    ctx.Services.Squad={Same=function(_,p,q) return team or p~=a and q~=a end}
    ctx.Services.Fishing={Stop=function() end}
    local paid={}
    ctx.Services.Economy={Spend=function(_,p,amount) if profiles[p].Money<amount then return false,"InsufficientMoney" end;profiles[p].Money-=amount;return true,"Paid" end,
        Credit=function(_,p,amount,source,key) assert(not paid[key],"duplicate credit");paid[key]=true;profiles[p].Money+=amount;return true,"Granted" end,
        Reward=function() return true,"Granted" end}
    local equipment=loadEquipment(world.Game,world.Clock)
    local combat=loadCombat(world.Game,M.Random,M.Vector3,M.Params,M.Enum,world.Clock)
    local rewards=loadRewards(world.Game,world.Clock)
    local revive=loadRevive(world.Game,M.Vector3,M.Params,M.Enum,world.Clock)
    ctx.Services.Equipment,ctx.Services.Combat,ctx.Services.PvPRewards,ctx.Services.Revive=equipment,combat,rewards,revive
    equipment:Init(ctx);combat:Init(ctx);rewards:Init(ctx);revive:Init(ctx);revive:Start()
    for _,player in {a,b,c} do equipment:EnsureStarter(player) end
    local checks=0
    local function check(ok,msg) assert(ok,msg);checks+=1 end
    check(profiles[a].OwnedEquipment.spark and profiles[a].EquippedLoadout.PRIMARY=="spark","starter reconciled server-side")
    check(not equipment:Equip(a,"ADMIN","spark") and not equipment:Equip(a,"PRIMARY","pulse"),"invalid slot and unowned loadout rejected")
    check(not equipment:Buy(a,"nova"),"combat state cannot trade even with proximity")
    local payload={X=1,Y=0,Z=0,Aim=true}
    local originalHead=a.Character.Head.Position
    a.Character.Head.Position=M.V(500,3,0)
    check(not combat:Shoot(a,payload) and equipment:GetSnapshot(a).Ammo==12,"spoofed rig head cannot move the shot origin away from verified root")
    a.Character.Head.Position=M.V(0/0,3,0)
    check(not combat:Shoot(a,payload),"nonfinite rig origin rejected")
    a.Character.Head.Position=originalHead
    world.Workspace.Hit=b
    team=true
    check(combat:Shoot(a,payload) and records[b].Health==100,"friendly fire never changes health")
    team=false;world.Tick(0.3)
    records[b].Area="SafeZone"
    check(combat:Shoot(a,payload) and records[b].Health==100,"untagged safe player protected")
    records[b].Area="CombatZone";world.Tick(0.3)
    check(combat:Shoot(a,payload) and records[b].Health==88,"server-confirmed hit deals catalog damage")
    local ammo=equipment:GetSnapshot(a).Ammo
    check(not combat:Shoot(a,payload) and equipment:GetSnapshot(a).Ammo==ammo,"cooldown cannot consume or fire twice")
    world.Workspace.Blocked=true;world.Tick(0.3)
    check(combat:Shoot(a,payload) and records[b].Health==88,"cover blocks raycast damage")
    world.Workspace.Blocked=false
    for _=1,8 do world.Tick(0.3);check(combat:Shoot(a,payload),"valid follow-up hit") end
    check(records[b].Health==0 and records[b].DownedUntil>world.Now() and profiles[a].Kills==0,"downed delays final settlement until recovery window closes")
    check(not combat:Shoot(b,payload),"downed player cannot fire")
    check(revive:Hold(c,2),"near teammate can begin revive")
    for _=1,15 do revive:Hold(c,2);world.Tick(0.35) end
    check(records[b].Health==35 and records[b].DownedUntil==0 and profiles[c].Revives==1,"five seconds of verified hold revive once")
    check(profiles[c].Money==140 and not combat:GetEncounter(b),"revive reward paid and old encounter cancelled")
    check(not revive:Hold(c,2) and profiles[c].Money==140,"revive cannot be replayed on active player")
    check(equipment:Reload(a),"empty capacity can reload")
    world.Tick(2.1)
    check(equipment:GetSnapshot(a).Ammo==EquipmentConfig.ById.spark.Capacity,"server reload timer restores capacity")
    for _=1,3 do world.Tick(0.3);combat:Shoot(a,payload) end
    check(records[b].DownedUntil>world.Now(),"second valid encounter created")
    revive:Hold(c,2);world.Tick(0.3);revive:Cancel(c)
    check(not revive:GetSnapshot(c) and not records[c].Reviving,"release cancels server revive progress")
    revive:Hold(c,2);world.Tick(1)
    check(not revive:GetSnapshot(c) and records[b].DownedUntil>0,"missing hold keepalive cannot finish revive")
    combat:Finalize(b);combat:Finalize(b)
    check(profiles[a].Kills==1 and profiles[b].Deaths==1 and profiles[a].Money==200,"encounter settled once including stats and money")
    for count=2,4 do
        local encounter={Id="repeat"..count,Attacker=1,Victim=2,VictimStreak=0,Contributions={},At=world.Now()}
        local before=profiles[a].Money
        rewards:Settle(encounter)
        local expected=if count==2 then 50 elseif count==3 then 50 else 0
        check(profiles[a].Money-before==expected,"opponent multiplier scales base and streak bonus "..count)
        local kills=profiles[a].Kills
        rewards:Settle(encounter)
        check(profiles[a].Kills==kills,"settled encounter object cannot repeat")
    end
    local before=profiles[a].Money
    rewards:Settle({Id="farmed-bounty",Attacker=1,Victim=2,VictimStreak=20,Contributions={},At=world.Now()})
    check(profiles[a].Money==before,"anti-farming also scales bounty and milestone to zero")
    profiles[a]=Schema.sanitize(profiles[a],GameConfig)
    profiles[c]=Schema.sanitize(profiles[c],GameConfig)
    local restarted=loadRewards(world.Game,world.Clock)
    restarted:Init(ctx)
    local beforeRestart=profiles[a].Money
    restarted:Settle({Id="new-server",Attacker=1,Victim=2,VictimStreak=20,Contributions={},At=world.Now()})
    check(profiles[a].Money==beforeRestart,"saved anti-farm window survives service restart and profile reload")
    local beforeRevive=profiles[c].Money
    restarted:Revive(c,b,"new-revive")
    check(profiles[c].Money==beforeRevive,"revive pair cooldown survives profile reload")
    print("Zone combat/equipment/revive/reward checks passed: "..checks)
end
