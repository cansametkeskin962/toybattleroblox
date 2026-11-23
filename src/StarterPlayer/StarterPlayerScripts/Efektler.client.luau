-- Efektler.client.luau
-- Sunucudan gelen Efekt olaylarini yerel olarak cizer. Bilinmeyen turler sessizce yoksayilir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local oyuncu = Players.LocalPlayer
local oyuncuGui = oyuncu:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EfektRemote = Remotes:WaitForChild(Config.Remote.Efekt)

local FONT = Enum.Font.FredokaOne
local KOYU = Color3.fromRGB(45, 40, 70)
local BEYAZ = Color3.new(1, 1, 1)
local rastgele = Random.new()
local jetler = {}

-- Yerel efekt parcalari burada durur
local efektKlasoru = Instance.new("Folder")
efektKlasoru.Name = "IstemciEfektleri"
efektKlasoru.Parent = workspace

-- Ekran efektleri (kendi vurus "POP!" isareti)
local efektGui = Instance.new("ScreenGui")
efektGui.Name = "EfektArayuz"
efektGui.ResetOnSpawn = false
efektGui.IgnoreGuiInset = true
efektGui.DisplayOrder = 3
efektGui.Parent = oyuncuGui

-- ===================== YARDIMCILAR =====================
local function parcaYap(ozellikler)
	local parca = Instance.new("Part")
	parca.Anchored = true
	parca.CanCollide = false
	parca.CanQuery = false
	parca.CanTouch = false
	parca.CastShadow = false
	parca.Material = Enum.Material.Neon
	parca.TopSurface = Enum.SurfaceType.Smooth
	parca.BottomSurface = Enum.SurfaceType.Smooth
	for ad, deger in pairs(ozellikler) do
		parca[ad] = deger
	end
	parca.Parent = efektKlasoru
	return parca
end

local function oynat(nesne, sure, hedef, stil, yon)
	local t = TweenService:Create(
		nesne,
		TweenInfo.new(sure, stil or Enum.EasingStyle.Quad, yon or Enum.EasingDirection.Out),
		hedef
	)
	t:Play()
	return t
end

local function bizeUzaklik(konum)
	local karakter = oyuncu.Character
	local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
	if kok then
		return (kok.Position - konum).Magnitude
	end
	local kamera = workspace.CurrentCamera
	if kamera then
		return (kamera.CFrame.Position - konum).Magnitude
	end
	return math.huge
end

-- ===================== KAMERA SARSINTISI =====================
local sarsinti = 0

local function kameraSars(guc)
	sarsinti = math.min(math.max(sarsinti, guc), 1.2)
end

-- Kamera guncellendikten sonra sadece konum kaydirir (bakis yonunu bozmaz)
RunService:BindToRenderStep("OyuncakKameraSarsintisi", Enum.RenderPriority.Camera.Value + 2, function(dt)
	if sarsinti <= 0.01 then
		sarsinti = 0
		return
	end
	local kamera = workspace.CurrentCamera
	if kamera then
		local t = os.clock() * 35
		local ofset = Vector3.new(math.noise(t, 1.3), math.noise(2.7, t), 0) * sarsinti * 2
		kamera.CFrame = kamera.CFrame * CFrame.new(ofset)
	end
	sarsinti *= math.exp(-dt * 7)
end)

-- ===================== KENDI VURUSUM "POP" =====================
local function kendiVurusumMu(konum)
	local son = oyuncu:GetAttribute("SonSaldiriZamani")
	if typeof(son) ~= "number" or os.clock() - son > 0.6 then
		return false
	end
	local karakter = oyuncu.Character
	local kok = karakter and karakter:FindFirstChild("HumanoidRootPart")
	if not kok then
		return false
	end
	local fark = konum - kok.Position
	local mesafe = fark.Magnitude
	if mesafe > 14 or mesafe < 0.5 then
		return false -- cok uzak veya tam ustumuzde (bize vurulmus)
	end
	return kok.CFrame.LookVector:Dot(fark.Unit) > 0.2
end

local function popGoster()
	-- genisleyen halka
	local halka = Instance.new("Frame")
	halka.AnchorPoint = Vector2.new(0.5, 0.5)
	halka.Position = UDim2.fromScale(0.5, 0.5)
	halka.Size = UDim2.fromOffset(22, 22)
	halka.BackgroundTransparency = 1
	halka.Parent = efektGui
	local kose = Instance.new("UICorner")
	kose.CornerRadius = UDim.new(1, 0)
	kose.Parent = halka
	local cizgi = Instance.new("UIStroke")
	cizgi.Thickness = 3
	cizgi.Color = BEYAZ
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cizgi.Parent = halka
	oynat(halka, 0.2, { Size = UDim2.fromOffset(58, 58) })
	oynat(cizgi, 0.2, { Transparency = 1 })
	Debris:AddItem(halka, 0.3)

	-- "POP!" yazisi
	local yazi = Instance.new("TextLabel")
	yazi.AnchorPoint = Vector2.new(0.5, 1)
	yazi.Position = UDim2.new(0.5, rastgele:NextInteger(20, 40), 0.5, -16)
	yazi.Size = UDim2.fromOffset(80, 32)
	yazi.Rotation = rastgele:NextNumber(-15, 15)
	yazi.BackgroundTransparency = 1
	yazi.Font = FONT
	yazi.Text = "POP!"
	yazi.TextScaled = true
	yazi.TextColor3 = Color3.fromRGB(255, 225, 80)
	yazi.Parent = efektGui
	local yaziKontur = Instance.new("UIStroke")
	yaziKontur.Thickness = 2.5
	yaziKontur.Color = KOYU
	yaziKontur.Parent = yazi
	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.4
	olcek.Parent = yazi
	oynat(olcek, 0.12, { Scale = 1.1 }, Enum.EasingStyle.Back)
	task.delay(0.18, function()
		if yazi.Parent then
			oynat(yazi, 0.2, { TextTransparency = 1 })
			oynat(yaziKontur, 0.2, { Transparency = 1 })
		end
	end)
	Debris:AddItem(yazi, 0.45)
end

-- ===================== EFEKTLER =====================
-- Beyaz yildiz patlamasi
local function vurusEfekti(veri)
	local konum = veri.Konum
	if typeof(konum) ~= "Vector3" then
		return
	end

	local kure = parcaYap({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.6,
		Color = BEYAZ,
		Transparency = 0.1,
		CFrame = CFrame.new(konum),
	})
	oynat(kure, 0.18, { Size = Vector3.one * 3.2, Transparency = 1 })
	Debris:AddItem(kure, 0.3)

	-- yildiz isinlari
	for i = 1, 8 do
		local yon = rastgele:NextUnitVector()
		local baslangic = konum + yon * 0.3
		local isin = parcaYap({
			Size = Vector3.new(0.22, 0.22, 0.7),
			Color = (i % 2 == 0) and BEYAZ or Color3.fromRGB(255, 245, 170),
			CFrame = CFrame.lookAt(baslangic, baslangic + yon),
		})
		local hedef = konum + yon * rastgele:NextNumber(2, 3.5)
		oynat(isin, 0.3, {
			CFrame = CFrame.lookAt(hedef, hedef + yon),
			Size = Vector3.new(0.05, 0.05, 0.2),
			Transparency = 1,
		})
		Debris:AddItem(isin, 0.4)
	end

	local mesafe = bizeUzaklik(konum)
	if mesafe < 18 then
		kameraSars(0.25 * (1 - mesafe / 18) + 0.05)
	end
	if kendiVurusumMu(konum) then
		popGoster()
	end
end

-- Sari ince kursun cizgisi
local function kursunEfekti(veri)
	local bas, son = veri.Bas, veri.Son
	if typeof(bas) ~= "Vector3" or typeof(son) ~= "Vector3" then
		return
	end
	local uzunluk = math.min((son - bas).Magnitude, 2048)
	if uzunluk < 0.05 then
		return
	end

	local cizgi = parcaYap({
		Size = Vector3.new(0.12, 0.12, uzunluk),
		Color = Color3.fromRGB(255, 225, 60),
		CFrame = CFrame.lookAt(bas, son) * CFrame.new(0, 0, -uzunluk / 2),
	})
	oynat(cizgi, 0.1, { Transparency = 1, Size = Vector3.new(0.03, 0.03, uzunluk) })
	Debris:AddItem(cizgi, 0.12)

	-- namlu parlamasi
	local parlama = parcaYap({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.7,
		Color = Color3.fromRGB(255, 240, 150),
		CFrame = CFrame.new(bas),
	})
	oynat(parlama, 0.08, { Size = Vector3.one * 1.2, Transparency = 1 })
	Debris:AddItem(parlama, 0.1)
end

-- Jetpack alevi (karakterin arkasindan)
local function jetEfekti(veri)
	local karakter = veri.Karakter
	if typeof(karakter) ~= "Instance" or not karakter:IsA("Model") then
		return
	end
	local kok = karakter:FindFirstChild("HumanoidRootPart") or karakter.PrimaryPart
	if not kok or not kok:IsA("BasePart") then
		return
	end

	for _, x in ipairs({ -0.45, 0.45 }) do
		local ek = Instance.new("Attachment")
		ek.Name = "JetEfekti"
		ek.Position = Vector3.new(x, -0.6, 0.9) -- +Z = karakterin arkasi

		local yayici = Instance.new("ParticleEmitter")
		yayici.Texture = "rbxasset://textures/particles/fire_main.dds"
		yayici.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 150, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 60, 20)),
		})
		yayici.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.1),
			NumberSequenceKeypoint.new(1, 0.2),
		})
		yayici.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		yayici.Lifetime = NumberRange.new(0.25, 0.45)
		yayici.Rate = 80
		yayici.Speed = NumberRange.new(10, 16)
		yayici.SpreadAngle = Vector2.new(12, 12)
		yayici.EmissionDirection = Enum.NormalId.Bottom
		yayici.LightEmission = 0.8
		yayici.Parent = ek
		ek.Parent = kok

		yayici:Emit(12)
		task.delay(0.6, function()
			if yayici.Parent then
				yayici.Enabled = false
			end
		end)
		Debris:AddItem(ek, 1.2) -- kalan parcaciklar sonmeye zaman bulsun
	end
end

local function jetBasla(veri)
	local karakter = veri.Karakter
	if typeof(karakter) ~= "Instance" or not karakter:IsA("Model") then return end
	local kok = karakter:FindFirstChild("HumanoidRootPart") or karakter.PrimaryPart
	if not kok or jetler[karakter] then return end
	local klasor = Instance.new("Folder")
	klasor.Name = "JetParcaciklari"
	klasor.Parent = kok
	for _, x in ipairs({ -0.45, 0.45 }) do
		local ek = Instance.new("Attachment")
		ek.Position = Vector3.new(x, -0.6, 0.9)
		ek.Parent = klasor
		local yayici = Instance.new("ParticleEmitter")
		yayici.Texture = "rbxasset://textures/particles/fire_main.dds"
		yayici.Color = ColorSequence.new(Color3.fromRGB(255, 170, 35))
		yayici.Lifetime = NumberRange.new(0.2, 0.4)
		yayici.Rate = 90
		yayici.Speed = NumberRange.new(9, 15)
		yayici.EmissionDirection = Enum.NormalId.Bottom
		yayici.Parent = ek
	end
	jetler[karakter] = klasor
end

local function jetBitis(veri)
	local klasor = jetler[veri.Karakter]
	if klasor then
		jetler[veri.Karakter] = nil
		klasor:Destroy()
	end
end

-- ===================== KEMENT =====================
local IP_RENGI = Color3.fromRGB(150, 95, 45)

-- Ilmek: halka seklinde dizili kucuk parcalar. yerlestir(cf, yaricap): halka cf'nin XZ duzleminde
local function ilmekYap()
	local parcalar = {}
	for i = 1, 14 do
		parcalar[i] = parcaYap({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.75, 0.2, 0.2),
			Color = IP_RENGI,
			Material = Enum.Material.Fabric,
		})
	end
	local ilmek = {}
	function ilmek.yerlestir(cf, yaricap)
		for i, p in ipairs(parcalar) do
			local a = (i / #parcalar) * math.pi * 2
			local konum = cf * CFrame.new(math.cos(a) * yaricap, 0, math.sin(a) * yaricap)
			-- silindir ekseni X: halkaya teget
			p.Size = Vector3.new(yaricap * 2 * math.pi / #parcalar + 0.1, 0.2, 0.2)
			p.CFrame = konum * CFrame.Angles(0, -a + math.pi / 2, 0)
		end
	end
	function ilmek.sil(sure)
		for _, p in ipairs(parcalar) do
			oynat(p, sure, { Transparency = 1 })
			Debris:AddItem(p, sure + 0.05)
		end
	end
	return ilmek
end

local function ipCiz(ip, a, b)
	local uzunluk = math.max((b - a).Magnitude, 0.05)
	ip.Size = Vector3.new(uzunluk, 0.16, 0.16)
	ip.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -uzunluk / 2) * CFrame.Angles(0, math.rad(90), 0)
end

local function elKonumu(karakter)
	local el = karakter and karakter:FindFirstChild("RightHand")
	return el and el.Position or nil
end

-- Atmadan once basin ustunde donen ilmek
local function kementDon(veri)
	local karakter = veri.Karakter
	if typeof(karakter) ~= "Instance" then return end
	local ilmek = ilmekYap()
	local ip = parcaYap({ Shape = Enum.PartType.Cylinder, Color = IP_RENGI, Material = Enum.Material.Fabric })
	local t0 = os.clock()
	local baglanti
	baglanti = RunService.RenderStepped:Connect(function()
		local gecen = os.clock() - t0
		local el = elKonumu(karakter)
		if gecen > 0.3 or not el then
			baglanti:Disconnect()
			ilmek.sil(0.01)
			ip:Destroy()
			return
		end
		local merkez = CFrame.new(el + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, gecen * 25, 0) * CFrame.new(1.2, 0, 0)
		ilmek.yerlestir(merkez * CFrame.Angles(0.25, 0, 0), 1.4)
		ipCiz(ip, el, merkez.Position)
	end)
end

local function kementEfekti(veri)
	local bas, son = veri.Bas, veri.Son
	if typeof(bas) ~= "Vector3" or typeof(son) ~= "Vector3" then return end
	local karakter = veri.Karakter
	local hedef = veri.Hedef
	local hedefKok = typeof(hedef) == "Instance" and hedef:FindFirstChild("HumanoidRootPart")
	local ilmek = ilmekYap()
	local ip = parcaYap({ Shape = Enum.PartType.Cylinder, Color = IP_RENGI, Material = Enum.Material.Fabric })
	local ucus = 0.15
	local bekle = hedefKok and 0.5 or 0.15
	local t0 = os.clock()
	local baglanti
	baglanti = RunService.RenderStepped:Connect(function()
		local gecen = os.clock() - t0
		local el = elKonumu(karakter) or bas
		local hedefNokta = hedefKok and hedefKok.Parent and hedefKok.Position or son
		if gecen < ucus then
			-- havada: hedefe bakan dik halka
			local a = gecen / ucus
			local konum = bas:Lerp(hedefNokta, a)
			ilmek.yerlestir(CFrame.lookAt(konum, hedefNokta + Vector3.new(0, 0.01, 0)) * CFrame.Angles(math.rad(90), 0, 0), 1.5)
			ipCiz(ip, el, konum)
		elseif gecen < ucus + bekle then
			if hedefKok then
				-- belde sikan halka
				local a = math.min((gecen - ucus) / 0.12, 1)
				ilmek.yerlestir(CFrame.new(hedefNokta + Vector3.new(0, 0.3, 0)), 1.6 - a * 0.5)
			else
				ilmek.yerlestir(CFrame.new(son - Vector3.new(0, (gecen - ucus) * 6, 0)), 1.5)
			end
			ipCiz(ip, el, hedefNokta)
		else
			baglanti:Disconnect()
			ilmek.sil(0.2)
			oynat(ip, 0.2, { Transparency = 1 })
			Debris:AddItem(ip, 0.25)
		end
	end)
end

-- ===================== ASTRONOT ISIN =====================
local function isinSarj(veri)
	local karakter = veri.Karakter
	if typeof(karakter) ~= "Instance" then return end
	local top = parcaYap({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Color = Color3.fromRGB(120, 230, 255) })
	local t0 = os.clock()
	local baglanti
	baglanti = RunService.RenderStepped:Connect(function()
		local gecen = os.clock() - t0
		local silah = karakter:FindFirstChild("GeciciSilah")
		local namlu = silah and silah:FindFirstChild("Namlu", true)
		if gecen > 0.5 or not namlu then
			baglanti:Disconnect()
			top:Destroy()
			return
		end
		top.Size = Vector3.one * (0.3 + gecen * 3)
		top.Transparency = 0.1 + math.sin(gecen * 60) * 0.1
		top.CFrame = CFrame.new(namlu.WorldPosition)
	end)
end

local function isinEfekti(veri)
	local bas, son = veri.Bas, veri.Son
	if typeof(bas) ~= "Vector3" or typeof(son) ~= "Vector3" then return end
	local uzunluk = math.max((son - bas).Magnitude, 1)
	local cf = CFrame.lookAt(bas, son) * CFrame.new(0, 0, -uzunluk / 2) * CFrame.Angles(0, math.rad(90), 0)
	local dis = parcaYap({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(uzunluk, 5, 5), Color = Color3.fromRGB(70, 160, 255), Transparency = 0.45, CFrame = cf })
	local ic = parcaYap({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(uzunluk, 2.2, 2.2), Color = Color3.fromRGB(220, 250, 255), CFrame = cf })
	oynat(dis, 0.45, { Size = Vector3.new(uzunluk, 0.2, 0.2), Transparency = 1 })
	oynat(ic, 0.45, { Size = Vector3.new(uzunluk, 0.1, 0.1), Transparency = 1 })
	Debris:AddItem(dis, 0.5)
	Debris:AddItem(ic, 0.5)
	local patlama = parcaYap({ Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Color = Color3.fromRGB(150, 230, 255), CFrame = CFrame.new(son) })
	oynat(patlama, 0.35, { Size = Vector3.one * 9, Transparency = 1 })
	Debris:AddItem(patlama, 0.4)
	if bizeUzaklik(bas) < 60 then kameraSars(0.9) end
end

local function lazerUyari(veri)
	local konum = veri.Konum
	if typeof(konum) ~= "Vector3" then return end
	local uyari = parcaYap({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.08, 16, 16),
		Color = Color3.fromRGB(255, 45, 45),
		Transparency = 0.35,
		CFrame = CFrame.new(konum + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	oynat(uyari, 1, { Transparency = 0.05, Size = Vector3.new(0.08, 18, 18) })
	Debris:AddItem(uyari, 1.1)
end

local function lazerEfekti(veri)
	local konum = veri.Konum
	if typeof(konum) ~= "Vector3" then return end
	local zemin = parcaYap({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 16, 16),
		Color = Color3.fromRGB(255, 30, 30),
		Transparency = 0.25,
		CFrame = CFrame.new(konum + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	local isin = parcaYap({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(120, 6, 6),
		Color = Color3.fromRGB(255, 40, 40),
		CFrame = CFrame.new(konum + Vector3.new(0, 60, 0)),
	})
	oynat(isin, 2, { Transparency = 1 })
	oynat(zemin, 2, { Transparency = 1 })
	Debris:AddItem(isin, 2.1)
	Debris:AddItem(zemin, 2.1)
	if bizeUzaklik(konum) < 40 then kameraSars(0.8) end
end

-- Yerde genisleyen halka + toz
local function carpmaEfekti(veri)
	local konum = veri.Konum
	if typeof(konum) ~= "Vector3" then
		return
	end
	local yaricap = (typeof(veri.Yaricap) == "number") and math.clamp(veri.Yaricap, 1, 200) or 10

	-- zemini bul (karakterleri ve efektleri yoksay)
	local haric = { efektKlasoru }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			table.insert(haric, p.Character)
		end
	end
	local parametre = RaycastParams.new()
	parametre.FilterType = Enum.RaycastFilterType.Exclude
	parametre.FilterDescendantsInstances = haric
	local sonuc = workspace:Raycast(konum + Vector3.new(0, 2, 0), Vector3.new(0, -14, 0), parametre)
	local zemin = sonuc and sonuc.Position or konum

	-- Neon silindir (silindirin ekseni X, dik cevir)
	local halka = parcaYap({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.25, 1, 1),
		Color = Color3.fromRGB(255, 235, 180),
		Transparency = 0.2,
		CFrame = CFrame.new(zemin + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	oynat(halka, 0.45, { Size = Vector3.new(0.25, yaricap * 2, yaricap * 2), Transparency = 1 })
	Debris:AddItem(halka, 0.5)

	-- ikinci, daha parlak ic dalga
	local ic = parcaYap({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 1, 1),
		Color = Color3.fromRGB(255, 170, 80),
		Transparency = 0.1,
		CFrame = CFrame.new(zemin + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	oynat(ic, 0.3, { Size = Vector3.new(0.3, yaricap * 1.2, yaricap * 1.2), Transparency = 1 })
	Debris:AddItem(ic, 0.35)

	-- ucusan toz parcalari
	for _ = 1, 8 do
		local aci = rastgele:NextNumber(0, math.pi * 2)
		local yatay = Vector3.new(math.cos(aci), 0, math.sin(aci))
		local toz = parcaYap({
			Material = Enum.Material.SmoothPlastic,
			Size = Vector3.one * rastgele:NextNumber(0.4, 0.8),
			Color = Color3.fromRGB(235, 215, 185),
			CFrame = CFrame.new(zemin + yatay * 1.5 + Vector3.new(0, 0.4, 0)),
		})
		local hedef = zemin + yatay * (yaricap * 0.6) + Vector3.new(0, rastgele:NextNumber(1.5, 3.5), 0)
		oynat(toz, 0.45, {
			CFrame = CFrame.new(hedef) * CFrame.Angles(rastgele:NextNumber(0, 3), rastgele:NextNumber(0, 3), 0),
			Size = Vector3.one * 0.1,
			Transparency = 1,
		})
		Debris:AddItem(toz, 0.5)
	end

	local mesafe = bizeUzaklik(zemin)
	local etkiAlani = yaricap * 2.5
	if mesafe < etkiAlani then
		kameraSars(0.6 * (1 - mesafe / etkiAlani) + 0.1)
	end
end

-- Ziplayip yukselen hasar sayisi
local function hasarEfekti(veri)
	local konum, miktar = veri.Konum, veri.Miktar
	if typeof(konum) ~= "Vector3" or typeof(miktar) ~= "number" then
		return
	end

	local ek = Instance.new("Attachment")
	ek.Name = "HasarSayisi"
	ek.Parent = workspace.Terrain
	ek.WorldPosition = konum

	local yanKayma = rastgele:NextNumber(-1, 1)
	local genislik = 80 + math.min(math.abs(miktar), 60)

	local pano = Instance.new("BillboardGui")
	pano.Adornee = ek
	pano.Size = UDim2.fromOffset(genislik, genislik * 0.5)
	pano.StudsOffset = Vector3.new(yanKayma, 1, 0)
	pano.AlwaysOnTop = true
	pano.LightInfluence = 0
	pano.MaxDistance = 150
	pano.Parent = ek

	local etiket = Instance.new("TextLabel")
	etiket.Size = UDim2.fromScale(1, 1)
	etiket.BackgroundTransparency = 1
	etiket.Font = FONT
	etiket.Text = tostring(math.floor(miktar + 0.5))
	etiket.TextScaled = true
	etiket.TextColor3 = BEYAZ
	etiket.Parent = pano

	local kontur = Instance.new("UIStroke")
	kontur.Thickness = 3
	kontur.Color = KOYU
	kontur.Parent = etiket

	local olcek = Instance.new("UIScale")
	olcek.Scale = 0.3
	olcek.Parent = etiket

	-- zipla (Back) + yuksel + kaybol
	oynat(olcek, 0.15, { Scale = 1.25 }, Enum.EasingStyle.Back)
	oynat(pano, 0.8, { StudsOffset = Vector3.new(yanKayma, 3.5, 0) }, Enum.EasingStyle.Back)
	task.delay(0.15, function()
		if etiket.Parent then
			oynat(olcek, 0.15, { Scale = 1 })
		end
	end)
	task.delay(0.5, function()
		if etiket.Parent then
			oynat(etiket, 0.3, { TextTransparency = 1 })
			oynat(kontur, 0.3, { Transparency = 1 })
		end
	end)
	Debris:AddItem(ek, 0.85)
end

-- ===================== DAGITICI =====================
local isleyiciler = {
	vurus = vurusEfekti,
	kursun = kursunEfekti,
	tabanca = kursunEfekti,
	jet = jetEfekti,
	jetBasla = jetBasla,
	jetBitis = jetBitis,
	carpma = carpmaEfekti,
	hasar = hasarEfekti,
	kement = kementEfekti,
	kementDon = kementDon,
	isinSarj = isinSarj,
	isin = isinEfekti,
	lazerUyari = lazerUyari,
	lazer = lazerEfekti,
	deprem = carpmaEfekti,
}

EfektRemote.OnClientEvent:Connect(function(tur, veri)
	if typeof(tur) ~= "string" or typeof(veri) ~= "table" then
		return
	end
	-- sunucu kucuk harfli anahtar gonderiyor: client bicimine cevir
	veri = {
		Konum = veri.Konum or veri.konum,
		Miktar = veri.Miktar or veri.miktar,
		Yaricap = veri.Yaricap or veri.yaricap,
		Karakter = veri.Karakter or veri.karakter,
		Bas = veri.Bas or veri.baslangic,
		Son = veri.Son or veri.bitis,
		Hedef = veri.Hedef or veri.hedef,
	}
	if tur == "dalis" then
		tur = "jet"
	end
	local isleyici = isleyiciler[tur]
	if not isleyici then
		return -- bilinmeyen tur: sessizce yoksay
	end
	local tamam, hata = pcall(isleyici, veri)
	if not tamam then
		warn("[Efektler] " .. tur .. ": " .. tostring(hata))
	end
end)
