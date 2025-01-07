local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scheduler = require(ReplicatedStorage.shared.ecs.scheduler)

for i, module in script.systems:GetChildren() do
    local system = (require :: any)(module)

    Scheduler:addSystem(system)
end

