local ContextActionService = game:GetService("ContextActionService")

local Keyboard = {}

Keyboard.moveVector = Vector3.zero

local forwardValue = 0
local backwardValue = 0
local leftValue = 0
local rightValue = 0

local function handleMovement(actionName, inputState, inputObject)
    if actionName == "forward" then
        forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
    end

    if actionName == "backward" then
        backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
    end

    if actionName == "left" then
        leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
    end

    if actionName == "right" then
        rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
    end

	Keyboard.moveVector = Vector3.new(leftValue + rightValue, 0, forwardValue + backwardValue)

    return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("forward", handleMovement, false, Enum.KeyCode.W)
ContextActionService:BindAction("backward", handleMovement, false, Enum.KeyCode.S)
ContextActionService:BindAction("right", handleMovement, false, Enum.KeyCode.D)
ContextActionService:BindAction("left", handleMovement, false, Enum.KeyCode.A)

return Keyboard