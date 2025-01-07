local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Planck = require(ReplicatedStorage.packages.planck)
local Jabby = require(ReplicatedStorage.packages.planckJabby)

-- Create scheduler
local scheduler = Planck.Scheduler.new()
    :addPlugin(Jabby.new() :: any)

return scheduler