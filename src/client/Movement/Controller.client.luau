local RunService = game:GetService("RunService")

local Movement = require(script.Parent)
local Player = require(script.Parent.Parent.Player)

local localPlayer = Player.getLocalPlayer(true) :: Player.MyPlayer

local lastDirection = Vector3.zero

RunService.RenderStepped:Connect(function()
    if Movement.canMove == false and Movement.isJumping == false then
        localPlayer.humanoid:Move(Movement.getMoveVector(), true)
    end

    if Movement.canMove == false and Movement.isJumping == true then
        localPlayer.humanoid:Move(lastDirection, true)
    end    
end)

localPlayer.humanoid.StateChanged:Connect(function(oldState, newState)
    if newState == Enum.HumanoidStateType.Freefall or newState == Enum.HumanoidStateType.Jumping then
        lastDirection = Movement.getMoveVector() * Vector3.new(1, 0, 1)
        Movement.isJumping = true
    else
        lastDirection = Vector3.zero
        Movement.isJumping = false
    end
end)