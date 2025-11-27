-- Super's Fling GUI for Roblox
-- Client-sided fling using extreme velocity, rotation, and physics manipulation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "SupersFlingGUI"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 130)
Frame.Position = UDim2.new(0.5, -150, 0.5, -65)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "Super's Fling GUI"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextColor3 = Color3.new(1, 1, 1)

local TextBox = Instance.new("TextBox", Frame)
TextBox.PlaceholderText = "Enter player name"
TextBox.Size = UDim2.new(1, -20, 0, 30)
TextBox.Position = UDim2.new(0, 10, 0, 40)
TextBox.ClearTextOnFocus = false
TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextBox.TextColor3 = Color3.new(1, 1, 1)
TextBox.Font = Enum.Font.SourceSans
TextBox.TextSize = 18

local FlingButton = Instance.new("TextButton", Frame)
FlingButton.Size = UDim2.new(0.45, -10, 0, 30)
FlingButton.Position = UDim2.new(0, 10, 0, 80)
FlingButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
FlingButton.Font = Enum.Font.SourceSansBold
FlingButton.TextSize = 18
FlingButton.TextColor3 = Color3.new(1, 1, 1)
FlingButton.Text = "Start Fling"

local UnflingButton = Instance.new("TextButton", Frame)
UnflingButton.Size = UDim2.new(0.45, -10, 0, 30)
UnflingButton.Position = UDim2.new(0.55, 0, 0, 80)
UnflingButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
UnflingButton.Font = Enum.Font.SourceSansBold
UnflingButton.TextSize = 18
UnflingButton.TextColor3 = Color3.new(1, 1, 1)
UnflingButton.Text = "Stop Fling"

-- Fling logic

local flinging = false
local flingTarget -- target character root part
local connection

-- Helper to get RootPart
local function getRootPart(char)
	return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
end

-- Mass/Weight alteration helper
local function setMassless(part, state)
	for _, p in pairs(part:GetChildren()) do
		if p:IsA("BasePart") then
			p.CustomPhysicalProperties = state and PhysicalProperties.new(0, 0, 0) or nil
		end
	end
end

-- Create a BodyVelocity and BodyAngularVelocity for fling effect
local bv, bav

local function startFling(targetChar)
	if not targetChar then return end
	local localChar = localPlayer.Character
	if not localChar then return end
	local localRoot = getRootPart(localChar)
	local targetRoot = getRootPart(targetChar)
	if not localRoot or not targetRoot then return end

	-- Prepare local character for fling
	-- Allow massless & increase mass for extreme fling
	setMassless(localChar, true)

	-- Weld localRoot to targetRoot so forces apply
	-- Instead of weld we use velocity based fling and spinning

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = localRoot

	bav = Instance.new("BodyAngularVelocity")
	bav.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bav.AngularVelocity = Vector3.new(0, 40, 0)
	bav.Parent = localRoot

	-- Quickly move local player onto target and spin fast to fling
	flinging = true

	connection = RunService.RenderStepped:Connect(function()
		if not flinging or not localRoot or not targetRoot then return end
		-- Teleport local Root to target constantly, slight offset
		localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 0.5)

		-- Push localRoot velocity outwards to fling target
		local dir = (targetRoot.Position - localRoot.Position).unit
		bv.Velocity = dir * 250 + Vector3.new(0, 0, 0)

		-- Rotate quickly for spin fling
		bav.AngularVelocity = Vector3.new(0, 50, 0)
	end)
end

local function stopFling()
	flinging = false
	if bv then bv:Destroy() bv = nil end
	if bav then bav:Destroy() bav = nil end
	if connection then connection:Disconnect() connection = nil end
	if localPlayer.Character then
		setMassless(localPlayer.Character, false)
	end
end

-- UI Actions
FlingButton.MouseButton1Click:Connect(function()
	local name = TextBox.Text
	if name == "" then return end
	local targetPlayer = Players:FindFirstChild(name)
	if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
		flingTarget = targetPlayer.Character
		startFling(flingTarget)
	end
end)
UnflingButton.MouseButton1Click:Connect(stopFling)

-- Cleanup on character respawn
Players.PlayerRemoving:Connect(function(plr)
	if flingTarget and flingTarget == plr.Character then
		stopFling()
	end
end)
localPlayer.CharacterRemoving:Connect(stopFling)
