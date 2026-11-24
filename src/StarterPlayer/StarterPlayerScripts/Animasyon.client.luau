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

-- Gercek yumruk animasyonlari (Roblox animgen). Her klipten sadece vurus araligi oynatilir;
-- hiz, tepe noktasina ~0.1 sn'de varacak sekilde: (tepe - bas) / 0.1
local YUMRUKLAR = {
	[1] = { id = "rbxassetid://134714218338910", bas = 1.95, tepe = 2.3, bit = 2.5 }, -- sol direkt
	[2] = { id = "rbxassetid://131432995363380", bas = 0.45, tepe = 0.75, bit = 1.1 }, -- sag duz
	[3] = { id = "rbxassetid://117454892144208", bas = 0.7, tepe = 1.15, bit = 1.6 }, -- sol aparkat
}
local yumrukIzleri = {} -- animator -> { [kombo] = track }
local yumrukSayaci = {}
task.spawn(function()
	local liste = {}
	for _, y in ipairs(YUMRUKLAR) do
		local a = Instance.new("Animation")
		a.AnimationId = y.id
		table.insert(liste, a)
	end
	pcall(function() game:GetService("ContentProvider"):PreloadAsync(liste) end)
end)

local function yumrukAnim(karakter, kombo)
	local hum = karakter:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local y = YUMRUKLAR[kombo] or YUMRUKLAR[1]
	if not animator then return false end
	local izler = yumrukIzleri[animator]
	if not izler then
		izler = {}
		yumrukIzleri[animator] = izler
	end
	local iz = izler[kombo]
	if not iz then
		local a = Instance.new("Animation")
		a.AnimationId = y.id
		iz = animator:LoadAnimation(a)
		iz.Priority = Enum.AnimationPriority.Action4
		iz.Looped = false
		izler[kombo] = iz
	end
	if iz.Length <= 0 then return false end -- henuz yuklenmedi: yedek poz
	for k, digeri in pairs(izler) do
		if k ~= kombo and digeri.IsPlaying then digeri:Stop(0.05) end
	end
	local hiz = (y.tepe - y.bas) / 0.1
	iz:Play(0.04, 1, hiz)
	iz.TimePosition = y.bas
	yumrukSayaci[animator] = (yumrukSayaci[animator] or 0) + 1
	local benim = yumrukSayaci[animator]
	task.delay((y.bit - y.bas) / hiz, function()
		if yumrukSayaci[animator] == benim and iz.IsPlaying then
			iz:Stop(0.15)
		end
	end)
	return true
end

local function yumruk(karakter, kombo)
	if yumrukAnim(karakter, kombo) then return end
	local sagOmuz = motorBul(karakter, "RightShoulder", "RightUpperArm")
	local solOmuz = motorBul(karakter, "LeftShoulder", "LeftUpperArm")
	local sagDirsek = motorBul(karakter, "RightElbow", "RightLowerArm")
	local solDirsek = motorBul(karakter, "LeftElbow", "LeftLowerArm")
	local bel = motorBul(karakter, "Waist", "UpperTorso")
	local kalca = motorBul(karakter, "RightHip", "RightUpperLeg")
	-- Olculen eksenler (AnimationConstraint): omuz X+ = kol ileri, sag omuz Z+ = disa (bel donusunu dengeler),
	-- dirsek X+ = bukme, bel Y+ = sag omuz one, bel X- = one egil, kalca X+ = bacak ileri
	-- Boks: once kol gogse cekilir (hazirlik), sonra govde donerek kol firlar, diger el yuzu korur.
	local hazir, vur, tut, don = 0.06, 0.06, 0.07, 0.18
	local gard = A(40, 0, 0)
	local gardDirsek = A(115)
	local function gardPoz(omuz, dirsek, z)
		poz(omuz, gard * A(0, 0, z), 0.07, hazir + vur + tut + 0.1, 0.25)
		poz(dirsek, gardDirsek, 0.07, hazir + vur + tut + 0.1, 0.25)
	end
	if kombo == 1 then
		-- sol direkt (jab)
		gardPoz(sagOmuz, sagDirsek, 10)
		poz(solOmuz, A(35, 0, -8), hazir, 0.3)
		poz(solDirsek, A(120), hazir, 0.3)
		poz(bel, A(0, 10, 0), hazir, 0.3)
		task.delay(hazir, function()
			poz(solOmuz, A(92, 0, -14), vur, tut, don)
			poz(solDirsek, A(0), vur, tut, don)
			poz(bel, A(-8, -18, 0), vur, tut, don)
		end)
	elseif kombo == 2 then
		-- sag kroşe/duz: govde tam doner
		gardPoz(solOmuz, solDirsek, -10)
		poz(sagOmuz, A(30, 0, 10), hazir, 0.3)
		poz(sagDirsek, A(125), hazir, 0.3)
		poz(bel, A(0, -20, 0), hazir, 0.3)
		task.delay(hazir, function()
			poz(sagOmuz, A(92, 0, 18), vur, tut, don)
			poz(sagDirsek, A(0), vur, tut, don)
			poz(bel, A(-12, 30, 0), vur, tut, don)
		end)
	else
		-- sag aparkat: comel, asagidan yukari patlat
		gardPoz(solOmuz, solDirsek, -10)
		poz(sagOmuz, A(10, 0, 12), 0.08, 0.3)
		poz(sagDirsek, A(100), 0.08, 0.3)
		poz(bel, A(-22, -12, 0), 0.08, 0.3)
		poz(kalca, A(-10), 0.08, 0.3)
		task.delay(0.09, function()
			poz(sagOmuz, A(150, 0, 8), 0.07, 0.1, 0.22)
			poz(sagDirsek, A(70), 0.07, 0.1, 0.22)
			poz(bel, A(12, 22, 0), 0.07, 0.1, 0.22)
			poz(kalca, A(30), 0.07, 0.1, 0.22)
		end)
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
