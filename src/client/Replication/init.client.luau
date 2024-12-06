local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Entities = require(ReplicatedStorage.Shared.Replication.Entities)
local Zap = require(script.Parent.Zap)
local Interpolation = require(ReplicatedStorage.Shared.Replication.Interpolation)
local SnapshotBuffer = require(ReplicatedStorage.Shared.Replication.SnapshotBuffer)
local Tick = require(ReplicatedStorage.Shared.Replication.Tick)
local Transform = require(ReplicatedStorage.Shared.Replication.Transform)
local Player = require(script.Parent.Player)

-- Local client buffer
local localClientBuffer = SnapshotBuffer.new(Interpolation.replicationRate)

-- Other clients buffers
local remoteClientBuffers = {} :: {SnapshotBuffer.Buffer}

-- Get entity updates
local remoteClientRoots = {} :: {Instance?}

-- Get server tick
local currentTime = Tick.toTimestamp(Zap.RequestServerTick.Call())

print("tryna find local")

-- Get local root
local localPlayer = Player.getLocalPlayer(true) :: Player.MyPlayer

print("Found local")

local lastTick = os.clock()

local queuedTransform: Transform.Transform = {
    x = localPlayer.root.CFrame.X,
    y = localPlayer.root.CFrame.Y,
    z = localPlayer.root.CFrame.Z,
    yRotation = math.rad(localPlayer.root.Orientation.Y)
} 

-- Update buffers and roots whenever an entity is added
Entities.connect(function(entity, added)
    if added then
        local root = Entities.getInstance(entity) :: BasePart?

        if root then
            remoteClientRoots[entity] = root
            remoteClientBuffers[entity] = SnapshotBuffer.new(Interpolation.replicationRate / 2)        
        end
    elseif not added then
        remoteClientRoots[entity] = nil
        remoteClientBuffers[entity] = nil
    end    
end)

-- Replicate local position to server
RunService.PostSimulation:Connect(function()
    if os.clock() - lastTick >= Interpolation.packetFrequency then
        lastTick = os.clock()

        queuedTransform = {
            x = localPlayer.root.CFrame.X,
            y = localPlayer.root.CFrame.Y,
            z = localPlayer.root.CFrame.Z,
            yRotation = math.rad(localPlayer.root.Orientation.Y)
        }

        Zap.RequestReplication.Fire(queuedTransform)
    end
end)

-- Interpolate other characters
RunService.RenderStepped:Connect(function(deltaTime: number)
    currentTime += deltaTime

    local roots = {}
    local cframes = {}

    local renderAt = currentTime - Interpolation.bufferDelay - (Interpolation.packetFrequency)

    for key, buffer in pairs(remoteClientBuffers) do
        local snapshotA, snapshotB = SnapshotBuffer.findClosestSnapshot(buffer, renderAt)

        if snapshotA and snapshotB then
            local newCFrame = Interpolation.getCFrame(snapshotA, snapshotB, renderAt)

            table.insert(roots, remoteClientRoots[key])
            table.insert(cframes, newCFrame)        
        end
    end

    if #roots == #cframes then
        Workspace:BulkMoveTo(roots, cframes)
    end
end)

-- Receive packets from server
Zap.BroadcastReplication.SetCallback(function(data)
    if Tick.raw > data.tick then
        Tick.wrapCount += 1
    end

    Tick.raw = data.tick

    local timestamp = Tick.toTimestamp(data.tick)

    currentTime = timestamp

    if queuedTransform then
        SnapshotBuffer.addSnapshot(localClientBuffer, {
            timestamp = timestamp,
            transform = queuedTransform
        })    
    end
    
    for i, v in pairs(data.map) do
        local transform = {
            x = v.x, 
            y = v.y, 
            z = v.z,
            yRotation = v.yRotation
        }

        if remoteClientRoots[v.entity] and remoteClientBuffers[v.entity]then
            SnapshotBuffer.addSnapshot(remoteClientBuffers[v.entity], {
                timestamp = timestamp,
                transform = transform
            })
        end
    end
end)
