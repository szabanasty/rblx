--!nonstrict
return function(loadService)
    local M=require("../RuntimeMocks")
    local players={PlayerAdded=M.Signal(),PlayerRemoving=M.Signal()}
    local character={WaitForChild=function() return {} end}
    local player={Parent=players,Character=character,CharacterAdded=M.Signal(),CharacterAppearanceLoaded=M.Signal()}
    function players:GetPlayers() return {player} end
    local service=loadService({GetService=function() return players end},{spawn=function(fn) fn() end})
    local count=0
    -- Test actual lifecycle subscriptions; mesh/accessory rendering requires the engine.
    service.Refresh=function(_,target) assert(target==player);count+=1 end
    local ctx={IsClosing=false}
    service:Init(ctx);service:Start()
    assert(count==1,"existing player observed")
    player.CharacterAdded:Fire(character);assert(count==2,"fresh character observed")
    player.CharacterAppearanceLoaded:Fire(character);assert(count==3,"late appearance triggers reconciliation")
    player.CharacterAppearanceLoaded:Fire({});assert(count==3,"stale avatar load cannot refresh another character")
    players.PlayerAdded:Fire(player);player.CharacterAppearanceLoaded:Fire(character);assert(count==4,"duplicate observe cannot add duplicate callbacks")
    ctx.IsClosing=true;player.CharacterAppearanceLoaded:Fire(character);assert(count==4,"shutdown cannot add equipment")
    ctx.IsClosing=false;players.PlayerRemoving:Fire(player)
    player.CharacterAdded:Fire(character);player.CharacterAppearanceLoaded:Fire(character)
    assert(count==4,"both scoped subscriptions disconnected on departure")
    print("Avatar lifecycle checks passed: 7")
end
