--!nonstrict
-- Geometry API boundary, not a Roblox physics emulator. Export uses the actual world/factory code.
local Mock = {}
local Vec = {}
Vec.__index = function(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=="Unit" then return v/v.Magnitude end
    return Vec[k]
end
function Mock.V(x,y,z) return setmetatable({X=x,Y=y,Z=z},Vec) end
function Vec.__add(a,b) return Mock.V(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function Vec.__sub(a,b) return Mock.V(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function Vec.__mul(a,b) if type(a)=="number" then return b*a end;return Mock.V(a.X*b,a.Y*b,a.Z*b) end
function Vec.__div(a,b) return Mock.V(a.X/b,a.Y/b,a.Z/b) end
function Vec.__unm(a) return Mock.V(-a.X,-a.Y,-a.Z) end
function Vec:Dot(b) return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function Vec:Cross(b) return Mock.V(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X) end
local Frame={}
local identity={1,0,0,0,1,0,0,0,1}
local function frame(position,rotation) return setmetatable({P=position,R=rotation or identity},Frame) end
local function rotate(r,p) return Mock.V(r[1]*p.X+r[2]*p.Y+r[3]*p.Z,r[4]*p.X+r[5]*p.Y+r[6]*p.Z,r[7]*p.X+r[8]*p.Y+r[9]*p.Z) end
Frame.__index=function(f,k)
    if k=="Position" then return f.P elseif k=="Rotation" then return frame(Mock.V(0,0,0),f.R)
    elseif k=="LookVector" then return Mock.V(-f.R[3],-f.R[6],-f.R[9]) end
    return Frame[k]
end
function Frame.__mul(a,b)
    local result={}
    for i=0,2 do for j=0,2 do result[i*3+j+1]=a.R[i*3+1]*b.R[j+1]+a.R[i*3+2]*b.R[j+4]+a.R[i*3+3]*b.R[j+7] end end
    return frame(a.P+rotate(a.R,b.P),result)
end
Mock.CFrame={new=function(x,y,z) return frame(if type(x)=="table" then x else Mock.V(x or 0,y or 0,z or 0)) end}
function Mock.CFrame.Angles(x,y,z)
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return frame(Mock.V(0,0,0),{cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy})
end
function Mock.CFrame.lookAt(a,b)
    local back=(a-b).Unit;local right=Mock.V(0,1,0):Cross(back)
    if right.Magnitude<0.001 then right=Mock.V(1,0,0) else right=right.Unit end
    local up=back:Cross(right)
    return frame(a,{right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z})
end
Mock.Vector3={new=Mock.V,zero=Mock.V(0,0,0)}
Mock.Color3={new=function(r,g,b) return {R=r,G=g,B=b} end,fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
Mock.Enum=setmetatable({}, {__index=function(t,k) local category=setmetatable({}, {__index=function(_,v) return k.."."..v end});rawset(t,k,category);return category end})
Mock.UDim2={fromOffset=function(x,y) return {X=x,Y=y} end,fromScale=function(x,y) return {X=x,Y=y} end}
Mock.PhysicalProperties={new=function(...) return {...} end}
local function signal() return {Connect=function(_,fn) return {Disconnect=function() end,Callback=fn} end} end
local Methods={}
function Methods:GetAttribute(k) return self.Attributes[k] end
function Methods:SetAttribute(k,v) self.Attributes[k]=v end
function Methods:IsA(class) return self.ClassName==class or class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="VehicleSeat") end
function Methods:FindFirstChild(name) for _,child in self.Children do if child.Name==name and not child.Destroyed then return child end end end
function Methods:WaitForChild(name) return assert(self:FindFirstChild(name),name) end
function Methods:FindFirstChildOfClass(name) for _,child in self.Children do if child.ClassName==name then return child end end end
function Methods:GetChildren() local children={};for _,child in self.Children do if not child.Destroyed then table.insert(children,child) end end;return children end
function Methods:Destroy() self.Destroyed=true end
local Meta={__index=function(o,k)
    if Methods[k] then return Methods[k] end
    if k=="Position" then return o.Props.CFrame.Position end
    return o.Props[k]
end,__newindex=function(o,k,v)
    o.Props[k]=v
    if k=="Parent" and v then table.insert(v.Children,o) end
end}
function Mock.World()
    local objects={}
    local instance={new=function(class)
        local o=setmetatable({ClassName=class,Id=#objects+1,Children={},Attributes={},Props={Name=class,CFrame=Mock.CFrame.new(),Transparency=0,CastShadow=true,Size=Mock.V(1,1,1),Color=Mock.Color3.new(1,1,1)}},Meta)
        if class=="ProximityPrompt" then o.Triggered=signal() end
        table.insert(objects,o);return o
    end}
    local workspace=instance.new("Workspace")
    local map=instance.new("Folder");map.Name,map.Parent="Map",workspace
    local lighting=instance.new("Lighting")
    local players={PlayerRemoving=signal()}
    local game={GetService=function(_,k) return ({Workspace=workspace,Lighting=lighting,Players=players,CollectionService={AddTag=function() end}})[k] end}
    return {Objects=objects,Instance=instance,Game=game,Workspace=workspace,Lighting=lighting}
end
local function quoted(text) return '"'..text:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"' end
local function json(value)
    if type(value)=="string" then return quoted(value) elseif type(value)=="number" or type(value)=="boolean" then return tostring(value) elseif value==nil then return "null" end
    local result={}
    if #value>0 then for _,entry in value do table.insert(result,json(entry)) end;return '['..table.concat(result,',')..']' end
    for key,entry in value do table.insert(result,quoted(key)..':'..json(entry)) end;return '{'..table.concat(result,',')..'}'
end
function Mock.Export(world)
    local result={}
    for _,object in world.Objects do
        if object:IsA("BasePart") and not object.Destroyed then
            local cf,size,color=object.CFrame,object.Size,object.Color
            table.insert(result,{Id=object.Id,Name=object.Name,Parent=if object.Parent then object.Parent.Name else "",Position={cf.P.X,cf.P.Y,cf.P.Z},Rotation=cf.R,Size={size.X,size.Y,size.Z},Color={color.R,color.G,color.B},Material=object.Material,Transparency=object.Transparency,Shape=object.Shape or "PartType.Block",Solid=object.CanCollide==true,CastShadow=object.CastShadow==true})
        elseif object.ClassName=="TextLabel" and object.Parent and object.Parent.ClassName=="SurfaceGui" then
            table.insert(result,{Text=object.Text,Face=object.Parent.Face,Part=object.Parent.Parent.Id})
        end
    end
    print(json(result))
end
return Mock
