--!nonstrict
return function(loadService, Validation, RateLimiter, GameConfig)
    local checks=0
    local function check(ok,message) assert(ok,message); checks+=1 end
    local function signal()
        local out={Callbacks={}}
        function out:Connect(fn) table.insert(self.Callbacks,fn) end
        function out:Fire(...) for _,fn in self.Callbacks do fn(...) end end
        return out
    end
    local function fixture()
        local now=100
        local players={PlayerRemoving=signal(),GetPlayers=function() return {} end}
        local player={UserId=123,Parent=players}
        local calls={Spawn=0,Despawn=0,Select=0,Input=0,Sync=0,Dismount=0,Notify=0,Feedback=0,Dirty=0,Buy=0,Upgrade=0,Quest=0}
        local profile={Settings={UIScale=1}}
        local remotes={Action={OnServerEvent=signal()},Input={OnServerEvent=signal()},Feedback={FireClient=function(_,_,_) calls.Feedback+=1 end}}
        local legacyConfig=table.clone(GameConfig)
        legacyConfig.FoundationOnly=false
        local ctx={
            Config={Game=legacyConfig},Validation=Validation,RateLimiter=RateLimiter,Remotes=remotes,
            Notify=function() calls.Notify+=1 end,
            Services={
                PlayerData={IsReady=function() return true end,GetProfile=function() return profile end,MarkDirty=function() calls.Dirty+=1 end},
                Scooter={
                    Spawn=function() calls.Spawn+=1;return true,"Spawned" end,
                    Despawn=function() calls.Despawn+=1;return true,"Despawned" end,
                    Select=function() calls.Select+=1;return false,"NotOwned" end,
                    Dismount=function() calls.Dismount+=1;return true,"Dismounted" end,
                    SetInput=function() calls.Input+=1 end,
                },
                Snapshot={Send=function() calls.Sync+=1 end},
                Shop={BuyScooter=function(_,_,id) assert(id=="kukirin_g3");calls.Buy+=1;return true,"ScooterPurchased" end,
                    Upgrade=function(_,_,id,category) assert(id=="kukirin_g2" and category=="Motor");calls.Upgrade+=1;return true,"UpgradePurchased" end},
                Quests={StartQuest=function(_,_,id) assert(id=="first_delivery");calls.Quest+=1;return true,"QuestStarted" end},
            },
        }
        local service=loadService({GetService=function(_,name) assert(name=="Players");return players end},{clock=function() return now end},function() end)
        service:Init(ctx);service:Start()
        return {Context=ctx,Calls=calls,Profile=profile,Player=player,Remotes=remotes,
            Tick=function(amount) now+=amount end,Remove=function() players.PlayerRemoving:Fire(player) end}
    end
    local f=fixture()
    f.Remotes.Action.OnServerEvent:Fire(f.Player,{Action="Reward",Payload={Money=999},RequestId=1})
    check(f.Calls.Feedback==0 and f.Calls.Notify==0,"reward injection rejected")
    local request={Action="SpawnScooter",Payload={},RequestId=2}
    f.Remotes.Action.OnServerEvent:Fire(f.Player,request)
    f.Remotes.Action.OnServerEvent:Fire(f.Player,request)
    check(f.Calls.Spawn==1,"replay blocked")
    f.Tick(1)
    f.Remotes.Action.OnServerEvent:Fire(f.Player,{Action="SetSetting",Payload={Name="UIScale",Value=1.25},RequestId=3})
    check(f.Profile.Settings.UIScale==1.25 and f.Calls.Dirty==1,"settings persist only through whitelist")
    f.Remotes.Input.OnServerEvent:Fire(f.Player,{Throttle=0/0,Steer=0,Brake=false,Jump=false})
    check(f.Calls.Input==0,"nonfinite input rejected")
    f.Remotes.Input.OnServerEvent:Fire(f.Player,{Throttle=1,Steer=0,Brake=false,Jump=false})
    check(f.Calls.Input==1,"valid intent forwarded")
    f.Remotes.Action.OnServerEvent:Fire(f.Player,{Action="BuyScooter",Payload={ScooterId="kukirin_g3"},RequestId=4})
    f.Remotes.Action.OnServerEvent:Fire(f.Player,{Action="UpgradeScooter",Payload={ScooterId="kukirin_g2",Category="Motor"},RequestId=5})
    f.Remotes.Action.OnServerEvent:Fire(f.Player,{Action="StartQuest",Payload={QuestId="first_delivery"},RequestId=6})
    check(f.Calls.Buy==1 and f.Calls.Upgrade==1 and f.Calls.Quest==1,"shop and quest intents route to server services")
    local flood=fixture()
    for id=1,500 do flood.Remotes.Action.OnServerEvent:Fire(flood.Player,{Action="SpawnScooter",Payload={},RequestId=id}) end
    check(flood.Calls.Spawn==GameConfig.ActionBurst,"action burst bounded")
    for _=1,500 do flood.Remotes.Input.OnServerEvent:Fire(flood.Player,{Throttle=1,Steer=0,Brake=false,Jump=false}) end
    check(flood.Calls.Input==GameConfig.InputBurst,"input burst bounded independently")
    flood.Context.IsClosing=true
    flood.Tick(10)
    flood.Remotes.Action.OnServerEvent:Fire(flood.Player,{Action="SpawnScooter",Payload={},RequestId=501})
    check(flood.Calls.Spawn==GameConfig.ActionBurst,"closing gates mutations")
    flood.Context.IsClosing=false
    flood.Remove()
    flood.Remotes.Action.OnServerEvent:Fire(flood.Player,{Action="SpawnScooter",Payload={},RequestId=1})
    check(flood.Calls.Spawn==GameConfig.ActionBurst+1,"player cleanup removes rate/history state")
    local foundation=fixture()
    foundation.Context.Config.Game.FoundationOnly=true
    for id,action in {"SpawnScooter","DespawnScooter","DismountScooter"} do
        foundation.Remotes.Action.OnServerEvent:Fire(foundation.Player,{Action=action,Payload={},RequestId=id})
    end
    foundation.Remotes.Input.OnServerEvent:Fire(foundation.Player,{Throttle=1,Steer=0,Brake=false,Jump=false})
    check(foundation.Calls.Spawn==0 and foundation.Calls.Despawn==0 and foundation.Calls.Dismount==0 and foundation.Calls.Input==0,"phase 0 disables gameplay even through valid legacy remotes")
    foundation.Remotes.Action.OnServerEvent:Fire(foundation.Player,{Action="SetSetting",Payload={Name="UIScale",Value=1.25},RequestId=4})
    check(foundation.Profile.Settings.UIScale==1.25,"phase 0 still validates settings")
    foundation.Remotes.Action.OnServerEvent:Fire(foundation.Player,{Action="Sync",Payload={},RequestId=5})
    check(foundation.Calls.Sync==1,"phase 0 provides a real state synchronization endpoint")
    local zone=fixture()
    local routed={Shoot=0,Reload=0,Revive=0,Sell=0,Squad=0,Cosmetic=0,Charge=0}
    local services=zone.Context.Services
    services.Quests=nil
    services.Combat={Shoot=function(_,p,payload) assert(p==zone.Player and payload.X==1);routed.Shoot+=1;return true,"" end}
    services.Equipment={Reload=function() routed.Reload+=1;return true,"" end}
    services.Revive={Hold=function(_,_,id) assert(id==8500000000);routed.Revive+=1;return true,"" end}
    services.Fishing={Sell=function(_,_,index,revision) assert(index==0 and revision==7);routed.Sell+=1;return true,"FishSold" end}
    services.Squad={Action=function(_,_,action,id) assert(action=="InviteSquad" and id==8500000000);routed.Squad+=1;return true,"SquadInvited" end}
    services.Cosmetics={Buy=function(_,_,category,option) assert(category=="Color" and option=="Mint");routed.Cosmetic+=1;return true,"CosmeticPurchased" end}
    services.Scooter.Charge=function() routed.Charge+=1;return true,"Charged" end
    local nextId=0
    local function action(name,payload) nextId+=1;zone.Remotes.Action.OnServerEvent:Fire(zone.Player,{Action=name,Payload=payload or {},RequestId=nextId}) end
    action("Shoot",{X=1,Y=0,Z=0,Aim=false,Damage=999})
    action("Shoot",{X=0/0,Y=0,Z=0,Aim=false})
    action("HoldRevive",{TargetId=8500000000,Health=100})
    action("SellFish",{Index=0,Revision=7,Price=999})
    check(routed.Shoot==0 and routed.Revive==0 and routed.Sell==0,"zone payloads reject forged damage, health, sale price and NaN")
    action("Shoot",{X=1,Y=0,Z=0,Aim=false})
    action("Shoot",{X=1,Y=0,Z=0,Aim=false})
    check(routed.Shoot==1,"shoot cooldown cannot be bypassed with fresh request IDs")
    zone.Tick(0.1);action("Shoot",{X=1,Y=0,Z=0,Aim=false})
    check(routed.Shoot==2 and zone.Calls.Notify==0,"valid shooting routes without full immediate snapshot spam")
    action("Reload");action("HoldRevive",{TargetId=8500000000});action("SellFish",{Index=0,Revision=7})
    action("InviteSquad",{TargetId=8500000000});action("BuyCosmetic",{Category="Color",Option="Mint"});action("ChargeScooter")
    check(routed.Reload==1 and routed.Revive==1 and routed.Sell==1 and routed.Squad==1 and routed.Cosmetic==1 and routed.Charge==1,"new zone intents route to their authoritative services")
    local before=zone.Calls.Feedback
    action("StartQuest",{QuestId="first_delivery"})
    check(zone.Calls.Feedback==before+1 and zone.Calls.Quest==0,"inactive legacy quest endpoint is rejected without runtime failure")
    services.PlayerData.IsReady=function() return false end
    zone.Tick(1);action("Shoot",{X=1,Y=0,Z=0,Aim=false})
    check(routed.Shoot==2,"unloaded profile cannot shoot")
    print("Network abuse checks passed: "..checks)
end
