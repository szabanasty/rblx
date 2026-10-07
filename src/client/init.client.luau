--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local projectInfoModule = shared:WaitForChild("ProjectInfo") :: ModuleScript
local ProjectInfo = require(projectInfoModule)

print(string.format("[%s][client] Sync ready (version %s).", ProjectInfo.Name, ProjectInfo.Version))
