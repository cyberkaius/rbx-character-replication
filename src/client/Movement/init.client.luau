local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Player = require(script.Parent.Player)
local Thumbstick = require(script.Thumbstick)
local Keyboard = require(script.Keyboard)

print("Wheres mah player")
local localPlayer = Player.getLocalPlayer(true)
print("nah i found it")

local character = localPlayer.character

Workspace.CurrentCamera.CameraSubject = character.humanoid

local thumbstick = Thumbstick.new()

if UserInputService.TouchEnabled then
    local playerGui = localPlayer.instance:WaitForChild("PlayerGui")
    local touchGui = playerGui and playerGui:WaitForChild("TouchGui") :: ScreenGui
    local touchControlFrame = touchGui and touchGui:WaitForChild("TouchControlFrame") :: Frame

    thumbstick:Enable(true, touchControlFrame)
end

-- Handle movement
RunService.RenderStepped:Connect(function()
    if UserInputService.TouchEnabled then
        character.moveVector = Vector3.new(thumbstick.moveVector.X, 0, thumbstick.moveVector.Y)
    end

    character.moveVector = Keyboard.moveVector

    if character.canMove == true then
        character.humanoid:Move(character.moveVector, true)
    end
end)