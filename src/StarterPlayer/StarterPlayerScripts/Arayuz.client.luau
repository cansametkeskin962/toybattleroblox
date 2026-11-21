-- Arayuz.client.luau
-- Oyuncak secim ekrani, HUD (para, yetenek kutulari, can bari) ve bildirimler.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local oyuncu = Players.LocalPlayer
local oyuncuGui = oyuncu:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SecimYapRemote = Remotes:WaitForChild(Config.Remote.SecimYap)
local SatinAlRemote = Remotes:WaitForChild(Config.Remote.SatinAl)
local DurumRemote = Remotes:WaitForChild(Config.Remote.Durum)
local BildirimRemote = Remotes:WaitForChild(Config.Remote.Bildirim)
local BeklemeRemote = Remotes:WaitForChild(Config.Remote.Bekleme)

local FONT = Enum.Font.FredokaOne
local RENK = {
	Koyu = Color3.fromRGB(45, 40, 70),
	Beyaz = Color3.fromRGB(255, 255, 255),
	Krem = Color3.fromRGB(255, 250, 240),
	Yesil = Color3.fromRGB(110, 215, 120),
	Sari = Color3.fromRGB(255, 210, 70),
	Kirmizi = Color3.fromRGB(255, 95, 95),
	Gri = Color3.fromRGB(175, 172, 185),
	Mavi = Color3.fromRGB(105, 175, 255),
	Pembe = Color3.fromRGB(255, 130, 185),
	Mor = Color3.fromRGB(165, 130, 255),
	Lila = Color3.fromRGB(240, 235, 255),
	YaziGri = Color3.fromRGB(95, 88, 115),
}
local MOBIL = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local TUSLAR = { "M1", "Q", "E" }
local TUS_METNI = { M1 = MOBIL and "M1" or "TIK", Q = "Q", E = "E" }
local MAKS_BILDIRIM = 4

local durum = { Para = 0, Acik = {}, Secili = nil }

-- ===================== YARDIMCILAR =====================
local function yeni(sinif, ozellikler, ebeveyn)
	local nesne = Instance.new(sinif)
	for ad, deger in pairs(ozellikler) do
		nesne[ad] = deger
	end
	nesne.Parent = ebeveyn
	return nesne
end

local function kose(ebeveyn, yaricap)
	return yeni("UICorner", { CornerRadius = yaricap or UDim.new(0, 16) }, ebeveyn)
end

local function kontur(ebeveyn, kalinlik, renk)
	return yeni("UIStroke", {
		Thickness = kalinlik or 4,
		Color = renk or RENK.Koyu,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, ebeveyn)
end

local function yazi(ebeveyn, ozellikler)
	local etiket = yeni("TextLabel", {
		BackgroundTransparency = 1,
		Font = FONT,
		TextColor3 = RENK.Beyaz,
		TextScaled = true,
		TextStrokeColor3 = RENK.Koyu,
		TextStrokeTransparency = 0,
	}, ebeveyn)
	for ad, deger in pairs(ozellikler) do
		etiket[ad] = deger
	end
	return etiket
end

local function yaziSiniri(ebeveyn, maks)
	return yeni("UITextSizeConstraint", { MaxTextSize = maks }, ebeveyn)
end

local function tween(nesne, sure, hedef, stil, yon)
	local t = TweenService:Create(
		nesne,
		TweenInfo.new(sure, stil or Enum.EasingStyle.Quad, yon or Enum.EasingDirection.Out),
		hedef
	)
	t:Play()
	return t
end

-- ===================== HUD =====================
local hud = yeni("ScreenGui", {
	Name = "OyuncakHUD",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 5,
}, oyuncuGui)

-- Para (sag ust)
local paraKutu = yeni("Frame", {
	Name = "Para",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -16, 0, 12),
	Size = UDim2.fromOffset(170, 56),
	BackgroundColor3 = RENK.Beyaz,
}, hud)
kose(paraKutu, UDim.new(1, 0))
kontur(paraKutu, 4)
local paraOlcek = yeni("UIScale", {}, paraKutu)

local paraDaire = yeni("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 6, 0.5, 0),
	Size = UDim2.fromOffset(44, 44),
	BackgroundColor3 = RENK.Sari,
}, paraKutu)
kose(paraDaire, UDim.new(1, 0))
kontur(paraDaire, 3, Color3.fromRGB(205, 140, 20))
yazi(paraDaire, { Size = UDim2.fromScale(1, 1), Text = "$" })

local paraYazi = yazi(paraKutu, {
	Position = UDim2.new(0, 58, 0, 8),
	Size = UDim2.new(1, -72, 1, -16),
	Text = "0",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = RENK.Koyu,
	TextStrokeTransparency = 1,
})
local paraDegeri = yeni("NumberValue", { Name = "ParaAnimasyon", Value = 0 }, hud)
paraDegeri.Changed:Connect(function(deger)
	paraYazi.Text = tostring(math.floor(deger + 0.5))
end)

-- Oyuncak Degistir butonu (sol ust)
local degistirButonu = yeni("TextButton", {
	Name = "OyuncakDegistir",
	Position = UDim2.fromOffset(16, 12),
	Size = MOBIL and UDim2.fromOffset(180, 46) or UDim2.fromOffset(230, 50),
	BackgroundColor3 = RENK.Pembe,
	Font = FONT,
	Text = MOBIL and "Oyuncak Degistir" or "Oyuncak Degistir (M)",
	TextScaled = true,
	TextColor3 = RENK.Beyaz,
	TextStrokeColor3 = RENK.Koyu,
	TextStrokeTransparency = 0,
	AutoButtonColor = true,
}, hud)
kose(degistirButonu, UDim.new(1, 0))
kontur(degistirButonu, 4)
yaziSiniri(degistirButonu, 24)

-- Alt panel: can bari + yetenek kutulari
local altPanel = yeni("Frame", {
	Name = "AltPanel",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(360, 160),
	BackgroundTransparency = 1,
}, hud)

local canBari = yeni("Frame", {
	Name = "CanBari",
	Size = UDim2.new(1, 0, 0, 38),
	BackgroundColor3 = Color3.fromRGB(70, 62, 95),
}, altPanel)
kose(canBari, UDim.new(1, 0))
kontur(canBari, 4)

local canDolgu = yeni("Frame", {
	Name = "Dolgu",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = RENK.Yesil,
	BorderSizePixel = 0,
}, canBari)
kose(canDolgu, UDim.new(1, 0))
-- parlaklik seridi (oyuncak gibi)
local canParlak = yeni("Frame", {
	Position = UDim2.new(0, 10, 0, 5),
	Size = UDim2.new(1, -20, 0, 7),
	BackgroundColor3 = RENK.Beyaz,
	BackgroundTransparency = 0.6,
	BorderSizePixel = 0,
}, canDolgu)
kose(canParlak, UDim.new(1, 0))

local canYazi = yazi(canBari, {
	Position = UDim2.new(0, 12, 0, 4),
	Size = UDim2.new(1, -24, 1, -8),
	Text = "",
	ZIndex = 3,
})

local yetenekSatiri = yeni("Frame", {
	Name = "Yetenekler",
	Position = UDim2.new(0, 0, 0, 54),
	Size = UDim2.new(1, 0, 0, 104),
	BackgroundTransparency = 1,
}, altPanel)
yeni("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 16),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, yetenekSatiri)

local yetenekKutulari = {} -- [tus] = {Cerceve, Ad, Karartma, Sayac, Olcek, Hazir}
local bekleme = {} -- [tus] = {Bitis, Toplam}

for sira, tus in ipairs(TUSLAR) do
	local cerceve = yeni("Frame", {
		Name = tus,
		LayoutOrder = sira,
		Size = UDim2.fromOffset(100, 100),
		BackgroundColor3 = RENK.Gri,
	}, yetenekSatiri)
	kose(cerceve, UDim.new(0, 22))
	kontur(cerceve, 4)
	local olcek = yeni("UIScale", {}, cerceve)

	yazi(cerceve, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(1, -16, 0, 46),
		Text = TUS_METNI[tus],
	})
	local adSeridi = yeni("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -14, 0, 30),
		BackgroundColor3 = RENK.Beyaz,
	}, cerceve)
	kose(adSeridi, UDim.new(1, 0))
	local adYazi = yazi(adSeridi, {
		Position = UDim2.fromOffset(6, 3),
		Size = UDim2.new(1, -12, 1, -6),
		Text = "-",
		TextColor3 = RENK.Koyu,
		TextStrokeTransparency = 1,
	})

	local karartma = yeni("Frame", {
		Name = "Karartma",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
	}, cerceve)
	kose(karartma, UDim.new(0, 22))
	local sayac = yazi(cerceve, {
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 6,
		Visible = false,
	})
	yaziSiniri(sayac, 42)

	yetenekKutulari[tus] = {
		Cerceve = cerceve,
		Ad = adYazi,
		Karartma = karartma,
		Sayac = sayac,
		Olcek = olcek,
		Hazir = true,
	}
	bekleme[tus] = { Bitis = 0, Toplam = 1 }
end

-- Mobilde: yetenek kutulari gizli (mobil butonlar gosteriyor), can bari sol uste
if MOBIL then
	yetenekSatiri.Visible = false
	altPanel.AnchorPoint = Vector2.new(0, 0)
	altPanel.Position = UDim2.fromOffset(16, 68)
	altPanel.Size = UDim2.fromOffset(230, 38)
end

-- Bildirim alani (ust orta)
local bildirimAlani = yeni("Frame", {
	Name = "Bildirimler",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.new(0.6, 0, 0, MAKS_BILDIRIM * 52),
	BackgroundTransparency = 1,
}, hud)
yeni("UISizeConstraint", { MaxSize = Vector2.new(560, math.huge) }, bildirimAlani)
yeni("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, bildirimAlani)

-- ===================== HUD FONKSIYONLARI =====================
local sonPara = 0
local paraTween = nil

local function paraGuncelle(yeniPara)
	durum.Para = yeniPara
	if paraTween then
		paraTween:Cancel()
		paraTween = nil
	end
	if yeniPara > sonPara then
		paraTween = tween(paraDegeri, 0.45, { Value = yeniPara })
		paraOlcek.Scale = 1.3
		tween(paraOlcek, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		paraDegeri.Value = yeniPara
	end
	sonPara = yeniPara
end

local function canRengi(oran)
	if oran > 0.5 then
		return RENK.Sari:Lerp(RENK.Yesil, (oran - 0.5) / 0.5)
	end
	return RENK.Kirmizi:Lerp(RENK.Sari, oran / 0.5)
end

local aktifInsan = nil
local canBaglantilari = {}

local function canGuncelle()
	local insan = aktifInsan
	if not insan or not insan.Parent then
		canYazi.Text = durum.Secili or ""
		return
	end
	local maks = math.max(insan.MaxHealth, 1)
	local can = math.clamp(insan.Health, 0, maks)
	local oran = can / maks
	tween(canDolgu, 0.2, { Size = UDim2.fromScale(oran, 1), BackgroundColor3 = canRengi(oran) })
	canDolgu.Visible = oran > 0.001
	local metin = tostring(math.ceil(can)) .. " / " .. tostring(math.floor(maks))
	if durum.Secili then
		metin = durum.Secili .. "   " .. metin
	end
	canYazi.Text = metin
end

local function karakterBagla(karakter)
	for _, baglanti in ipairs(canBaglantilari) do
		baglanti:Disconnect()
	end
	table.clear(canBaglantilari)
	aktifInsan = nil

	local insan = karakter:WaitForChild("Humanoid", 10)
	if not insan or not insan:IsA("Humanoid") or oyuncu.Character ~= karakter then
		return
	end
	aktifInsan = insan
	table.insert(canBaglantilari, insan.HealthChanged:Connect(canGuncelle))
	table.insert(canBaglantilari, insan:GetPropertyChangedSignal("MaxHealth"):Connect(canGuncelle))
	canGuncelle()
end

local function yetenekleriGuncelle()
	local veri = durum.Secili and Config.Oyuncaklar[durum.Secili] or nil
	for _, tus in ipairs(TUSLAR) do
		local kutu = yetenekKutulari[tus]
		if veri then
			if tus == "M1" then
				kutu.Ad.Text = "Vurus"
			else
				kutu.Ad.Text = (veri[tus] and veri[tus].Ad) or "-"
			end
			kutu.Cerceve.BackgroundColor3 = veri.Renk:Lerp(RENK.Beyaz, 0.25)
		else
			kutu.Ad.Text = "-"
			kutu.Cerceve.BackgroundColor3 = RENK.Gri
		end
	end
end

-- Bildirim seridi
local bildirimler = {}
local bildirimSayaci = 0

local function bildirimGoster(metin, renk)
	bildirimSayaci += 1
	while #bildirimler >= MAKS_BILDIRIM do
		local eski = table.remove(bildirimler, 1)
		if eski then
			eski:Destroy()
		end
	end

	local tutucu = yeni("Frame", {
		Name = "Bildirim",
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundTransparency = 1,
		LayoutOrder = bildirimSayaci,
	}, bildirimAlani)
	local serit = yeni("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -30),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = renk or RENK.Mavi,
		BackgroundTransparency = 1,
	}, tutucu)
	kose(serit, UDim.new(1, 0))
	local cizgi = kontur(serit, 3)
	cizgi.Transparency = 1
	local etiket = yazi(serit, {
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -32, 1, -12),
		Text = metin,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	yaziSiniri(etiket, 26)
	table.insert(bildirimler, tutucu)

	-- yukaridan kayarak gel
	tween(serit, 0.3, { Position = UDim2.new(0.5, 0, 0, 0), BackgroundTransparency = 0.05 }, Enum.EasingStyle.Back)
	tween(etiket, 0.25, { TextTransparency = 0, TextStrokeTransparency = 0 })
	tween(cizgi, 0.25, { Transparency = 0 })

	task.delay(3, function()
		if not tutucu.Parent then
			return
		end
		tween(serit, 0.3, { Position = UDim2.new(0.5, 0, 0, -20), BackgroundTransparency = 1 })
		tween(etiket, 0.3, { TextTransparency = 1, TextStrokeTransparency = 1 })
		tween(cizgi, 0.3, { Transparency = 1 })
		task.wait(0.3)
		local sira = table.find(bildirimler, tutucu)
		if sira then
			table.remove(bildirimler, sira)
		end
		tutucu:Destroy()
	end)
end

-- ===================== SECIM EKRANI =====================
local secimGui = yeni("ScreenGui", {
	Name = "OyuncakSecim",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 10,
	Enabled = false,
}, oyuncuGui)

local arkaPlan = yeni("Frame", {
	Name = "Arka",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = RENK.Beyaz,
	BackgroundTransparency = 0.15,
	BorderSizePixel = 0,
}, secimGui)
yeni("UIGradient", {
	Rotation = 35,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 230)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 235, 190)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 215, 255)),
	}),
}, arkaPlan)

-- Ekran boyutuna gore olcek (dis) + acilis animasyonu olcegi (ic)
local icerik = yeni("Frame", {
	Name = "Icerik",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(840, 540),
	BackgroundTransparency = 1,
}, secimGui)
local uyumOlcek = yeni("UIScale", {}, icerik)

local animKutu = yeni("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, icerik)
local animOlcek = yeni("UIScale", {}, animKutu)

local function uyumGuncelle()
	local boyut = secimGui.AbsoluteSize
	if boyut.X > 0 and boyut.Y > 0 then
		uyumOlcek.Scale = math.clamp(math.min(boyut.X / 880, boyut.Y / 580), 0.4, 1.25)
	end
end
secimGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(uyumGuncelle)
uyumGuncelle()

local baslik = yazi(animKutu, {
	Size = UDim2.new(1, 0, 0, 72),
	Text = "OYUNCAGINI SEC!",
	TextStrokeTransparency = 1,
})
yeni("UIStroke", { Thickness = 5, Color = RENK.Koyu }, baslik) -- yazi konturu
yaziSiniri(baslik, 64)

local kapatButonu = yeni("TextButton", {
	Name = "Kapat",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -4, 0, 6),
	Size = UDim2.fromOffset(60, 60),
	BackgroundColor3 = RENK.Kirmizi,
	Font = FONT,
	Text = "X",
	TextScaled = true,
	TextColor3 = RENK.Beyaz,
	TextStrokeColor3 = RENK.Koyu,
	TextStrokeTransparency = 0,
	Visible = false,
}, animKutu)
kose(kapatButonu, UDim.new(1, 0))
kontur(kapatButonu, 4)
yaziSiniri(kapatButonu, 34)

local kartSatiri = yeni("Frame", {
	Name = "Kartlar",
	Position = UDim2.fromOffset(0, 88),
	Size = UDim2.new(1, 0, 0, 404),
	BackgroundTransparency = 1,
}, animKutu)
yeni("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 24),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, kartSatiri)

local ipucu = yazi(animKutu, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -4),
	Size = UDim2.new(1, 0, 0, 30),
	Text = MOBIL and "Sol ustteki butonla tekrar acabilirsin" or "M tusu ile bu ekrani tekrar acabilirsin",
})
yaziSiniri(ipucu, 24)

-- Oyuncaklari Sira'ya gore diz
local siraliAdlar = {}
for ad in pairs(Config.Oyuncaklar) do
	table.insert(siraliAdlar, ad)
end
table.sort(siraliAdlar, function(a, b)
	return (Config.Oyuncaklar[a].Sira or 99) < (Config.Oyuncaklar[b].Sira or 99)
end)

local kartlar = {} -- [ad] = {Kart, Buton, Kilit, Olcek}
local secimAcik = false
local secimEkraniniKapat -- ileri tanim

local function oyuncakAcikMi(ad)
	local veri = Config.Oyuncaklar[ad]
	if not veri then
		return false
	end
	return (veri.Fiyat or 0) <= 0 or durum.Acik[ad] == true
end

local function kartGuncelle(ad)
	local kart = kartlar[ad]
	local veri = Config.Oyuncaklar[ad]
	if not kart or not veri then
		return
	end
	local acik = oyuncakAcikMi(ad)
	kart.Kilit.Visible = not acik
	if acik then
		if durum.Secili == ad then
			kart.Buton.Text = "SECILI"
			kart.Buton.BackgroundColor3 = RENK.Mavi
		else
			kart.Buton.Text = "SEC"
			kart.Buton.BackgroundColor3 = RENK.Yesil
		end
		kart.Buton.AutoButtonColor = true
		kart.Cizgi.Color = (durum.Secili == ad) and RENK.Mavi or RENK.Koyu
	else
		kart.Buton.Text = "AC (" .. tostring(veri.Fiyat) .. " para)"
		if durum.Para >= veri.Fiyat then
			kart.Buton.BackgroundColor3 = RENK.Sari
			kart.Buton.AutoButtonColor = true
		else
			kart.Buton.BackgroundColor3 = RENK.Gri
			kart.Buton.AutoButtonColor = false
		end
		kart.Cizgi.Color = RENK.Koyu
	end
end

local function tumKartlariGuncelle()
	for _, ad in ipairs(siraliAdlar) do
		kartGuncelle(ad)
	end
	kapatButonu.Visible = durum.Secili ~= nil
end

for sira, ad in ipairs(siraliAdlar) do
	local veri = Config.Oyuncaklar[ad]

	local kart = yeni("Frame", {
		Name = ad,
		LayoutOrder = sira,
		Size = UDim2.fromOffset(250, 400),
		BackgroundColor3 = RENK.Krem,
	}, kartSatiri)
	kose(kart, UDim.new(0, 26))
	local kartCizgi = kontur(kart, 5)
	local kartOlcek = yeni("UIScale", {}, kart)

	-- renkli daire ikon
	local ikon = yeni("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.fromOffset(104, 104),
		BackgroundColor3 = veri.Renk,
	}, kart)
	kose(ikon, UDim.new(1, 0))
	kontur(ikon, 5)
	local parlak = yeni("Frame", {
		Position = UDim2.fromScale(0.16, 0.12),
		Size = UDim2.fromOffset(28, 20),
		BackgroundColor3 = RENK.Beyaz,
		BackgroundTransparency = 0.35,
	}, ikon)
	kose(parlak, UDim.new(1, 0))
	yazi(ikon, {
		Size = UDim2.fromScale(1, 1),
		Text = string.sub(ad, 1, 1),
	})

	-- kilit rozeti
	local kilit = yazi(kart, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 10),
		Size = UDim2.fromOffset(84, 28),
		BackgroundTransparency = 0,
		BackgroundColor3 = RENK.Kirmizi,
		Rotation = 8,
		Text = "KILITLI",
		Visible = false,
		ZIndex = 3,
	})
	kose(kilit, UDim.new(1, 0))
	kontur(kilit, 3)

	local adYazi = yazi(kart, {
		Position = UDim2.fromOffset(12, 130),
		Size = UDim2.new(1, -24, 0, 40),
		Text = ad,
		TextColor3 = veri.Renk,
	})
	yaziSiniri(adYazi, 36)

	local aciklama = yazi(kart, {
		Position = UDim2.fromOffset(14, 172),
		Size = UDim2.new(1, -28, 0, 62),
		Text = veri.Aciklama or "",
		TextWrapped = true,
		TextColor3 = RENK.YaziGri,
		TextStrokeTransparency = 1,
	})
	yaziSiniri(aciklama, 20)

	local istatistik = yazi(kart, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 240),
		Size = UDim2.new(1, -28, 0, 32),
		BackgroundTransparency = 0,
		BackgroundColor3 = RENK.Lila,
		Text = "Can " .. tostring(veri.Can) .. "   |   Hiz " .. tostring(veri.Hiz),
		TextColor3 = RENK.Koyu,
		TextStrokeTransparency = 1,
	})
	kose(istatistik, UDim.new(1, 0))
	yaziSiniri(istatistik, 20)

	local qAd = veri.Q and veri.Q.Ad or "-"
	local eAd = veri.E and veri.E.Ad or "-"
	local yetenekler = yazi(kart, {
		Position = UDim2.fromOffset(14, 280),
		Size = UDim2.new(1, -28, 0, 50),
		Text = "Q: " .. qAd .. "\nE: " .. eAd,
		TextColor3 = RENK.Mor,
		TextStrokeTransparency = 1,
	})
	yaziSiniri(yetenekler, 22)

	local buton = yeni("TextButton", {
		Name = "Buton",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.new(1, -28, 0, 54),
		BackgroundColor3 = RENK.Yesil,
		Font = FONT,
		Text = "SEC",
		TextScaled = true,
		TextColor3 = RENK.Beyaz,
		TextStrokeColor3 = RENK.Koyu,
		TextStrokeTransparency = 0,
	}, kart)
	kose(buton, UDim.new(0, 18))
	kontur(buton, 4)
	yaziSiniri(buton, 30)

	kartlar[ad] = { Kart = kart, Buton = buton, Kilit = kilit, Olcek = kartOlcek, Cizgi = kartCizgi }

	-- uzerine gelince hafif buyume
	kart.MouseEnter:Connect(function()
		tween(kartOlcek, 0.15, { Scale = 1.05 })
	end)
	kart.MouseLeave:Connect(function()
		tween(kartOlcek, 0.15, { Scale = 1 })
	end)

	buton.Activated:Connect(function()
		if not secimAcik then
			return
		end
		if oyuncakAcikMi(ad) then
			if durum.Secili ~= ad then
				SecimYapRemote:FireServer(ad)
				durum.Secili = ad -- iyimser guncelleme, sunucu Durum ile dogrular
				oyuncu:SetAttribute("SeciliOyuncak", ad)
				yetenekleriGuncelle()
				canGuncelle()
			end
			secimEkraniniKapat()
		elseif durum.Para >= (veri.Fiyat or 0) then
			SatinAlRemote:FireServer(ad)
		else
			bildirimGoster("Yeterli paran yok! " .. tostring(veri.Fiyat) .. " para lazim.", RENK.Kirmizi)
		end
	end)
end

local function secimEkraniniAc()
	secimAcik = true
	oyuncu:SetAttribute("ArayuzAcik", true)
	tumKartlariGuncelle()
	secimGui.Enabled = true
	animOlcek.Scale = 0.85
	tween(animOlcek, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

secimEkraniniKapat = function()
	if not secimAcik then
		return
	end
	secimAcik = false
	oyuncu:SetAttribute("ArayuzAcik", false)
	tween(animOlcek, 0.15, { Scale = 0.85 })
	task.delay(0.15, function()
		if not secimAcik then
			secimGui.Enabled = false
		end
	end)
end

-- ===================== BAGLANTILAR =====================
degistirButonu.Activated:Connect(function()
	if not secimAcik then
		secimEkraniniAc()
	end
end)

kapatButonu.Activated:Connect(function()
	if durum.Secili then
		secimEkraniniKapat()
	end
end)

UserInputService.InputBegan:Connect(function(girdi, oyunIsledi)
	if oyunIsledi then
		return
	end
	if girdi.KeyCode == Enum.KeyCode.M then
		if secimAcik then
			if durum.Secili then
				secimEkraniniKapat()
			end
		else
			secimEkraniniAc()
		end
	end
end)

DurumRemote.OnClientEvent:Connect(function(veri)
	if typeof(veri) ~= "table" then
		return
	end
	if typeof(veri.Para) == "number" then
		paraGuncelle(veri.Para)
	end
	if typeof(veri.Acik) == "table" then
		durum.Acik = veri.Acik
	end
	if typeof(veri.Secili) == "string" and Config.Oyuncaklar[veri.Secili] then
		durum.Secili = veri.Secili
	else
		durum.Secili = nil
	end
	oyuncu:SetAttribute("SeciliOyuncak", durum.Secili)
	yetenekleriGuncelle()
	tumKartlariGuncelle()
	canGuncelle()
end)

BildirimRemote.OnClientEvent:Connect(function(metin, renk)
	if metin == nil then
		return
	end
	bildirimGoster(tostring(metin), typeof(renk) == "Color3" and renk or nil)
end)

BeklemeRemote.OnClientEvent:Connect(function(tus, saniye)
	local b = bekleme[tus]
	if not b or typeof(saniye) ~= "number" or saniye <= 0 then
		return
	end
	b.Bitis = os.clock() + saniye
	b.Toplam = saniye
end)

oyuncu.CharacterAdded:Connect(karakterBagla)
if oyuncu.Character then
	task.spawn(karakterBagla, oyuncu.Character)
end

-- Yetenek kutularinda bekleme karartmasi + geri sayim
RunService.RenderStepped:Connect(function()
	if not yetenekSatiri.Visible then
		return
	end
	local simdi = os.clock()
	for tus, kutu in pairs(yetenekKutulari) do
		local b = bekleme[tus]
		local kalan = b.Bitis - simdi
		if kalan > 0 then
			kutu.Hazir = false
			kutu.Karartma.Visible = true
			kutu.Karartma.Size = UDim2.fromScale(1, math.clamp(kalan / b.Toplam, 0, 1))
			kutu.Sayac.Visible = true
			if kalan >= 1 then
				kutu.Sayac.Text = tostring(math.ceil(kalan))
			else
				kutu.Sayac.Text = string.format("%.1f", kalan)
			end
		elseif not kutu.Hazir then
			-- yetenek hazir: kisa ziplama
			kutu.Hazir = true
			kutu.Karartma.Visible = false
			kutu.Sayac.Visible = false
			kutu.Olcek.Scale = 1.15
			tween(kutu.Olcek, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
end)

-- Baslangic
yetenekleriGuncelle()
canGuncelle()
secimEkraniniAc()
