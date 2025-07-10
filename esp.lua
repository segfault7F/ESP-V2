local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local ESP = {}
local BOXES = {}

-- Color setting: Color based on health percentage (green -> red)
local function GetHealthColor(health, maxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    local r = (1 - ratio) * 255
    local g = ratio * 255
    return Color3.fromRGB(r, g, 0)
end

-- Create boxes and name tags
local function CreateESP(player)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = nil
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Transparency = 0.4
    box.Size = Vector3.new(4, 6, 1)
    box.Color3 = Color3.new(1,1,1)
    box.Parent = Camera

    local nameTag = Instance.new("BillboardGui")
    nameTag.Adornee = nil
    nameTag.AlwaysOnTop = true
    nameTag.Size = UDim2.new(0, 100, 0, 20)
    nameTag.StudsOffset = Vector3.new(0, 3.5, 0)
    nameTag.Parent = Camera

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Text = player.Name
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextScaled = true
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.Parent = nameTag

    local healthBar = Instance.new("Frame")
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Parent = nameTag

    local healthBarBG = Instance.new("Frame")
    healthBarBG.BackgroundColor3 = Color3.fromRGB(50,50,50)
    healthBarBG.BorderSizePixel = 0
    healthBarBG.Size = UDim2.new(1, 0, 0.2, 0)
    healthBarBG.Position = UDim2.new(0, 0, 0.8, 0)
    healthBarBG.Parent = nameTag

    healthBar.Parent = healthBarBG

    return {
        Box = box,
        NameTag = nameTag,
        NameLabel = nameLabel,
        HealthBarBG = healthBarBG,
        HealthBar = healthBar,
    }
end

-- Remove ESP for player
local function RemoveESP(player)
    if BOXES[player] then
        BOXES[player].Box:Destroy()
        BOXES[player].NameTag:Destroy()
        BOXES[player] = nil
    end
end

-- Update ESP elements based on player's character state
local function UpdateESP(player)
    local data = BOXES[player]
    if not data then return end

    local character = player.Character
    if not character then
        data.Box.Adornee = nil
        data.NameTag.Adornee = nil
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then
        data.Box.Adornee = nil
        data.NameTag.Adornee = nil
        return
    end

    data.Box.Adornee = root
    data.NameTag.Adornee = root

    -- Set color according to health percentage
    local healthPercent = humanoid.Health / humanoid.MaxHealth
    data.Box.Color3 = GetHealthColor(humanoid.Health, humanoid.MaxHealth)
    data.NameLabel.TextColor3 = GetHealthColor(humanoid.Health, humanoid.MaxHealth)

    -- Health bar settings
    data.HealthBarBG.Size = UDim2.new(1, 0, 0.15, 0)
    data.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    data.HealthBar.BackgroundColor3 = GetHealthColor(humanoid.Health, humanoid.MaxHealth)

    -- Hide if off-screen
    local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
    local visible = onScreen and screenPos.Z > 0
    data.Box.Visible = visible
    data.NameTag.Enabled = visible
end

-- Setup ESP when character spawns
local function OnCharacterAdded(player, character)
    if not BOXES[player] then
        BOXES[player] = CreateESP(player)
    end

    local humanoid = character:WaitForChild("Humanoid")

    humanoid.Died:Connect(function()
        -- When player dies, box and name tag remain visible.
        -- On respawn, UpdateESP will refresh the box.
    end)
end

-- Setup player connections
local function SetupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        OnCharacterAdded(player, character)
    end)

    if player.Character then
        OnCharacterAdded(player, player.Character)
    end
end

-- Initialize for existing players
for _, player in pairs(Players:GetPlayers()) do
    SetupPlayer(player)
end

Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(RemoveESP)

-- Update ESP every frame
RunService.RenderStepped:Connect(function()
    for player, _ in pairs(BOXES) do
        UpdateESP(player)
    end
end)
