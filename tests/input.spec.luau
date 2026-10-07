--!nonstrict
return function(loadService)
    local checks=0
    local function check(ok,message) assert(ok,message);checks+=1 end
    local function signal()
        local out={Callbacks={}}
        function out:Connect(fn) table.insert(self.Callbacks,fn);return {Disconnect=function() end} end
        function out:Fire(...) for _,fn in self.Callbacks do fn(...) end end
        return out
    end
    local enums=setmetatable({}, {__index=function(self,category)
        local items=setmetatable({}, {__index=function(group,name)
            local value=category..":"..name;rawset(group,name,value);return value
        end});rawset(self,category,items);return items
    end})
    enums.ContextActionPriority={High={Value=3000}}
    local textbox=nil
    local ui={InputBegan=signal(),InputEnded=signal(),WindowFocusReleased=signal(),WindowFocused=signal(),
        GetFocusedTextBox=function() return textbox end}
    local actions={}
    local cas={BindActionAtPriority=function(_,name,callback,_,priority,...)
        check(priority>3000,"priority beats native character controls");actions[name]=callback
    end}
    local humanoid={Parent=true,Enabled=true,Jump=true,GetStateEnabled=function(self) return self.Enabled end,
        SetStateEnabled=function(self,_,enabled) self.Enabled=enabled end}
    local character={FindFirstChildOfClass=function() return humanoid end}
    local player={Character=character,CharacterAdded=signal(),WaitForChild=function()
        return {WaitForChild=function() return nil end}
    end}
    local heart=signal()
    local services={UserInputService=ui,ContextActionService=cas,RunService={Heartbeat=heart},Players={LocalPlayer=player}}
    local sent={}
    local requests={}
    local service=loadService({GetService=function(_,name) return services[name] end},enums,
        {spawn=function(callback) callback() end},function() error("No optional PlayerModule in fixture") end)
    service:Init({Remotes={Input={FireServer=function(_,value) table.insert(sent,value) end}},
        Send=function(action) table.insert(requests,action) end,
        Controllers={UIController={SetInputHandlers=function() end}}})
    service:Start()
    heart:Fire(0.2);check(#sent==0,"on-foot inputs not sent")
    service:Update({Ready=true,Telemetry={Riding=true}})
    check(humanoid.Enabled==false and humanoid.Jump==false,"native humanoid jump disabled while riding")
    local function key(code,state)
        return actions.ScooterKeyboard("ScooterKeyboard",state or enums.UserInputState.Begin,{KeyCode=code})
    end
    check(key(enums.KeyCode.W)==enums.ContextActionResult.Sink,"mounted movement consumed")
    heart:Fire(0.1);check(sent[#sent].Throttle==1,"W accelerates")
    key(enums.KeyCode.S)
    heart:Fire(0.1);check(sent[#sent].Brake and sent[#sent].Throttle==0,"brake overrides throttle")
    key(enums.KeyCode.S,enums.UserInputState.End)
    key(enums.KeyCode.A)
    heart:Fire(0.1);check(sent[#sent].Steer==-1,"left steering")
    key(enums.KeyCode.Space)
    heart:Fire(0.1);check(sent[#sent].Jump==true,"Space emits scooter jump")
    heart:Fire(0.1);check(sent[#sent].Jump==false,"jump one-shot")
    key(enums.KeyCode.E)
    check(requests[#requests]=="DismountScooter","explicit dismount intent")
    ui.WindowFocusReleased:Fire()
    check(sent[#sent].Throttle==0 and sent[#sent].Brake,"lost focus immediately brakes")
    ui.WindowFocused:Fire()
    service:SetTouchInput("Throttle",true)
    heart:Fire(0.1);check(sent[#sent].Throttle==1,"touch throttle")
    textbox={}
    heart:Fire(0.1);check(sent[#sent].Throttle==0 and sent[#sent].Brake,"typing does not drive")
    textbox=nil
    service:SetMenuOpen(true)
    check(sent[#sent].Brake and sent[#sent].Throttle==0,"opening menu brakes immediately")
    service:SetTouchInput("Throttle",true)
    key(enums.KeyCode.W)
    heart:Fire(0.1)
    check(sent[#sent].Throttle==0 and sent[#sent].Brake,"menu ignores keyboard and touch driving")
    service:SetMenuOpen(false)
    heart:Fire(0.1)
    check(sent[#sent].Throttle==0,"menu close does not preserve held pedal")
    service:Update({Ready=false})
    check(humanoid.Enabled==true,"native jump restored on exit")
    check(key(enums.KeyCode.W)==enums.ContextActionResult.Pass,"on-foot keyboard passed through")
    print("Client input checks passed: "..checks)
end
