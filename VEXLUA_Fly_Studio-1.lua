-- VEXLUA Fly x10 — Roblox Studio version for your own game
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.
-- Uses the normal Roblox mobile joystick and jump button for vertical movement.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local speeds = {10, 100, 1000, 10000}
local speedIndex = 1
local flying = false
local heartbeatConnection
local attachment
local linearVelocity
local alignOrientation
local savedAutoRotate

local gui = Instance.new("ScreenGui")
gui.Name = "VEXLUA_Fly"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(210, 158)
panel.Position = UDim2.new(1, -224, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(24, 18, 39)
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(145, 90, 255)
stroke.Thickness = 2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -16, 0, 30)
title.Position = UDim2.fromOffset(8, 6)
title.BackgroundTransparency = 1
title.Text = "VEXLUA  •  FLY"
title.TextColor3 = Color3.fromRGB(205, 175, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = panel

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 42)
    button.Position = UDim2.fromOffset(10, y)
    button.BackgroundColor3 = Color3.fromRGB(94, 55, 160)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.Text = text
    button.AutoButtonColor = true
    button.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    return button
end

local flyButton = makeButton("FLY: OFF", 42)
local speedButton = makeButton("SPEED: 10", 90)

local function cleanupFlight()
    flying = false
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    if linearVelocity then
        linearVelocity:Destroy()
        linearVelocity = nil
    end
    if alignOrientation then
        alignOrientation:Destroy()
        alignOrientation = nil
    end
    if attachment then
        attachment:Destroy()
        attachment = nil
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and savedAutoRotate ~= nil then
        humanoid.AutoRotate = savedAutoRotate
    end
    savedAutoRotate = nil
    flyButton.Text = "FLY: OFF"
    flyButton.BackgroundColor3 = Color3.fromRGB(94, 55, 160)
end

local function startFlight()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return
    end

    cleanupFlight()
    character = player.Character
    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return
    end

    savedAutoRotate = humanoid.AutoRotate
    humanoid.AutoRotate = false

    attachment = Instance.new("Attachment")
    attachment.Name = "VEXLUA_FlyAttachment"
    attachment.Parent = root

    linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Name = "VEXLUA_FlyVelocity"
    linearVelocity.Attachment0 = attachment
    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
    linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    linearVelocity.ForceLimitsEnabled = false
    linearVelocity.VectorVelocity = Vector3.zero
    linearVelocity.Parent = root

    alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Name = "VEXLUA_FlyOrientation"
    alignOrientation.Attachment0 = attachment
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Responsiveness = 12
    alignOrientation.MaxTorque = 1000000
    alignOrientation.CFrame = root.CFrame.Rotation
    alignOrientation.Parent = root

    flying = true
    flyButton.Text = "FLY: ON"
    flyButton.BackgroundColor3 = Color3.fromRGB(52, 145, 100)

    heartbeatConnection = RunService.RenderStepped:Connect(function()
        if not flying or not root.Parent or not humanoid.Parent then
            cleanupFlight()
            return
        end

        -- Use the camera direction for forward/back movement, and the
        -- Humanoid movement direction for left/right input.
        local camera = workspace.CurrentCamera
        local move = humanoid.MoveDirection
        local horizontal = Vector3.zero
        if camera then
            local look = camera.CFrame.LookVector
            local flatLook = Vector3.new(look.X, 0, look.Z)
            if flatLook.Magnitude > 0.001 then
                flatLook = flatLook.Unit
            end
            local right = camera.CFrame.RightVector
            local flatRight = Vector3.new(right.X, 0, right.Z)
            if flatRight.Magnitude > 0.001 then
                flatRight = flatRight.Unit
            end

            local forwardInput = move:Dot(flatLook)
            local sideInput = move:Dot(flatRight)
            horizontal = flatLook * forwardInput + flatRight * sideInput
        end

        local vertical = 0
        if humanoid.Jump then
            vertical = 1
        end
        -- On desktop, Space moves up and LeftControl moves down.
        -- Mobile users can use the jump button to rise; see note below.
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical = -1
        end

        linearVelocity.VectorVelocity =
            horizontal * speeds[speedIndex] + Vector3.new(0, vertical * speeds[speedIndex], 0)
    end)
end

flyButton.Activated:Connect(function()
    if flying then
        cleanupFlight()
    else
        startFlight()
    end
end)

speedButton.Activated:Connect(function()
    speedIndex += 1
    if speedIndex > #speeds then
        speedIndex = 1
    end
    speedButton.Text = "SPEED: " .. speeds[speedIndex]
end)

player.CharacterAdded:Connect(function()
    cleanupFlight()
end)

script.Destroying:Connect(function()
    cleanupFlight()
end)
