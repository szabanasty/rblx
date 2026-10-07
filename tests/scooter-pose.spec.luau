--!nonstrict
return function(loadPose)
    local M=require("../SceneMock")
    local world=M.World()
    local function make(class,name,parent) local obj=world.Instance.new(class);obj.Name,obj.Parent=name,parent;return obj end
    local character=make("Model","Character",nil)
    local humanoid=make("Humanoid","Humanoid",character)
    local root=make("Part","Chassis",nil)
    local external=make("IKControl","ExistingAvatarControl",humanoid)
    for _,side in {"Left","Right"} do
        for _,pair in {{"UpperLeg","Foot"},{"UpperArm","Hand"}} do
            make("Part",side..pair[1],character);make("Part",side..pair[2],character)
            make("Attachment",side..pair[2].."Target",root)
        end
    end
    local pose=loadPose(world.Instance,M.Enum)
    local player={Character=character}
    local checks=0
    local function check(ok,msg) assert(ok,msg);checks+=1 end
    pose.Apply(player,root)
    local count=0
    for _,control in humanoid:GetChildren() do
        if control:GetAttribute("ZoneScooterPose") then
            count+=1
            check(control.ChainRoot and control.EndEffector and control.Target and control.Weight==1,"procedural pose binds existing R15 chain to real scooter attachment")
        end
    end
    check(count==4,"both feet and hands have controls")
    pose.Apply(player,root)
    check(#humanoid:GetChildren()==5,"remount replaces owned controls without accumulating or removing avatar controls")
    pose.Clear(player)
    check(#humanoid:GetChildren()==1 and not external.Destroyed,"dismount clears only scooter controls")
    local r6=make("Model","R6",nil);local r6human=make("Humanoid","Humanoid",r6)
    pose.Apply({Character=r6},root)
    check(#r6human:GetChildren()==0,"missing R15 chains safely use native R6 seating")
    print("Scooter procedural pose checks passed: "..checks)
end
