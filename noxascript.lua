-- LocalScript (poner en StarterPlayer > StarterPlayerScripts)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local flying = false
local bodyVelocity, bodyGyro
local BASE_SPEED = 60           -- velocidad base
local SPEED_MULTIPLIER = 2.0    -- multiplicador al mantener LeftShift
local V_FORCE = 1e5

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function enableFly()
    local char = getCharacter()
    local hrp = char:WaitForChild("HumanoidRootPart")
    if bodyVelocity or bodyGyro then return end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(V_FORCE, V_FORCE, V_FORCE)
    bodyVelocity.P = 1250
    bodyVelocity.Velocity = Vector3.new(0,0,0)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(V_FORCE, V_FORCE, V_FORCE)
    bodyGyro.P = 3000
    bodyGyro.CFrame = hrp.CFrame
    bodyGyro.Parent = hrp

    -- Evitar que el Humanoid intente "caminar" mientras vuelas
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.PlatformStand = false
    end

    flying = true
end

local function disableFly()
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    flying = false
end

-- Toggle con E
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.E then
            if flying then disableFly() else enableFly() end
        end
    end
end)

-- Lógica de movimiento por frame
RunService.RenderStepped:Connect(function()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local char = player.Character
    if not char then disableFly(); return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then disableFly(); return end

    -- Dirección basada en la cámara para control natural
    local cam = workspace.CurrentCamera
    local look = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector

    local moveVec = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + Vector3.new(look.X, 0, look.Z) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - Vector3.new(look.X, 0, look.Z) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - Vector3.new(right.X, 0, right.Z) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + Vector3.new(right.X, 0, right.Z) end

    local vertical = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = vertical + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = vertical - 1 end

    local currentSpeed = BASE_SPEED
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        currentSpeed = currentSpeed * SPEED_MULTIPLIER
    end

    local horizontalVel = Vector3.new(0,0,0)
    if moveVec.Magnitude > 0 then
        horizontalVel = moveVec.Unit * currentSpeed
    end

    local targetVel = horizontalVel + Vector3.new(0, vertical * currentSpeed, 0)
    bodyVelocity.Velocity = targetVel

    -- Mantener orientación suave hacia la dirección de la cámara
    bodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)

-- Limpiar si el personaje reaparece o si se cae el humano
player.CharacterRemoving:Connect(function() disableFly() end)
player.CharacterAdded:Connect(function() disableFly() end)
