--!nonstrict
return function(loadMount)
    local M=require("../SceneMock")
    local world=M.World()
    local blocked=false
    function world.Workspace:Raycast() return if blocked then {Instance={}} else nil end
    local humanoid={Health=100,Enabled=false,SetStateEnabled=function(self,_,value) self.Enabled=value end}
    local root={Position=M.V(0,3,0),IsA=function(_,name) return name=="BasePart" end}
    local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end,
        PivotTo=function(_,cf) root.Position=cf.Position end}
    local player={UserId=1,Character=character}
    local owner=1
    local model={GetAttribute=function() return owner end}
    local sits=0
    local seat={Position=M.V(10,2.5,0),CFrame=M.CFrame.new(10,2.5,0),Disabled=false,
        Sit=function(self,h) sits+=1;h.SeatPart=self;self.Occupant=h end}
    local assembly={Model=model,Root={Position=M.V(10,1.1,0)},Seat=seat}
    local ready,allowed=true,true
    local trustedPosition
    local ctx={Services={PlayerData={IsReady=function() return ready end},State={IsAllowed=function() return allowed end},Movement={AllowTeleport=function(_,p,pos) assert(p==player);trustedPosition=pos end}}}
    local mount=loadMount(world.Game,M.CFrame,{new=function() return {} end},M.Enum)
    local checks=0
    local function check(ok,msg) assert(ok,msg);checks+=1 end
    owner=-1;check(not mount.Try(player,assembly,ctx) and sits==0,"showroom and other-owner scooters cannot mount")
    owner=1;ready=false;check(not mount.Try(player,assembly,ctx),"unloaded profile rejected")
    ready=true;allowed=false;check(not mount.Try(player,assembly,ctx),"downed/fishing/state lock rejected")
    allowed=true;seat.Disabled=true;check(not mount.Try(player,assembly,ctx),"disabled display seat rejected")
    seat.Disabled=false;blocked=true;check(not mount.Try(player,assembly,ctx),"cannot seat through a shop wall")
    blocked=false;root.Position=M.V(100,3,0);check(not mount.Try(player,assembly,ctx),"mount cannot teleport a distant player")
    root.Position=M.V(0,3,0)
    check(mount.Try(player,assembly,ctx) and sits==1 and humanoid.Enabled,"eligible native seat request made once")
    check(trustedPosition==root.Position and root.Position.X==10,"authorized relocation registered with movement guard before seating")
    check(mount.Try(player,assembly,ctx) and sits==1,"already seated request is idempotent")
    seat.Occupant=nil;humanoid.SeatPart={}
    check(not mount.Try(player,assembly,ctx),"cannot steal a player from another vehicle")
    print("Scooter mount checks passed: "..checks)
end
