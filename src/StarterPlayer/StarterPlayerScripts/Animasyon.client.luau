-- Tum oyuncaklar icin yumruk ve yetenek pozlari.
-- Eklemler artik AnimationConstraint (C0 salt okunur). Poz, Animator'dan sonra Transform'a eklenir,
-- bir sonraki karede Animator'dan once geri alinir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local oyuncu = Players.LocalPlayer
local efektRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(Config.Remote.Efekt)

local aktif = {} -- eklem -> { bas, hedef, t0, giris, bitis, cikis }
local uygulanan = {} -- eklem -> bu karede eklenen ofset

local function motorBul(karakter, ad, ebeveyn)
	local parca = karakter and karakter:FindFirstChild(ebeveyn)
	local eklem = parca and parca:FindFirstChild(ad)
	if eklem and (eklem:IsA("Motor6D") or eklem:IsA("AnimationConstraint")) then
		return eklem
	end
	return nil
end

local function simdikiOfset(eklem)
	local a = aktif[eklem]
	if not a then return CFrame.identity end
	local simdi = os.clock()
	if simdi < a.t0 + a.giris then
		local t = (simdi - a.t0) / a.giris
		t = 1 - (1 - t) * (1 - t)
		return a.bas:Lerp(a.hedef, t)
	elseif simdi < a.bitis then
		return a.hedef
	elseif simdi < a.bitis + a.cikis then
		return a.hedef:Lerp(CFrame.identity, (simdi - a.bitis) / a.cikis)
	end
	return nil
end

-- hedef: eklemin dinlenme pozuna gore donus, sure: giris, bekle: hedefte kalma
local function poz(eklem, hedef, sure, bekle, cikis)
	if not eklem or not eklem.Parent then return end
	local bas = simdikiOfset(eklem) or CFrame.identity
	local simdi = os.clock()
	aktif[eklem] = {
		bas = bas,
		hedef = hedef,
		t0 = simdi,
		giris = math.max(sure, 0.01),
		bitis = simdi + sure + (bekle or 0),
		cikis = cikis or 0.13,
	}
end

RunService.PreAnimation:Connect(function()
	for eklem, ofset in pairs(uygulanan) do
		if eklem.Parent then
			eklem.Transform = ofset:Inverse() * eklem.Transform
		end
	end
	table.clear(uygulanan)
end)

RunService.PreSimulation:Connect(function()
	for eklem in pairs(aktif) do
		if not eklem.Parent then
			aktif[eklem] = nil
		else
			local ofset = simdikiOfset(eklem)
			if ofset then
				eklem.Transform = ofset * eklem.Transform
				uygulanan[eklem] = ofset
			else
				aktif[eklem] = nil
			end
		end
	end
end)

local function A(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y or 0), math.rad(z or 0))
end

local function yumruk(karakter, kombo)
	local sagOmuz = motorBul(karakter, "RightShoulder", "RightUpperArm")
	local solOmuz = motorBul(karakter, "LeftShoulder", "LeftUpperArm")
	local sagDirsek = motorBul(karakter, "RightElbow", "RightLowerArm")
	local solDirsek = motorBul(karakter, "LeftElbow", "LeftLowerArm")
	local bel = motorBul(karakter, "Waist", "UpperTorso")
	local kalca = motorBul(karakter, "RightHip", "RightUpperLeg")
	-- Olculen eksenler (AnimationConstraint): omuz X+ = kol ileri, sag omuz Z+ = disa (bel donusunu dengeler),
	-- dirsek X+ = bukme, bel Y+ = sag omuz one, bel X- = one egil, kalca X+ = bacak ileri
	local sure = 0.07
	if kombo == 2 then
		poz(solOmuz, A(92, 0, -12), sure, 0.08, 0.15)
		poz(solDirsek, A(5), sure, 0.08, 0.15)
		poz(bel, A(-6, -15, 0), sure, 0.08, 0.15)
	elseif kombo == 3 then
		poz(sagOmuz, A(155, 0, 10), 0.09, 0.12, 0.2)
		poz(sagDirsek, A(45), 0.09, 0.12, 0.2)
		poz(bel, A(4, 15, 0), 0.09, 0.12, 0.2)
		poz(kalca, A(35), 0.09, 0.12, 0.2)
	else
		poz(sagOmuz, A(92, 0, 12), sure, 0.08, 0.15)
		poz(sagDirsek, A(5), sure, 0.08, 0.15)
		poz(bel, A(-6, 15, 0), sure, 0.08, 0.15)
	end
end

local function kolIleri(karakter)
	poz(motorBul(karakter, "RightShoulder", "RightUpperArm"), A(90, 0, -6), 0.12, 3)
	poz(motorBul(karakter, "LeftShoulder", "LeftUpperArm"), A(90, 0, 6), 0.12, 3)
end

-- Kement: kolu basin ustune kaldir (ilmek doner), sonra ileri savur
local function firlat(karakter)
	local omuz = motorBul(karakter, "RightShoulder", "RightUpperArm")
	local dirsek = motorBul(karakter, "RightElbow", "RightLowerArm")
	local bel = motorBul(karakter, "Waist", "UpperTorso")
	poz(omuz, A(170, 0, 15), 0.1, 0.2)
	poz(dirsek, A(20), 0.1, 0.2)
	poz(bel, A(0, -15, 0), 0.1, 0.2)
	task.delay(0.3, function()
		poz(omuz, A(95, 0, -8), 0.07, 0.4, 0.2)
		poz(dirsek, A(0), 0.07, 0.4, 0.2)
		poz(bel, A(-8, 22, 0), 0.07, 0.4, 0.2)
	end)
end

local function yumrukYere(karakter)
	poz(motorBul(karakter, "RightShoulder", "RightUpperArm"), A(170, 0, 15), 0.12, 0.1)
	poz(motorBul(karakter, "LeftShoulder", "LeftUpperArm"), A(170, 0, -15), 0.12, 0.1)
	task.delay(0.22, function()
		poz(motorBul(karakter, "RightShoulder", "RightUpperArm"), A(40, 0, -10), 0.08, 0.3)
		poz(motorBul(karakter, "LeftShoulder", "LeftUpperArm"), A(40, 0, 10), 0.08, 0.3)
		poz(motorBul(karakter, "Waist", "UpperTorso"), A(-25), 0.08, 0.3)
	end)
end

-- Astronot isin: iki el ileri, govde hafif geri
local function isinPoz(karakter)
	poz(motorBul(karakter, "RightShoulder", "RightUpperArm"), A(90, 0, -15), 0.15, 0.9, 0.25)
	poz(motorBul(karakter, "LeftShoulder", "LeftUpperArm"), A(90, 0, 15), 0.15, 0.9, 0.25)
	poz(motorBul(karakter, "Waist", "UpperTorso"), A(6), 0.15, 0.9, 0.25)
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
	elseif tur == "isinPoz" and typeof(karakter) == "Instance" then
		isinPoz(karakter)
	elseif tur == "vurus" then
		vurusuIsle(veri)
	end
end)
