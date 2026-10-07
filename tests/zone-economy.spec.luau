--!nonstrict
return function(loadService,Schema,GameConfig,RewardConfig,LevelConfig,EconomyConfig,Progression)
    local Mocks=require("../RuntimeMocks")
    local world=Mocks.World()
    local profile=Schema.new(1,GameConfig)
    local ready=true
    local instance={new=function(class)
        local value={Children={},Name=""}
        function value:IsA(other) return class==other end
        function value:FindFirstChild(name) return self.Children[name] end
        return value
    end}
    local player={UserId=1,FindFirstChild=function() return nil end}
    local service=loadService(world.Game,instance)
    service:Init({Config={Rewards=RewardConfig,Levels=LevelConfig,Economy=EconomyConfig},Progression=Progression,Notify=function() end,
        Services={PlayerData={IsReady=function() return ready end,GetProfile=function() return if ready then profile else nil end,MarkDirty=function() end}}})
    local checks=0
    local function check(ok,message) assert(ok,message);checks+=1 end
    check(service:Credit(player,100,"PvP","one") and profile.Money==200,"exact validated credit")
    check(not service:Credit(player,100,"PvP","one") and profile.Money==200,"credit receipt blocks replay")
    check(not service:Credit(player,-10,"PvP","bad") and not service:Credit(player,0/0,"PvP","nan"),"nonpositive/nonfinite currency denied")
    check(not service:Credit(player,1,"Robux","source"),"unknown source denied")
    check(not service:Credit(player,EconomyConfig.SourceCaps.Fishing+1,"Fishing","over") and profile.Money==200,"exact sale cannot silently truncate")
    check(service:Credit(player,EconomyConfig.SourceCaps.Fishing,"Fishing","sale"),"independent source budget")
    check(not service:Credit(player,1,"Fishing","over2"),"source daily cap enforced")
    ready=false
    check(not service:Credit(player,1,"Objective","load"),"lost profile cannot receive or spend currency")
    ready=true;profile.Money=GameConfig.MaxCurrency
    check(not service:Credit(player,1,"Objective","max"),"maximum balance protected")
    print("Zone exact economy checks passed: "..checks)
end
