local SnapshotBuffer = require(script.Parent.SnapshotBuffer)

local Interpolation = {}

Interpolation.bufferDelay = .1
Interpolation.replicationRate = 60 -- hz
Interpolation.packetFrequency = 1 / Interpolation.replicationRate
Interpolation.allowedExtrapolation = 1 + (Interpolation.packetFrequency * 4)

local twoPi = math.pi * 2

local function angleAbs(angle: number)
    return ((angle % twoPi) + twoPi) % twoPi
end

local function angleShortest(a0: number, a1: number)
    local d1 = angleAbs(a1 - a0)
    local d2 = angleAbs(a0 - a1)

    return if d1 > d2 then -d2 else d1
end

local function lerpAngle(a0: number, a1: number, fraction: number)
    return a0 + angleShortest(a0, a1) * fraction
end

function Interpolation.getCFrame(snapshotA: SnapshotBuffer.Snapshot, snapshotB: SnapshotBuffer.Snapshot, renderAt: number)
    local alpha = (renderAt - snapshotA.timestamp) / (snapshotB.timestamp - snapshotA.timestamp)

    alpha = math.clamp(alpha, 0, Interpolation.allowedExtrapolation)

    --print(snapshotB.timestamp - snapshotA.timestamp)
    --print("SnapshotA Timestamp:" .. snapshotA.timestamp)
   -- print("RenderAt Timestamp:" .. renderAt)
    --print("SnapshotB Timestamp:" .. snapshotB.timestamp)
    --print("Alpha:" .. alpha)
    --print("-------------")

    local positionA = Vector3.new(snapshotA.transform.x, snapshotA.transform.y, snapshotA.transform.z)
    local positionB = Vector3.new(snapshotA.transform.x, snapshotA.transform.y, snapshotA.transform.z)
    
    local lerpedRotation = lerpAngle(snapshotA.transform.yRotation, snapshotB.transform.yRotation, alpha)
    local cos, sin = math.cos(lerpedRotation), math.sin(lerpedRotation)

    local lerpedPosition = positionA:Lerp(positionB, alpha)
    
    --stylua: ignore start
    local newCFrame = CFrame.new(
        lerpedPosition.X,
        lerpedPosition.Y,
        lerpedPosition.Z,
        
        cos,  0,    sin,
        0,    1,    0,
        -sin, 0,    cos
    )
    --stylua: ignore end

    return newCFrame
end

return Interpolation