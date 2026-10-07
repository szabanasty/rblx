--!nonstrict
return function(loadService, Schema, Progression, GameConfig, ScooterConfig, LevelConfig)
    local players={GetPlayers=function() return {} end}
    local player={UserId=123,Parent=players}
    local profile=Schema.new(123,GameConfig)
    profile.Secret="internal"
    profile.IdempotencyLedger.secret_receipt=100
    profile.ScooterUpgrades.kukirin_g2={Motor=1}
    local sent=nil
    local service=loadService({GetService=function(_,name)
        if name=="Players" then return players end
        return {IsStudio=function() return true end}
    end})
    local ctx={
        Config={Game=GameConfig,Scooters=ScooterConfig,Levels=LevelConfig},Progression=Progression,Schema=Schema,
        Remotes={Snapshot={FireClient=function(_,recipient,value) assert(recipient==player);sent=value end}},
        Services={
            PlayerData={GetProfile=function() return profile end,GetStatus=function() return "StudioMemory" end},
            Scooter={GetTelemetry=function() return {Speed=35,Distance=250,ScooterId="kukirin_g2",Riding=true,Suspicion=10} end,GetPosition=function() return nil end},
        },
    }
    service:Init(ctx);service:Send(player)
    assert(sent.Ready and sent.Money==100 and sent.SaveMode=="StudioMemory")
    assert(sent.Secret==nil and sent.IdempotencyLedger==nil and sent.Telemetry.Suspicion==nil)
    sent.Settings.UIScale=1.5
    assert(profile.Settings.UIScale==1,"projection cannot mutate source settings")
    sent.ScooterUpgrades.kukirin_g2.Motor=99
    assert(profile.ScooterUpgrades.kukirin_g2.Motor==1,"projection cannot mutate source upgrades")
    profile=nil
    service:Send(player)
    assert(sent.Ready==false and sent.Money==nil,"loading snapshot does not invent profile")
    print("Snapshot projection checks passed")
end
