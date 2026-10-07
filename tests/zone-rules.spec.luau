--!nonstrict
return function(StateRules, ZoneRules, SquadStore, FishingRules, CombatConfig, ZoneConfig, FishingConfig, Validation)
    local checks=0
    local function check(ok, message) assert(ok,message);checks+=1 end
    local state=StateRules.New(100)
    check(not StateRules.CanAct(state,"Shoot",0),"unloaded avatar cannot shoot")
    state.Ready,state.Area=true,"SafeZone"
    check(StateRules.State(state,0)=="SAFE" and not StateRules.CanAct(state,"Target",0),"safe protection is server state")
    state.Area="CombatZone"
    check(StateRules.CanAct(state,"Shoot",0) and StateRules.CanAct(state,"Target",0),"combat participation valid")
    check(not StateRules.Damage(state,25,0,CombatConfig) and state.Health==75,"nonlethal damage")
    state.Area="SafeZone"
    check(StateRules.State(state,1)=="COMBAT" and StateRules.CanAct(state,"Target",1) and not StateRules.CanAct(state,"Trade",1),"safe boundary cannot clear combat tag")
    check(StateRules.Damage(state,100,2,CombatConfig) and state.DownedUntil==62,"lethal damage starts exact downed window")
    for _,kind in {"Shoot","Drive","Trade","Fish","Squad","Target"} do check(not StateRules.CanAct(state,kind,3),"downed action denied: "..kind) end
    check(StateRules.Revive(state,7,CombatConfig) and state.Health==35 and state.ProtectedUntil==9,"revive restores limited health and protection")
    check(not StateRules.Revive(state,8,CombatConfig),"repeat revive cannot restore health again")
    check(not StateRules.CanAct(state,"Target",8) and StateRules.CanAct(state,"Target",10),"temporary protection expires")
    state.Fishing=true;state.Area="FishingArea";state.TaggedUntil=0
    check(StateRules.State(state,30)=="FISHING" and not StateRules.CanAct(state,"Shoot",30),"fishing locks combat")
    check(ZoneRules.At({X=0,Y=3,Z=0},ZoneConfig)=="SafeZone","spawn inside safe")
    check(ZoneRules.At({X=1050,Y=3,Z=0},ZoneConfig)=="CombatZone","combat geometry bounds")
    check(ZoneRules.At({X=-340,Y=3,Z=355},ZoneConfig)=="FishingArea","dock inside fishing")
    check(ZoneRules.At({X=0,Y=200,Z=0},ZoneConfig)=="City","vertical bounds prevent sky-safe flag")
    check(ZoneRules.At({X=520,Y=3,Z=0},ZoneConfig)=="City" and ZoneRules.At({X=750,Y=3,Z=0},ZoneConfig)=="City","bridge and approach stay outside the distant combat boundary")
    local squad=SquadStore.new(4)
    check(squad:Create(1) and not squad:Create(1),"one membership per player")
    for id=2,4 do check(squad:Invite(1,id,0) and squad:Accept(id,1),"server invite acceptance "..id) end
    check(squad:Same(1,4) and not squad:Invite(1,5,1),"four member cap")
    check(not squad:Kick(2,3) and not squad:Kick(1,1),"only leader can kick another member")
    check(squad:Leave(1) and squad.Squads[squad.Membership[2]].Leader==2,"leader ownership transfers on leave")
    check(squad:Invite(2,5,1) and not squad:Accept(5,32),"invite expires server-side")
    check(squad:Kick(2,4) and not squad.Membership[4],"kick removes membership")
    local Mocks=require("../RuntimeMocks")
    local fish=FishingRules.Roll(Mocks.Random.new(),FishingConfig)
    check(fish and fish.Rarity=="COMMON" and FishingRules.Value(fish,FishingConfig)>0,"server RNG uses catalog")
    check(FishingRules.Value({FishId="river_fish",Weight=100,Rarity="COMMON"},FishingConfig)==nil,"forged weight rejected")
    check(FishingRules.Value({FishId="river_fish",Weight=1,Rarity="LEGENDARY"},FishingConfig)==nil,"forged rarity rejected")
    for _,aim in {{X=0,Y=0,Z=0,Aim=false},{X=math.huge,Y=0,Z=0,Aim=false},{X=1,Y=0,Z=0,Aim=false,Damage=999}} do
        check(not Validation.ParseAction({Action="Shoot",Payload=aim,RequestId=1}),"invalid/extra aim cannot reach combat")
    end
    check(Validation.ParseAction({Action="Shoot",Payload={X=1,Y=0,Z=0,Aim=false},RequestId=1})~=nil,"normalized aim intent accepted")
    check(not Validation.ParseAction({Action="SellFish",Payload={Index=0,Revision=1,Money=999},RequestId=1}),"client cannot declare fish price")
    check(Validation.ParseAction({Action="InviteSquad",Payload={TargetId=8500000000},RequestId=1})~=nil,"modern Roblox user IDs above int32 supported")
    print("Zone rules checks passed: "..checks)
end
