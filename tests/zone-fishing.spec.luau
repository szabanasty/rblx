--!nonstrict
return function(loadService,Schema,GameConfig,FishingConfig,FishingRules)
    local M=require("../RuntimeMocks")
    local world=M.World()
    local player=world.Player(1,0)
    local profile=Schema.new(1,GameConfig)
    local record={Fishing=false,TaggedUntil=0}
    local near,allowed,canCredit=true,true,true
    local ctx={Config={Fishing=FishingConfig},FishingRules=FishingRules,Notify=function() end,Feedback=function() end,Services={}}
    ctx.Services.PlayerData={GetProfile=function() return profile end,MarkDirty=function() end}
    ctx.Services.State={GetRecord=function() return record end,Changed=function() end,IsAllowed=function(_,_,kind) return allowed and (kind~="Drive" or not record.Fishing) end}
    ctx.Services.World={IsNear=function() return near end}
    ctx.Services.Scooter={GetTelemetry=function() return {Riding=false} end}
    local credits={}
    ctx.Services.Economy={Credit=function(_,_,amount,_,receipt) if not canCredit then return false,"DailyLimit" end;assert(not credits[receipt]);credits[receipt]=true;profile.Money+=amount;return true,"Granted" end,Reward=function() return true,"Granted" end}
    local service=loadService(world.Game,M.Random,world.Clock)
    service:Init(ctx);service:Start()
    local checks=0
    local function check(ok,msg) assert(ok,msg);checks+=1 end
    near=false;check(not service:Toggle(player),"cannot start fishing remotely")
    near=true;check(service:Toggle(player) and record.Fishing,"server starts automatic session")
    world.Tick(24)
    local snapshot=service:GetSnapshot(player)
    check(#profile.FishingInventory==1 and snapshot.Active and snapshot.Inventory[1].Value>0,"elapsed server timer generates catalog fish without client claim")
    check(not service:Sell(player,0,snapshot.Revision),"fishing locks buyer trade")
    service:Stop(player)
    local revision=snapshot.Revision
    local amount=snapshot.Inventory[1].Value
    canCredit=false
    check(not service:Sell(player,0,revision) and #profile.FishingInventory==1,"failed/capped credit preserves inventory")
    canCredit=true
    check(service:Sell(player,0,revision) and #profile.FishingInventory==0 and profile.Money==100+amount,"sale uses server value and removes exactly sold fish")
    check(not service:Sell(player,0,revision) and profile.Money==100+amount,"stale revision blocks sale replay")
    profile.FishingInventory={{FishId="river_fish",Weight=1,Rarity="COMMON"},{FishId="blue_pike",Weight=2,Rarity="RARE"}}
    snapshot=service:GetSnapshot(player)
    check(service:Sell(player,2,snapshot.Revision) and #profile.FishingInventory==1 and profile.FishingInventory[1].FishId=="river_fish","selected sale preserves other fish")
    service:Toggle(player);near=false;world.Tick(0.5)
    check(not service:GetSnapshot(player).Active and not record.Fishing,"leaving dock stops automatic income")
    near=true;profile.FishingInventory={}
    for _=1,FishingConfig.InventoryLimit do table.insert(profile.FishingInventory,{FishId="river_fish",Weight=1,Rarity="COMMON"}) end
    check(not service:Toggle(player),"full inventory cannot start")
    profile.FishingInventory={};allowed=false
    check(not service:Toggle(player),"invalid/downed state cannot fish")
    allowed=true;service:Toggle(player);world.Tick(FishingConfig.MaximumSessionSeconds+1)
    check(not service:GetSnapshot(player).Active and #profile.FishingInventory==0,"AFK session ends rather than catching backlog")
    print("Zone automatic fishing/atomic sale checks passed: "..checks)
end
