--!nonstrict
-- Instance/signal boundary only; no Roblox layout, renderer or input dispatch is emulated.
local M = require("./RuntimeMocks")
local Mock = {}
local methods = {}
function methods:GetChildren()
    local out = {}; for _, child in self.Children do if not child.Destroyed then table.insert(out, child) end end; return out
end
function methods:FindFirstChild(name) for _, child in self:GetChildren() do if child.Name == name then return child end end end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name), name) end
function methods:FindFirstChildOfClass(name) for _, child in self:GetChildren() do if child.ClassName == name then return child end end end
function methods:IsA(name) return self.ClassName == name or name == "BasePart" and self.ClassName == "Part" end
function methods:Destroy() self.Destroyed = true end
function methods:GetPropertyChangedSignal(name)
    if not self.Signals[name] then self.Signals[name] = M.Signal() end
    return self.Signals[name]
end
local mt = {__index = function(o,k) return methods[k] or o.Properties[k] end,
    __newindex = function(o,k,v) o.Properties[k] = v; if k == "Parent" and v then table.insert(v.Children,o) end end}
function Mock.World(width,height,touch)
    local objects = {}
    local instance = {new = function(class)
        local value = setmetatable({ClassName = class, Children = {}, Signals = {}, Properties = {
            Name=class, Visible=true, Scale=1, AbsoluteSize=M.V(width,height,0), Activated=M.Signal(), InputBegan=M.Signal(), InputEnded=M.Signal()}}, mt)
        table.insert(objects,value); return value
    end}
    local gui = instance.new("PlayerGui")
    local head = instance.new("Part");head.Name,head.Position="Head",M.V(0,3,0)
    local root = instance.new("Part");root.Name,root.Position,root.AssemblyLinearVelocity="HumanoidRootPart",M.V(0,3,0),M.V(0,0,0)
    local character = instance.new("Model");head.Parent,root.Parent=character,character
    local player = instance.new("Player");player.UserId,player.Character=1,character;gui.Parent=player
    local camera={ViewportSize=M.V(width,height,0),FieldOfView=70,Parent=true,
        GetPropertyChangedSignal=function() return M.Signal() end,
        ViewportPointToRay=function() return {Origin=M.V(0,3,0),Direction=M.V(1,0,0)} end}
    local workspace={CurrentCamera=camera,GetPropertyChangedSignal=function() return M.Signal() end,Raycast=function() return nil end}
    local input={TouchEnabled=touch,InputBegan=M.Signal(),InputEnded=M.Signal(),WindowFocusReleased=M.Signal(),
        GetFocusedTextBox=function() return nil end,GetMouseLocation=function() return M.V(width/2,height/2,0) end}
    local run={Heartbeat=M.Signal(),RenderStepped=M.Signal()}
    local game={GetService=function(_,name) return ({Players={LocalPlayer=player},Workspace=workspace,UserInputService=input,RunService=run,
        HttpService={JSONEncode=function() return "fixture-key" end},GuiService={GetGuiInset=function() return M.V(0,0,0) end}})[name] end}
    local delayed={}
    local task={delay=function(_,fn) table.insert(delayed,fn) end}
    local enum=setmetatable({}, {__index=function(t,k) local group=setmetatable({}, {__index=function(_,v) return k..":"..v end});rawset(t,k,group);return group end})
    local function udim(scale,offset) return {Scale=scale,Offset=offset} end
    local udim2={new=function(xs,xo,ys,yo) return {X=udim(xs,xo),Y=udim(ys,yo)} end}
    udim2.fromOffset=function(x,y) return udim2.new(0,x,0,y) end
    udim2.fromScale=function(x,y) return udim2.new(x,0,y,0) end
    local color={new=function(r,g,b) return {R=r,G=g,B=b} end,fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
    local function find(name) for _,o in objects do if o.Name==name and not o.Destroyed then return o end end end
    local function button(text) for _,o in objects do if o.ClassName=="TextButton" and o.Text==text and not o.Destroyed then return o end end end
    return {Game=game,Gui=gui,Player=player,Camera=camera,Input=input,Run=run,Instance=instance,Task=task,Enum=enum,UDim2=udim2,UDim={new=udim},Color3=color,
        Vector2={new=function(x,y) return M.V(x,y,0) end,zero=M.V(0,0,0)},Find=find,Button=button,Delayed=delayed}
end
return Mock
