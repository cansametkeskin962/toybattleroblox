-- Tum oyuncaklar icin yumruk ve yetenek pozlari.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local oyuncu = Players.LocalPlayer
local efektRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Config.Remote.Efekt)
local orijinaller = {}
local aktifTweenler = {}

local function motorBul(karakter, ad, ebeveyn)
	local parca = karakter and karakter:FindFirstChild(ebeveyn)
	local motor = parca and parca:FindFirstChild(ad)
	return motor and motor:IsA("Motor6D") and motor or nil
end

local function motorC0(motor)
	if not orijinaller[motor] then
		orijinaller[motor] = motor.C0
	end
	if aktifTweenler[motor] then
		aktifTweenler[motor]:Cancel()
	end
end

local function poz(motor, hedef, sure, bekle)
	if not motor or not motor.Parent then return end
	motorC0(motor)
	local tween = TweenService:Create(motor, TweenInfo.new(sure, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = orijinaller[motor] * hedef })
	aktifTweenler[motor] = tween
	tween:Play()
	if bekle then
		task.delay(bekle, function()
			if motor.Parent and orijinaller[motor] then
				if aktifTweenler[motor] then aktifTweenler[motor]:Cancel() end
				local don = TweenService:Create(motor, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { C0 = orijinaller[motor] })
				aktifTweenler[motor] = don
				don:Play()
			end
		end)
	end
end

local function yumruk(karakter, kombo)
	local sagOmuz = motorBul(karakter, "RightShoulder", "RightUpperArm")
	local solOmuz = motorBul(karakter, "LeftShoulder", "LeftUpperArm")
	local sagDirsek = motorBul(karakter, "RightElbow", "RightLowerArm")
	local bel = motorBul(karakter, "Waist", "UpperTorso")
	local kalca = motorBul(karakter, "RightHip", "RightUpperLeg")
	local sure = 0.12
	if kombo == 2 then
		poz(solOmuz, CFrame.Angles(math.rad(-65), math.rad(18), math.rad(-20)), sure)
	elseif kombo == 3 then
		poz(sagOmuz, CFrame.Angles(math.rad(-115), math.rad(-8), math.rad(28)), sure)
		poz(sagDirsek, CFrame.Angles(math.rad(-50), 0, 0), sure)
		poz(bel, CFrame.Angles(math.rad(12), math.rad(22), 0), sure)
		poz(kalca, CFrame.Angles(math.rad(-18), 0, 0), sure)
	else
		poz(sagOmuz, CFrame.Angles(math.rad(-65), math.rad(-18), math.rad(20)), sure)
		poz(sagDirsek, CFrame.Angles(math.rad(-28), 0, 0), sure)
	end
	for _, motor in ipairs({ sagOmuz, solOmuz, sagDirsek, bel, kalca }) do
		if motor then
			local original = orijinaller[motor]
			task.delay(0.12, function()
				if motor.Parent and original then
					local don = TweenService:Create(motor, TweenInfo.new(0.13), { C0 = original })
					aktifTweenler[motor] = don
					don:Play()
				end
			end)
		end
	end
end

local function kolIleri(karakter)
	for _, bilgi in ipairs({ { "RightShoulder", "RightUpperArm", -78, -8 }, { "LeftShoulder", "LeftUpperArm", -78, 8 } }) do
		poz(motorBul(karakter, bilgi[1], bilgi[2]), CFrame.Angles(math.rad(bilgi[3]), 0, math.rad(bilgi[4])), 0.16, 3)
	end
end

local function firlat(karakter)
	poz(motorBul(karakter, "RightShoulder", "RightUpperArm"), CFrame.Angles(math.rad(-125), math.rad(-20), math.rad(18)), 0.12, 0.3)
	poz(motorBul(karakter, "RightElbow", "RightLowerArm"), CFrame.Angles(math.rad(-70), 0, 0), 0.12, 0.3)
end

local function yumrukYere(karakter)
	for _, bilgi in ipairs({ { "RightShoulder", "RightUpperArm", 70, -18 }, { "LeftShoulder", "LeftUpperArm", 70, 18 } }) do
		poz(motorBul(karakter, bilgi[1], bilgi[2]), CFrame.Angles(math.rad(bilgi[3]), 0, math.rad(bilgi[4])), 0.15, 0.45)
	end
end

local function vurusuIsle(veri)
	local karakter = veri.karakter or veri.Karakter
	local konum = veri.konum or veri.Konum
	if not karakter and typeof(konum) == "Vector3" then
		local enYakin, uzaklik = nil, 3
		for _, player in ipairs(Players:GetPlayers()) do
			local aday = player.Character
			local kok = aday and aday:FindFirstChild("HumanoidRootPart")
			if kok and (kok.Position - konum).Magnitude < uzaklik then
				enYakin, uzaklik = aday, (kok.Position - konum).Magnitude
			end
		end
		karakter = enYakin
	end
	if typeof(karakter) == "Instance" and karakter:IsA("Model") then
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 55, 55)
		highlight.OutlineColor = Color3.fromRGB(255, 230, 230)
		highlight.FillTransparency = 0.35
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = karakter
		Debris:AddItem(highlight, 0.12)
	end
	if typeof(konum) == "Vector3" then
		local root = oyuncu.Character and oyuncu.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - konum).Magnitude < 24 then
			local kamera = workspace.CurrentCamera
			if kamera then kamera.CFrame = kamera.CFrame * CFrame.new(0, 0, 0.06) end
		end
	end
end

efektRemote.OnClientEvent:Connect(function(tur, veri)
	if typeof(tur) ~= "string" or typeof(veri) ~= "table" then return end
	local karakter = veri.karakter or veri.Karakter
	if tur == "yumruk" and typeof(karakter) == "Instance" then
		yumruk(karakter, veri.kombo or veri.Kombo or 1)
	elseif tur == "kolIleri" and typeof(karakter) == "Instance" then
		kolIleri(karakter)
	elseif tur == "firlat" and typeof(karakter) == "Instance" then
		firlat(karakter)
	elseif tur == "yumrukYere" and typeof(karakter) == "Instance" then
		yumrukYere(karakter)
	elseif tur == "vurus" then
		vurusuIsle(veri)
	end
end)
