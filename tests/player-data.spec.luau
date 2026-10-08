--!nonstrict
-- Real service code is provided by the test runner; Roblox services are modeled below.
return function(loadService, RealSchema, GameConfig)
local checks = 0
local function check(ok, message)
    assert(ok, message)
    checks += 1
end
local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in value do output[key] = deepCopy(item) end
    return output
end
local function factory(studio, existing, useRealSchema)
    local clock = 1000
    local os = {time = function() return math.floor(clock) end, clock = function() return clock end}
    local timers = {}
    local task = {}
    function task.wait(seconds)
        local duration = seconds or 0
        return coroutine.yield(duration)
    end
    function task.spawn(fn, ...)
        local co = coroutine.create(fn)
        local ok, delay = coroutine.resume(co, ...)
        assert(ok, tostring(delay))
        if coroutine.status(co) ~= "dead" then
            table.insert(timers, {Thread = co, At = clock + (delay or 0)})
        end
        return co
    end
    local function advance(seconds)
        local target = clock + seconds
        local iterations = 0
        while true do
            local index = nil
            for idx, timer in timers do
                if timer.At <= target and (not index or timer.At < timers[index].At) then index = idx end
            end
            if not index then break end
            iterations += 1
            assert(iterations < 10000, "timer runaway")
            local timer = table.remove(timers,index)
            clock = timer.At
            local ok,delay = coroutine.resume(timer.Thread)
            assert(ok,tostring(delay))
            if coroutine.status(timer.Thread) ~= "dead" then
                table.insert(timers,{Thread=timer.Thread,At=clock+(delay or 0.1)})
            end
        end
        clock=target
    end
    local function event()
        local out = {Callbacks={}}
        function out:Connect(fn) table.insert(self.Callbacks,fn) end
        function out:Fire(...)
            for _, fn in self.Callbacks do task.spawn(fn,...) end
        end
        return out
    end
    local players = {PlayerAdded=event(), PlayerRemoving=event(), List={}}
    function players:GetPlayers() return self.List end
    local guid=0
    local records = deepCopy(existing or {})
    local store={Failures=0,Calls=0,Record=records,LostResponse=false}
    function store:UpdateAsync(key,callback)
        self.Calls += 1
        if self.Failures > 0 then self.Failures -= 1; error("DataStore request failed") end
        local value=callback(deepCopy(records[key]))
        if value ~= nil then records[key]=deepCopy(value) end
        if self.LostResponse then self.LostResponse=false; error("response timed out after commit") end
        return deepCopy(value)
    end
    local services={
        Players=players,
        DataStoreService={GetDataStore=function() return store end},
        HttpService={GenerateGUID=function() guid+=1; return "test_guid_"..guid end},
        RunService={IsStudio=function() return studio end},
    }
    local warnings={}
    local function warn(value) table.insert(warnings,value) end
    local game={GetService=function(_,name) return services[name] end,BindToClose=function() end}
    local service=loadService(game, task, warn, os)
    local schema={}
    function schema.new(userId,config) return {SchemaVersion=1,UserId=userId,Money=config.StartingMoney} end
    function schema.sanitize(profile)
        if type(profile) ~= "table" or profile.SchemaVersion ~= 1 then return nil,"invalid" end
        return deepCopy(profile)
    end
    schema.deepCopy=deepCopy
    local notifications=0
    local ctx={Config={Game={DataStoreName="Tests",UseStudioDataStore=false,StartingMoney=100}},Schema=schema,Notify=function() notifications+=1 end}
    if useRealSchema then
        ctx.Schema=RealSchema; ctx.Config.Game=table.clone(GameConfig)
        ctx.Config.Game.DataStoreName="Tests"; ctx.Config.Game.UseStudioDataStore=false
    end
    service:Init(ctx)
    service:Start()
    local function add(userId)
        local player={UserId=userId,Parent=players,Kicked=nil}
        function player:Kick(message) self.Kicked=message end
        players.PlayerAdded:Fire(player)
        return player
    end
    return {Service=service,Store=store,Records=records,Add=add,Advance=advance,Task=task,Players=players,Context=ctx,Warnings=warnings}
end

local a=factory(false)
local p=a.Add(42)
check(a.Service:IsReady(p),"production default profile acquired")
check(a.Service:IsPersistent(p),"production usable profile qualifies for durable receipt processing")
check(a.Records.Player_42.Data.Money==100,"initial profile stored")
check(a.Records.Player_42.Session ~= nil,"session lease stored")
a.Service:GetProfile(p).Money=240
a.Service:MarkDirty(p)
local saved=a.Service:Save(p,false)
check(saved and a.Records.Player_42.Data.Money==240,"autosave updates profile")
local token=a.Records.Player_42.Session.Token
a.Advance(61)
check(a.Records.Player_42.Session.Token==token and a.Records.Player_42.Session.ExpiresAt>1180,"unchanged profile renews lease")
check(a.Service:Save(p,true),"release succeeds")
check(a.Records.Player_42.Session==nil,"release removes lease")
check(a.Service:Save(p,true),"duplicate release idempotent")

local b=factory(false,{Player_45={SchemaVersion=1,Data={SchemaVersion=1,UserId=45,Money=900},Session={Token="other",ExpiresAt=2000}}})
local q=b.Add(45)
b.Advance(12)
check(not b.Service:IsReady(q) and q.Kicked ~=nil,"active foreign lease fails closed")
check(b.Records.Player_45.Data.Money==900 and b.Records.Player_45.Session.Token=="other","blocked load preserves record")

local c=factory(false,{Player_46={SchemaVersion=2,Data={SchemaVersion=2,UserId=46,Money=777}}})
local r=c.Add(46)
check(r.Kicked ~=nil and not c.Service:IsReady(r),"future schema rejected")
check(c.Records.Player_46.Data.Money==777,"future record preserved")

local d=factory(false)
d.Store.Failures=99
local s=d.Add(47)
d.Advance(20)
check(s.Kicked ~=nil and d.Records.Player_47==nil,"failed load never writes defaults")

local e=factory(false)
local t=e.Add(48)
e.Records.Player_48.Session.Token="stolen"
local success,reason=e.Service:Save(t,false)
check(not success and reason=="SessionLost" and t.Kicked~=nil,"stolen token stops gameplay")
check(not e.Service:IsPersistent(t),"lost lease cannot authorize consumable purchases")
check(e.Records.Player_48.Session.Token=="stolen","stolen lease never overwritten")

local f=factory(true)
local u=f.Add(49)
check(f.Service:GetStatus(u)=="StudioMemory" and f.Service:IsReady(u),"Studio memory test usable")
check(not f.Service:IsPersistent(u),"memory-only session never qualifies for durable receipt processing")
check(f.Store.Calls==0 and #f.Warnings>0,"Studio default never touches production DataStore")

local g=factory(false)
local v=g.Add(50)
g.Service:GetProfile(v).Money=333
g.Store.LostResponse=true
local releaseOk=false
g.Task.spawn(function() releaseOk=g.Service:Save(v,true) end)
g.Advance(2)
check(releaseOk and g.Records.Player_50.Data.Money==333 and g.Records.Player_50.Session==nil,"uncertain release retry safely recognized")

local h=factory(false,{Player_51={SchemaVersion=1,Data={SchemaVersion=1,UserId=999,Money=555}}})
local w=h.Add(51)
check(w.Kicked~=nil and h.Records.Player_51.Data.Money==555,"mismatched owner record not loaded or overwritten")

local i=factory(false)
i.Store.LostResponse=true
local x=i.Add(52)
x.Parent=nil
i.Players.PlayerRemoving:Fire(x)
i.Advance(2)
check(i.Records.Player_52.Session==nil,"departing player releases an uncertain acquired lease")
check(not i.Service:IsReady(x),"departing player cannot access profile")

local j=factory(false)
local y=j.Add(53)
j.Service:GetProfile(y).Money=456
j.Task.spawn(function() j.Service:Shutdown() end)
j.Advance(1)
check(j.Records.Player_53.Data.Money==456 and j.Records.Player_53.Session==nil,"shutdown saves and releases loaded profiles")
check(j.Context.IsClosing==true,"shutdown signals closing to other services")

local history=RealSchema.new(54,GameConfig)
history.UpgradeCredits=300
for index=1,300 do history.PurchaseReceipts["real-receipt-"..index]=true end
local envelope={SchemaVersion=1,Data=history,Session={Token="old",ExpiresAt=900}}
local envelopeCopy=RealSchema.deepCopy(envelope)
local receipts=0;for _ in envelopeCopy.Data.PurchaseReceipts do receipts+=1 end
check(receipts==300,"real schema preserves full purchase history inside DataStore envelope")
local k=factory(false,{Player_54=envelope},true)
k.Store.LostResponse=true
local z=k.Add(54)
z.Parent=nil;k.Players.PlayerRemoving:Fire(z);k.Advance(2)
receipts=0;for _ in k.Records.Player_54.Data.PurchaseReceipts do receipts+=1 end
check(receipts==300 and k.Records.Player_54.Data.UpgradeCredits==300 and k.Records.Player_54.Session==nil,
    "uncertain acquisition release with actual schema keeps every permanent purchase receipt")

print("PlayerDataService mock checks passed: "..checks)

end
