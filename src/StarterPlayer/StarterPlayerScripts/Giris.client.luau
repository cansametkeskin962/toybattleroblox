-- Giris.client.luau
-- Oyuncu kontrolleri: M1 / Q / R / Blok (klavye, fare, dokunmatik, oyun kolu),
-- mobil butonlar ve omuz kamerasi (Shift Lock benzeri).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local oyuncu = Players.LocalPlayer
local oyuncuGui = oyuncu:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SaldirRemote = Remotes:WaitForChild(Config.Remote.Saldir)
local BlokRemote = Remotes:WaitForChild(Config.Remote.Blok)
local BeklemeRemote = Remotes:WaitForChild(Config.Remote.Bekleme)

-- ===================== AYARLAR =====================
local OMUZ_KILIDI = true -- karakter kameranin baktigi yone doner (Shift Lock benzeri)
local FAREYI_KILITLE = true -- PC'de fare ekran ortasina kilitlenir (Sol Alt basili = serbest)
local KAMERA_OFSETI = Vector3.new(2.1, 0.6, 0) -- omuz kamerasi kaymasi
local DOKUNMA_MAKS_SURE = 0.25 -- bu sureden kisa dokunus = M1
local DOKUNMA_MAKS_KAYMA = 18 -- piksel; daha fazla kayarsa kamera cevirme sayilir
local VARSAYILAN_BEKLEME = { M1 = 0.35, Q = 5, R = 0 }

local FONT = Enum.Font.FredokaOne
local KOYU = Color3.fromRGB(45, 40, 70)
local BEYAZ = Color3.new(1, 1, 1)

-- ===================== DURUM =====================
local hazirZamani = { M1 = 0, Q = 0, R = 0 } -- tus bu zamandan sonra tekrar kullanilabilir
local m1Kaynaklari = {} -- basili tutulan M1 kaynaklari (fare, mobil buton, kol)
local blokKaynaklari = {} -- basili tutulan blok kaynaklari (F, mobil buton, kol)
local dokunmalar = {} -- [InputObject] = {Zaman, Konum} ekrana yapilan dokunuslar
local basiliGirdiler = {} -- [InputObject] = birakinca calisacak fonksiyon (mobil butonlar)
local blokAktif = false

-- ===================== YARDIMCILAR =====================
local function arayuzAcik()
	return oyuncu:GetAttribute("ArayuzAcik") == true
end

-- Canli karakter varsa karakter, humanoid, kok parcasini dondurur
local function canliKarakter()
	local karakter = oyuncu.Character
	if not karakter then
		return nil
	end
	local insan = karakter:FindFirstChildOfClass("Humanoid")
	local kok = karakter:FindFirstChild("HumanoidRootPart")
	if not insan or not kok or insan.Health <= 0 then
		return nil
	end
	return karakter, insan, kok
end

-- Secili oyuncagin Config'teki bekleme suresi
local function beklemeSuresi(tus)
	local secili = oyuncu:GetAttribute("SeciliOyuncak")
	local veri = (typeof(secili) == "string") and Config.Oyuncaklar[secili] or nil
	if veri and veri[tus] and typeof(veri[tus].Bekleme) == "number" then
		return veri[tus].Bekleme
	end
	return VARSAYILAN_BEKLEME[tus] or 0.5
end

local rNisanBitis = 0 -- R aktifken nisan gonderilir
local sonRNisan = 0

-- Nisan: kameranin ortasindan bakilan noktayi bul, karakterden o noktaya yon ver
local function nisanYonu(kamera)
	local char = oyuncu.Character
	local kok = char and char:FindFirstChild("HumanoidRootPart")
	if not kok then
		return kamera.CFrame.LookVector
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local bas = kamera.CFrame.Position
	local sonuc = workspace:Raycast(bas, kamera.CFrame.LookVector * 300, params)
	local hedef = sonuc and sonuc.Position or (bas + kamera.CFrame.LookVector * 300)
	local yon = hedef - (kok.Position + Vector3.new(0, 0.7, 0))
	if yon.Magnitude < 0.5 then
		return kamera.CFrame.LookVector
	end
	return yon.Unit
end

-- Saldiri gonder (istemci tarafi bekleme kontrolu ile)
local function saldir(tus)
	if arayuzAcik() then
		return false
	end
	if not canliKarakter() then
		return false
	end
	local kamera = workspace.CurrentCamera
	if not kamera then
		return false
	end
	local simdi = os.clock()
	if simdi < (hazirZamani[tus] or 0) then
		return false
	end
	hazirZamani[tus] = simdi + beklemeSuresi(tus)
	oyuncu:SetAttribute("SonSaldiriZamani", simdi)
	SaldirRemote:FireServer(tus, nisanYonu(kamera))
	if tus == "R" then
		rNisanBitis = simdi + 3.5
	end
	return true
end

-- Blok durumunu kaynaklara gore guncelle, sadece degisince sunucuya bildir
local function blokGuncelle()
	local istenen = next(blokKaynaklari) ~= nil and not arayuzAcik() and canliKarakter() ~= nil
	if istenen ~= blokAktif then
		blokAktif = istenen
		BlokRemote:FireServer(blokAktif)
	end
end

-- ===================== ARAYUZ (mobil butonlar + nisangah) =====================
local kontrolGui = Instance.new("ScreenGui")
kontrolGui.Name = "OyuncakKontroller"
kontrolGui.ResetOnSpawn = false
kontrolGui.IgnoreGuiInset = true
kontrolGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
kontrolGui.DisplayOrder = 4
kontrolGui.Parent = oyuncuGui

-- Ekran ortasinda arti nisangah (oyunda hep gorunur). Ayri gui: GuiInset'i yok say, tam kamera merkezi.
local nisanGui = Instance.new("ScreenGui")
nisanGui.Name = "NisanArayuz"
nisanGui.ResetOnSpawn = false
nisanGui.IgnoreGuiInset = true
nisanGui.DisplayOrder = 2
nisanGui.Parent = oyuncuGui
local nisangah = Instance.new("Frame")
nisangah.Name = "Nisangah"
nisangah.AnchorPoint = Vector2.new(0.5, 0.5)
nisangah.Position = UDim2.fromScale(0.5, 0.5)
nisangah.Size = UDim2.fromOffset(30, 30)
nisangah.BackgroundTransparency = 1
nisangah.Visible = false
nisangah.Parent = nisanGui
do
	local function cubuk(boyut, konum)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = boyut
		f.Position = konum
		f.BackgroundColor3 = BEYAZ
		f.BorderSizePixel = 0
		local cizgi = Instance.new("UIStroke")
		cizgi.Thickness = 1.5
		cizgi.Color = KOYU
		cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cizgi.Parent = f
		f.Parent = nisangah
		return f
	end
	local nokta = cubuk(UDim2.fromOffset(5, 5), UDim2.fromScale(0.5, 0.5))
	local kose = Instance.new("UICorner")
	kose.CornerRadius = UDim.new(1, 0)
	kose.Parent = nokta
	cubuk(UDim2.fromOffset(3, 8), UDim2.new(0.5, 0, 0.5, -11))
	cubuk(UDim2.fromOffset(3, 8), UDim2.new(0.5, 0, 0.5, 11))
	cubuk(UDim2.fromOffset(8, 3), UDim2.new(0.5, -11, 0.5, 0))
	cubuk(UDim2.fromOffset(8, 3), UDim2.new(0.5, 11, 0.5, 0))
end

-- Kamera: omuz ustu, daha yakin
oyuncu.CameraMaxZoomDistance = 11
oyuncu.CameraMinZoomDistance = 8
task.delay(1, function()
	oyuncu.CameraMinZoomDistance = 3
end)

-- Sag altta mobil buton kumesi (Roblox'un ziplama butonunun solunda)
local mobilCerceve = Instance.new("Frame")
mobilCerceve.Name = "MobilButonlar"
mobilCerceve.AnchorPoint = Vector2.new(1, 1)
mobilCerceve.Position = UDim2.new(1, -180, 1, -16)
mobilCerceve.Size = UDim2.fromOffset(230, 200)
mobilCerceve.BackgroundTransparency = 1
mobilCerceve.Visible = false
mobilCerceve.Parent = kontrolGui

local mobilOlcek = Instance.new("UIScale")
mobilOlcek.Parent = mobilCerceve

local function mobilOlcekGuncelle()
	local boyut = kontrolGui.AbsoluteSize
	local kisaKenar = math.min(boyut.X, boyut.Y)
	if kisaKenar > 0 then
		mobilOlcek.Scale = math.clamp(kisaKenar / 420, 0.8, 1.25)
	end
end
kontrolGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(mobilOlcekGuncelle)
mobilOlcekGuncelle()

local mobilButonlar = {} -- [tus] = {Buton, Karartma, Renk, AktifRenk}

local function yuvarlakButon(ad, metin, boyut, merkez, renk)
	local buton = Instance.new("TextButton")
	buton.Name = ad
	buton.AnchorPoint = Vector2.new(0.5, 0.5)
	buton.Position = UDim2.fromOffset(merkez.X, merkez.Y)
	buton.Size = UDim2.fromOffset(boyut, boyut)
	buton.BackgroundColor3 = renk
	buton.AutoButtonColor = false
	buton.Font = FONT
	buton.Text = metin
	buton.TextScaled = true
	buton.TextColor3 = BEYAZ
	buton.TextStrokeColor3 = KOYU
	buton.TextStrokeTransparency = 0
	buton.Parent = mobilCerceve

	local kose = Instance.new("UICorner")
	kose.CornerRadius = UDim.new(1, 0)
	kose.Parent = buton

	local cizgi = Instance.new("UIStroke")
	cizgi.Thickness = 4
	cizgi.Color = KOYU
	cizgi.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	cizgi.Parent = buton

	local yaziSiniri = Instance.new("UITextSizeConstraint")
	yaziSiniri.MaxTextSize = math.floor(boyut * 0.34)
	yaziSiniri.Parent = buton

	local olcek = Instance.new("UIScale")
	olcek.Parent = buton

	-- Bekleme karartmasi + geri sayim
	local karartma = Instance.new("TextLabel")
	karartma.Name = "Bekleme"
	karartma.Size = UDim2.fromScale(1, 1)
	karartma.BackgroundColor3 = Color3.new(0, 0, 0)
	karartma.BackgroundTransparency = 0.45
	karartma.Font = FONT
	karartma.Text = ""
	karartma.TextSize = math.floor(boyut * 0.36)
	karartma.TextColor3 = BEYAZ
	karartma.TextStrokeColor3 = KOYU
	karartma.TextStrokeTransparency = 0
	karartma.ZIndex = 2
	karartma.Visible = false
	karartma.Parent = buton
	local karartmaKose = Instance.new("UICorner")
	karartmaKose.CornerRadius = UDim.new(1, 0)
	karartmaKose.Parent = karartma

	return buton, olcek, karartma
end

-- Butona basili tutmayi bagla (dokunma ve fare)
local function basiliBagla(buton, olcek, baslat, bitir)
	buton.InputBegan:Connect(function(girdi)
		local tur = girdi.UserInputType
		if tur ~= Enum.UserInputType.Touch and tur ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if basiliGirdiler[girdi] then
			return
		end
		TweenService:Create(olcek, TweenInfo.new(0.08), { Scale = 0.88 }):Play()
		basiliGirdiler[girdi] = function()
			TweenService:Create(olcek, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			bitir(girdi)
		end
		baslat(girdi)
	end)
end

do
	local tanimlar = {
		{ Tus = "M1", Metin = "M1", Boyut = 96, Merkez = Vector2.new(170, 140), Renk = Color3.fromRGB(255, 120, 120) },
		{ Tus = "Q", Metin = "Q", Boyut = 66, Merkez = Vector2.new(60, 160), Renk = Color3.fromRGB(110, 175, 255) },
		{ Tus = "R", Metin = "R", Boyut = 66, Merkez = Vector2.new(80, 70), Renk = Color3.fromRGB(255, 170, 80) },
		{ Tus = "Blok", Metin = "BLOK", Boyut = 66, Merkez = Vector2.new(170, 40), Renk = Color3.fromRGB(120, 210, 140) },
	}
	for _, t in ipairs(tanimlar) do
		local buton, olcek, karartma = yuvarlakButon(t.Tus .. "Butonu", t.Metin, t.Boyut, t.Merkez, t.Renk)
		mobilButonlar[t.Tus] = {
			Buton = buton,
			Karartma = karartma,
			Renk = t.Renk,
			AktifRenk = Color3.fromRGB(255, 210, 70),
		}
		if t.Tus == "M1" then
			basiliBagla(buton, olcek, function(girdi)
				m1Kaynaklari[girdi] = true
				saldir("M1")
			end, function(girdi)
				m1Kaynaklari[girdi] = nil
			end)
		elseif t.Tus == "Blok" then
			basiliBagla(buton, olcek, function(girdi)
				blokKaynaklari[girdi] = true
				blokGuncelle()
			end, function(girdi)
				blokKaynaklari[girdi] = nil
				blokGuncelle()
			end)
		else
			local tus = t.Tus
			basiliBagla(buton, olcek, function()
				saldir(tus)
			end, function() end)
		end
	end
end

-- ===================== GIRDI =====================
UserInputService.InputBegan:Connect(function(girdi, oyunIsledi)
	local tur = girdi.UserInputType

	-- Dokunmatik: kisa dokunus = M1 (birakinca kontrol edilir)
	if tur == Enum.UserInputType.Touch then
		if not oyunIsledi then
			dokunmalar[girdi] = { Zaman = os.clock(), Konum = girdi.Position }
		end
		return
	end

	if oyunIsledi then
		return -- sohbet yazarken veya arayuze tiklarken yoksay
	end

	if tur == Enum.UserInputType.MouseButton1 then
		m1Kaynaklari.Fare = true
		saldir("M1")
		return
	end

	local tus = girdi.KeyCode
	if tus == Enum.KeyCode.Q or tus == Enum.KeyCode.ButtonX then
		saldir("Q")
	elseif tus == Enum.KeyCode.R or tus == Enum.KeyCode.ButtonY then
		saldir("R")
	elseif tus == Enum.KeyCode.F then
		blokKaynaklari.Klavye = true
		blokGuncelle()
	elseif tus == Enum.KeyCode.ButtonL2 then
		blokKaynaklari.Kol = true
		blokGuncelle()
	elseif tus == Enum.KeyCode.ButtonR2 then
		m1Kaynaklari.Kol = true
		saldir("M1")
	end
end)

UserInputService.InputEnded:Connect(function(girdi)
	-- Mobil buton birakildi mi?
	local birak = basiliGirdiler[girdi]
	if birak then
		basiliGirdiler[girdi] = nil
		birak()
	end

	local tur = girdi.UserInputType
	if tur == Enum.UserInputType.Touch then
		local bilgi = dokunmalar[girdi]
		dokunmalar[girdi] = nil
		if bilgi and not birak then
			local sure = os.clock() - bilgi.Zaman
			local kayma = (girdi.Position - bilgi.Konum).Magnitude
			if sure <= DOKUNMA_MAKS_SURE and kayma <= DOKUNMA_MAKS_KAYMA then
				saldir("M1")
			end
		end
	elseif tur == Enum.UserInputType.MouseButton1 then
		m1Kaynaklari.Fare = nil
	else
		local tus = girdi.KeyCode
		if tus == Enum.KeyCode.F then
			blokKaynaklari.Klavye = nil
			blokGuncelle()
		elseif tus == Enum.KeyCode.ButtonL2 then
			blokKaynaklari.Kol = nil
			blokGuncelle()
		elseif tus == Enum.KeyCode.ButtonR2 then
			m1Kaynaklari.Kol = nil
		end
	end
end)

-- Pencere odagi kaybolursa basili her seyi birak
UserInputService.WindowFocusReleased:Connect(function()
	local eskiler = basiliGirdiler
	basiliGirdiler = {}
	for _, birak in pairs(eskiler) do
		birak()
	end
	table.clear(m1Kaynaklari)
	table.clear(blokKaynaklari)
	table.clear(dokunmalar)
	blokGuncelle()
end)

-- Sunucudan gelen bekleme bilgisi (asil otorite sunucu)
BeklemeRemote.OnClientEvent:Connect(function(tus, saniye)
	if hazirZamani[tus] == nil or typeof(saniye) ~= "number" then
		return
	end
	hazirZamani[tus] = math.max(hazirZamani[tus], os.clock() + math.max(saniye, 0) - 0.05)
end)

-- ===================== DONGULER =====================
RunService.Heartbeat:Connect(function()
	-- Basili tutulan M1 = bekleme bittikce otomatik vurus
	if next(m1Kaynaklari) ~= nil then
		saldir("M1")
	end
	blokGuncelle()

	-- Cifte Tabanca gibi aktif ult ler icin sunucuya guncel 3D nisani gonder.
	local kamera = workspace.CurrentCamera
	local simdiN = os.clock()
	if kamera and oyuncu.Character and simdiN < rNisanBitis and simdiN - sonRNisan > 0.1 then
		sonRNisan = simdiN
		SaldirRemote:FireServer("RNisan", nisanYonu(kamera))
	end

	-- Mobil butonlar
	local goster = UserInputService.TouchEnabled and not arayuzAcik()
	mobilCerceve.Visible = goster
	if goster then
		local simdi = os.clock()
		for tus, bilgi in pairs(mobilButonlar) do
			if tus == "Blok" then
				bilgi.Buton.BackgroundColor3 = blokAktif and bilgi.AktifRenk or bilgi.Renk
			else
				local kalan = (hazirZamani[tus] or 0) - simdi
				if kalan > 0 then
					bilgi.Karartma.Visible = true
					if tus == "M1" then
						bilgi.Karartma.Text = ""
					elseif kalan >= 1 then
						bilgi.Karartma.Text = tostring(math.ceil(kalan))
					else
						bilgi.Karartma.Text = string.format("%.1f", kalan)
					end
				else
					bilgi.Karartma.Visible = false
				end
			end
		end
	end
end)

-- Omuz kamerasi: karakteri kameranin yatay yonune cevir, fareyi kilitle
local omuzInsan = nil -- kilidi uyguladigimiz humanoid
local fareKilitli = false

local function omuzKilidiniBirak()
	if omuzInsan and omuzInsan.Parent then
		omuzInsan.AutoRotate = true
		omuzInsan.CameraOffset = Vector3.zero
	end
	omuzInsan = nil
end

RunService:BindToRenderStep("OyuncakOmuzKamerasi", Enum.RenderPriority.Camera.Value + 1, function()
	local kamera = workspace.CurrentCamera
	local karakter, insan, kok = canliKarakter()
	local aktif = OMUZ_KILIDI
		and kamera ~= nil
		and karakter ~= nil
		and not arayuzAcik()
		and not insan.Sit
		and not insan.PlatformStand

	if aktif then
		if omuzInsan ~= insan then
			omuzKilidiniBirak()
			omuzInsan = insan
		end
		insan.AutoRotate = false
		insan.CameraOffset = KAMERA_OFSETI
		local bakis = kamera.CFrame.LookVector
		local yatay = Vector3.new(bakis.X, 0, bakis.Z)
		if yatay.Magnitude > 0.01 then
			local konum = kok.Position
			kok.CFrame = CFrame.lookAt(konum, konum + yatay.Unit)
		end
	elseif omuzInsan then
		omuzKilidiniBirak()
	end

	-- Fare kilidi sadece fareli cihazda
	local fareCihazi = UserInputService.MouseEnabled
		and UserInputService:GetLastInputType() ~= Enum.UserInputType.Touch
	local kilitle = FAREYI_KILITLE
		and aktif
		and fareCihazi
		and not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)

	if kilitle then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		fareKilitli = true
	elseif fareKilitli then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		fareKilitli = false
	end
	nisangah.Visible = aktif
end)
