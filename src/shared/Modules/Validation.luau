--!strict
local Validation = {}
export type ActionRequest = {Action: string, Payload: {[string]: any}, RequestId: number}
export type ScooterInput = {Throttle: number, Steer: number, Brake: boolean, Jump: boolean}
function Validation.IsFinite(value: any): boolean
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Validation.IsInteger(value: any, low: number, high: number): boolean
    return Validation.IsFinite(value) and value % 1 == 0 and value >= low and value <= high
end
local function fields(value: any, allowed: {[string]: boolean}, maximum: number): boolean
    if type(value) ~= "table" then return false end
    local count = 0
    for key in value do
        count += 1
        if count > maximum or type(key) ~= "string" or not allowed[key] then return false end
    end
    return true
end
local settings = {
    UIScale = {0.75, 1.5}, GraphicsQuality = {1, 3},
    MusicVolume = {0, 1}, SFXVolume = {0, 1},
}
function Validation.IsSetting(name: any, value: any): boolean
    if name == "ReducedEffects" then return type(value) == "boolean" end
    if type(name) ~= "string" then return false end
    local limits = settings[name]
    if not limits or not Validation.IsFinite(value) then return false end
    if name == "GraphicsQuality" and value % 1 ~= 0 then return false end
    return value >= limits[1] and value <= limits[2]
end
function Validation.ParseAction(value: any): (ActionRequest?, string?)
    if not fields(value, {Action = true, Payload = true, RequestId = true}, 3) then return nil, "InvalidRequest" end
    if type(value.Action) ~= "string" or #value.Action > 32
        or not Validation.IsInteger(value.RequestId, 1, 2000000000) then return nil, "InvalidRequest" end
    local action = value.Action
    local payload = value.Payload
    local empty = {ChargeScooter = true, CreateSquad = true, AcceptSquad = true, DeclineSquad = true, LeaveSquad = true,
        Reload = true, CancelRevive = true, ToggleFishing = true, StopFishing = true}
    if empty[action] then
        if not fields(payload, {}, 0) then return nil, "InvalidPayload" end
    elseif action == "InviteSquad" or action == "KickSquad" or action == "HoldRevive" then
        if not fields(payload, {TargetId = true}, 1) or not Validation.IsInteger(payload.TargetId, -9007199254740991, 9007199254740991) then return nil, "InvalidPlayer" end
    elseif action == "Shoot" then
        if not fields(payload, {X = true, Y = true, Z = true, Aim = true}, 4) or not Validation.IsFinite(payload.X)
            or not Validation.IsFinite(payload.Y) or not Validation.IsFinite(payload.Z) or type(payload.Aim) ~= "boolean" then return nil, "InvalidAim" end
        local length = payload.X^2 + payload.Y^2 + payload.Z^2
        if length < 0.98 or length > 1.02 then return nil, "InvalidAim" end
    elseif action == "EquipEquipment" then
        if not fields(payload, {Slot = true, EquipmentId = true}, 2) or type(payload.EquipmentId) ~= "string" or #payload.EquipmentId > 64
            or (payload.Slot ~= "PRIMARY" and payload.Slot ~= "SECONDARY" and payload.Slot ~= "UTILITY") then return nil, "InvalidEquipment" end
    elseif action == "SwitchEquipment" then
        if not fields(payload, {Slot = true}, 1) or (payload.Slot ~= "PRIMARY" and payload.Slot ~= "SECONDARY" and payload.Slot ~= "UTILITY") then return nil, "InvalidEquipment" end
    elseif action == "BuyEquipment" then
        if not fields(payload, {EquipmentId = true}, 1) or type(payload.EquipmentId) ~= "string" or #payload.EquipmentId == 0 or #payload.EquipmentId > 64 then return nil, "InvalidEquipment" end
    elseif action == "SellFish" then
        if not fields(payload, {Index = true, Revision = true}, 2) or not Validation.IsInteger(payload.Index, 0, 60) or not Validation.IsInteger(payload.Revision, 1, 2000000000) then return nil, "InvalidFish" end
    elseif action == "BuyCosmetic" then
        if not fields(payload, {Category = true, Option = true}, 2) or type(payload.Category) ~= "string" or #payload.Category > 32
            or type(payload.Option) ~= "string" or #payload.Option > 64 then return nil, "InvalidCosmetic" end
    elseif action == "Sync" or action == "SpawnScooter" or action == "DespawnScooter" or action == "DismountScooter" or action == "CancelQuest" then
        if not fields(payload, {}, 0) then return nil, "InvalidPayload" end
    elseif action == "SelectScooter" or action == "BuyScooter" then
        if not fields(payload, {ScooterId = true}, 1)
            or type(payload.ScooterId) ~= "string" or #payload.ScooterId < 1 or #payload.ScooterId > 64 then
            return nil, "InvalidScooter"
        end
    elseif action == "UpgradeScooter" then
        if not fields(payload, {ScooterId = true, Category = true}, 2)
            or type(payload.ScooterId) ~= "string" or #payload.ScooterId < 1 or #payload.ScooterId > 64
            or type(payload.Category) ~= "string" or #payload.Category < 1 or #payload.Category > 32 then return nil, "InvalidUpgrade" end
    elseif action == "StartQuest" then
        if not fields(payload, {QuestId = true}, 1)
            or type(payload.QuestId) ~= "string" or #payload.QuestId < 1 or #payload.QuestId > 64 then return nil, "InvalidQuest" end
    elseif action == "SetSetting" then
        if not fields(payload, {Name = true, Value = true}, 2) or not Validation.IsSetting(payload.Name, payload.Value) then
            return nil, "InvalidSetting"
        end
    else return nil, "UnknownAction" end
    return {Action = action, Payload = payload, RequestId = value.RequestId}, nil
end
function Validation.ParseInput(value: any): (ScooterInput?, string?)
    if not fields(value, {Throttle = true, Steer = true, Brake = true, Jump = true}, 4)
        or not Validation.IsFinite(value.Throttle) or math.abs(value.Throttle) > 1
        or not Validation.IsFinite(value.Steer) or math.abs(value.Steer) > 1
        or type(value.Brake) ~= "boolean" or type(value.Jump) ~= "boolean" then return nil, "InvalidInput" end
    return {Throttle = value.Throttle, Steer = value.Steer, Brake = value.Brake, Jump = value.Jump}, nil
end
return table.freeze(Validation)
