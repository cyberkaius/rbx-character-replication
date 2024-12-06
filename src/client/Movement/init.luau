local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = require(script.Parent.Player)

local Thumbstick = require(script.Thumbstick)
local Keyboard = require(script.Keyboard)

local thumbstick = Thumbstick.new()

print(Player.getLocalPlayer(false))

local localPlayer = Player.getLocalPlayer(true) :: Player.MyPlayer

print(localPlayer)

local Movement = {}
Movement.canMove = false
Movement.canJump = true
Movement.isJumping = false

if UserInputService.TouchEnabled then
    local playerGui = localPlayer.instance:WaitForChild("PlayerGui")
    local touchGui = playerGui and playerGui:WaitForChild("TouchGui") :: ScreenGui
    local touchControlFrame = touchGui and touchGui:WaitForChild("TouchControlFrame") :: Frame

    thumbstick:Enable(true, touchControlFrame)
end

Movement.getMoveVector = function()
    if UserInputService.TouchEnabled then
        return Vector3.new(thumbstick.moveVector.X, 0, thumbstick.moveVector.Y)
    end

    return Keyboard.moveVector
end

-- Must be called every frame
Movement.moveTo = function(position: Vector3, faceTarget: CFrame?, lerpSpeed: number?)
    -- Move to position
    local targetPos = position * Vector3.new(1, 0, 1)
    local rootPos = localPlayer.root.Position * Vector3.new(1, 0, 1)
    local directionToTarget = targetPos - rootPos

    localPlayer.humanoid:Move(directionToTarget)

    -- Rotate to target
    if faceTarget ~= nil then
        localPlayer.root.CFrame = localPlayer.root.CFrame:Lerp(faceTarget, lerpSpeed or 0.1)      
    end
end

return Movement