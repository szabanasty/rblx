--!nonstrict
-- Minimal deterministic API boundaries; production modules are loaded unchanged.
local Mocks = {}
function Mocks.Signal()
    local signal = {Connections = {}}
    function signal:Connect(callback)
        local connection = {Callback = callback, Connected = true}
        function connection:Disconnect() self.Connected = false end
        table.insert(self.Connections, connection)
        return connection
    end
    function signal:Fire(...)
        for _, connection in table.clone(self.Connections) do if connection.Connected then connection.Callback(...) end end
    end
    return signal
end
local vector = {}
vector.__index = function(value, key)
    if key == "Magnitude" then return math.sqrt(value.X^2 + value.Y^2 + value.Z^2) end
    if key == "Unit" then return value / value.Magnitude end
    return vector[key]
end
function Mocks.V(x, y, z) return setmetatable({X=x,Y=y,Z=z},vector) end
function vector.__add(a,b) return Mocks.V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vector.__sub(a,b) return Mocks.V(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vector.__mul(a,b) if type(a)=="number" then return b*a end; return Mocks.V(a.X*b,a.Y*b,a.Z*b) end
function vector.__div(a,b) return Mocks.V(a.X/b,a.Y/b,a.Z/b) end
function vector:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
Mocks.Vector3={new=Mocks.V,zero=Mocks.V(0,0,0)}
Mocks.Random={new=function() return {NextNumber=function(_,a,b) return if a then (a+b)/2 else 0.1 end,NextInteger=function(_,a) return a end} end}
Mocks.Params={new=function() return {} end}
Mocks.Enum={RaycastFilterType={Exclude="Exclude"}}
function Mocks.World()
    local now=100
    local players={PlayerAdded=Mocks.Signal(),PlayerRemoving=Mocks.Signal(),List={}}
    function players:GetPlayers() return self.List end
    function players:GetPlayerByUserId(id) for _,p in self.List do if p.UserId==id then return p end end end
    function players:GetPlayerFromCharacter(character) for _,p in self.List do if p.Character==character then return p end end end
    local run={Heartbeat=Mocks.Signal()}
    local workspace={Hit=nil,Blocked=false}
    function workspace:Raycast(origin,direction,params)
        if self.Blocked then return {Position=origin+direction*0.2,Instance={CanCollide=true,FindFirstAncestorOfClass=function() return nil end}} end
        if self.Hit and not (params and table.find(params.FilterDescendantsInstances or {},self.Hit.Character)) and (self.Hit.Character.Head.Position-origin).Magnitude<=direction.Magnitude then
            return {Position=self.Hit.Character.Head.Position,Instance={CanCollide=true,FindFirstAncestorOfClass=function() return self.Hit.Character end}}
        end
        return nil
    end
    function workspace:WaitForChild() return {} end
    local sequence=0
    local http={GenerateGUID=function() sequence+=1;return "guid-"..sequence end}
    local game={GetService=function(_,name) return ({Players=players,RunService=run,Workspace=workspace,HttpService=http})[name] end}
    local clock={clock=function() return now end,time=function() return 1700000000+now end}
    local function player(id,x)
        local character={Head={Position=Mocks.V(x,3,0),IsA=function() return true end}}
        character.HumanoidRootPart={Position=Mocks.V(x,3,0),IsA=function() return true end,AssemblyLinearVelocity=Mocks.V(0,0,0)}
        function character:FindFirstChild(name) return self[name] end
        local result={UserId=id,Name="Player"..id,Character=character,Parent=players,CharacterAdded=Mocks.Signal()}
        table.insert(players.List,result)
        return result
    end
    return {Game=game,Players=players,Workspace=workspace,Run=run,Clock=clock,Player=player,
        Tick=function(dt) now+=dt;run.Heartbeat:Fire(dt) end,Now=function() return now end}
end
return Mocks
