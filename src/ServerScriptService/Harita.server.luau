-- Haritayi kodla kurar: dev cocuk odasi, siperler, platformlar, 8 dogum noktasi ve aydinlatma.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Varsa eski Baseplate veya eski Harita'yi kaldir
local eskiBaseplate = Workspace:FindFirstChild("Baseplate")
if eskiBaseplate then
	eskiBaseplate:Destroy()
end

local eskiHarita = Workspace:FindFirstChild("Harita")
if eskiHarita then
	eskiHarita:Destroy()
end

local harita = Instance.new("Model")
harita.Name = "Harita"
harita.Parent = Workspace

local function parcaOlustur(ozellikler)
	local p = Instance.new(ozellikler.Sinif or "Part")
	p.Name = ozellikler.Ad or "Parca"
	p.Size = ozellikler.Boyut
	p.CFrame = ozellikler.CFrame or CFrame.new(ozellikler.Konum or Vector3.zero)
	p.Color = ozellikler.Renk or Color3.fromRGB(255, 255, 255)
	p.Material = ozellikler.Materyal or Enum.Material.SmoothPlastic
	p.Anchored = if ozellikler.Sabit ~= nil then ozellikler.Sabit else true
	p.CanCollide = if ozellikler.Carpisma ~= nil then ozellikler.Carpisma else true
	p.Transparency = ozellikler.Seffaflik or 0
	if p:IsA("Part") and ozellikler.Sekil then
		p.Shape = ozellikler.Sekil
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = ozellikler.Ebeveyn or harita
	return p
end

-- 1. Zemin (260x260 ahsap zemin, ust yuzey Y = 0)
parcaOlustur({
	Ad = "Zemin",
	Boyut = Vector3.new(260, 4, 260),
	Konum = Vector3.new(0, -2, 0),
	Renk = Color3.fromRGB(196, 150, 102),
	Materyal = Enum.Material.WoodPlanks,
})

-- 2. 4 Duvar (pastel renkler, yuksek)
local duvarBilgi = {
	{ Ad = "DuvarKuzey", Boyut = Vector3.new(268, 80, 4), Konum = Vector3.new(0, 38, -132), Renk = Color3.fromRGB(186, 220, 245) },
	{ Ad = "DuvarGuney", Boyut = Vector3.new(268, 80, 4), Konum = Vector3.new(0, 38, 132), Renk = Color3.fromRGB(186, 220, 245) },
	{ Ad = "DuvarBati", Boyut = Vector3.new(4, 80, 260), Konum = Vector3.new(-132, 38, 0), Renk = Color3.fromRGB(248, 232, 188) },
	{ Ad = "DuvarDogu", Boyut = Vector3.new(4, 80, 260), Konum = Vector3.new(132, 38, 0), Renk = Color3.fromRGB(248, 232, 188) },
}

for _, d in ipairs(duvarBilgi) do
	parcaOlustur(d)
end

-- Oda supurgeligi (duvar dibi beyaz serit)
parcaOlustur({ Ad = "SupurgelikKuzey", Boyut = Vector3.new(260, 3, 0.8), Konum = Vector3.new(0, 1.5, -129.6), Renk = Color3.fromRGB(245, 245, 245) })
parcaOlustur({ Ad = "SupurgelikGuney", Boyut = Vector3.new(260, 3, 0.8), Konum = Vector3.new(0, 1.5, 129.6), Renk = Color3.fromRGB(245, 245, 245) })
parcaOlustur({ Ad = "SupurgelikBati", Boyut = Vector3.new(0.8, 3, 260), Konum = Vector3.new(-129.6, 1.5, 0), Renk = Color3.fromRGB(245, 245, 245) })
parcaOlustur({ Ad = "SupurgelikDogu", Boyut = Vector3.new(0.8, 3, 260), Konum = Vector3.new(129.6, 1.5, 0), Renk = Color3.fromRGB(245, 245, 245) })

-- 3. Ortada Daire Hali (acik dovus alani)
local haliCFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0, math.rad(90))
parcaOlustur({
	Ad = "HaliDis",
	Sekil = Enum.PartType.Cylinder,
	Boyut = Vector3.new(0.24, 68, 68),
	CFrame = haliCFrame,
	Renk = Color3.fromRGB(110, 190, 225),
	Materyal = Enum.Material.Fabric,
})
parcaOlustur({
	Ad = "HaliIc",
	Sekil = Enum.PartType.Cylinder,
	Boyut = Vector3.new(0.28, 44, 44),
	CFrame = CFrame.new(0, 0.14, 0) * CFrame.Angles(0, 0, math.rad(90)),
	Renk = Color3.fromRGB(255, 214, 110),
	Materyal = Enum.Material.Fabric,
})

-- 4. Dev Lego Bloklari (ustune cikilabilir, parlak renkli siper ve yukseklik)
local function legoBlok(ad, konum, boyut, renk, cikintiSatir, cikintiSutun)
	local model = Instance.new("Model")
	model.Name = ad
	model.Parent = harita

	parcaOlustur({
		Ad = "Govde",
		Boyut = boyut,
		Konum = konum,
		Renk = renk,
		Ebeveyn = model,
	})

	-- Ustteki Lego cikintilari (yurumeyi bozmamasi icin CanCollide = false)
	local ustY = konum.Y + boyut.Y * 0.5 + 0.45
	local aralikX = boyut.X / cikintiSatir
	local aralikZ = boyut.Z / cikintiSutun
	for ix = 1, cikintiSatir do
		for iz = 1, cikintiSutun do
			local x = konum.X - boyut.X * 0.5 + aralikX * (ix - 0.5)
			local z = konum.Z - boyut.Z * 0.5 + aralikZ * (iz - 0.5)
			parcaOlustur({
				Ad = "Cikinti",
				Sekil = Enum.PartType.Cylinder,
				Boyut = Vector3.new(0.9, 2.8, 2.8),
				CFrame = CFrame.new(x, ustY, z) * CFrame.Angles(0, 0, math.rad(90)),
				Renk = renk,
				Carpisma = false,
				Ebeveyn = model,
			})
		end
	end
end

-- Guney-Dogu Lego merdiven kulesi
legoBlok("LegoKirmizi", Vector3.new(72, 3, 72), Vector3.new(28, 6, 18), Color3.fromRGB(235, 65, 65), 4, 2)
legoBlok("LegoSari", Vector3.new(82, 8, 72), Vector3.new(18, 6, 16), Color3.fromRGB(250, 210, 50), 2, 2)
legoBlok("LegoMavi", Vector3.new(86, 13.5, 80), Vector3.new(12, 5, 12), Color3.fromRGB(55, 135, 240), 2, 2)

-- Orta cevre siper Legolari
legoBlok("LegoSiperYesil", Vector3.new(46, 2.5, -18), Vector3.new(16, 5, 8), Color3.fromRGB(70, 200, 95), 2, 1)
legoBlok("LegoSiperTuruncu", Vector3.new(-46, 2.5, 18), Vector3.new(8, 5, 16), Color3.fromRGB(255, 145, 50), 1, 2)
legoBlok("LegoSiperMor", Vector3.new(18, 2.5, 48), Vector3.new(16, 5, 8), Color3.fromRGB(165, 95, 225), 2, 1)
legoBlok("LegoSiperCamgobegi", Vector3.new(-18, 2.5, -48), Vector3.new(16, 5, 8), Color3.fromRGB(65, 205, 215), 2, 1)

-- 5. Yatak Platformu (Kuzey-Bati kosesi, yuksek + yaninda rampa)
local yatakModel = Instance.new("Model")
yatakModel.Name = "YatakPlatformu"
yatakModel.Parent = harita

-- Yatak govdesi (ust yuzey Y = 14)
parcaOlustur({
	Ad = "Iskelet",
	Boyut = Vector3.new(50, 10, 70),
	Konum = Vector3.new(-100, 5, -90),
	Renk = Color3.fromRGB(150, 98, 58),
	Materyal = Enum.Material.Wood,
	Ebeveyn = yatakModel,
})
parcaOlustur({
	Ad = "Yatak",
	Boyut = Vector3.new(46, 4, 66),
	Konum = Vector3.new(-100, 12, -90),
	Renk = Color3.fromRGB(245, 245, 250),
	Materyal = Enum.Material.Fabric,
	Ebeveyn = yatakModel,
})
parcaOlustur({
	Ad = "Yorgan",
	Boyut = Vector3.new(47, 1.2, 42),
	Konum = Vector3.new(-100, 14.3, -78),
	Renk = Color3.fromRGB(115, 180, 240),
	Materyal = Enum.Material.Fabric,
	Ebeveyn = yatakModel,
})
parcaOlustur({
	Ad = "Baslik",
	Boyut = Vector3.new(50, 14, 4),
	Konum = Vector3.new(-100, 17, -123),
	Renk = Color3.fromRGB(130, 82, 48),
	Materyal = Enum.Material.Wood,
	Ebeveveyn = yatakModel,
})
parcaOlustur({
	Ad = "Yastik1",
	Boyut = Vector3.new(18, 3, 12),
	Konum = Vector3.new(-111, 15.5, -112),
	Renk = Color3.fromRGB(255, 245, 220),
	Materyal = Enum.Material.Fabric,
	Ebeveyn = yatakModel,
})
parcaOlustur({
	Ad = "Yastik2",
	Boyut = Vector3.new(18, 3, 12),
	Konum = Vector3.new(-89, 15.5, -112),
	Renk = Color3.fromRGB(255, 245, 220),
	Materyal = Enum.Material.Fabric,
	Ebeveyn = yatakModel,
})

-- Yatak rampasi (-X'e dogru yukselir: X = -35'ten -75'e)
parcaOlustur({
	Ad = "YatakRampasi",
	Sinif = "WedgePart",
	Boyut = Vector3.new(14, 14, 40),
	CFrame = CFrame.lookAt(Vector3.new(-55, 7, -75), Vector3.new(-35, 7, -75)),
	Renk = Color3.fromRGB(235, 175, 95),
	Materyal = Enum.Material.Wood,
	Ebeveyn = yatakModel,
})

-- 6. Kitap Yiginindan Rampa / Merdiven (Guney-Bati bolgesi)
local kitapModel = Instance.new("Model")
kitapModel.Name = "KitapMerdiveni"
kitapModel.Parent = harita

local kitaplar = {
	{ Boyut = Vector3.new(34, 3, 24), Konum = Vector3.new(-85, 1.5, 78), Renk = Color3.fromRGB(220, 80, 90) },
	{ Boyut = Vector3.new(28, 3, 20), Konum = Vector3.new(-88, 4.5, 78), Renk = Color3.fromRGB(80, 155, 225) },
	{ Boyut = Vector3.new(22, 3, 18), Konum = Vector3.new(-91, 7.5, 78), Renk = Color3.fromRGB(105, 195, 115) },
	{ Boyut = Vector3.new(16, 3, 16), Konum = Vector3.new(-94, 10.5, 78), Renk = Color3.fromRGB(245, 195, 70) },
	{ Boyut = Vector3.new(12, 3, 14), Konum = Vector3.new(-96, 13.5, 78), Renk = Color3.fromRGB(175, 110, 220) },
}

for i, k in ipairs(kitaplar) do
	parcaOlustur({
		Ad = "Kitap" .. i,
		Boyut = k.Boyut,
		Konum = k.Konum,
		Renk = k.Renk,
		Ebeveyn = kitapModel,
	})
end

-- Kitaplara yasli egik kapak rampasi
parcaOlustur({
	Ad = "KitapRampa",
	Sinif = "WedgePart",
	Boyut = Vector3.new(10, 12, 32),
	CFrame = CFrame.lookAt(Vector3.new(-74, 6, 94), Vector3.new(-58, 6, 94)),
	Renk = Color3.fromRGB(255, 135, 100),
	Ebeveyn = kitapModel,
})

-- 7. Oyuncak Kutusu (Kuzey-Dogu bolgesi, icine girilebilir acik kutu)
local kutuModel = Instance.new("Model")
kutuModel.Name = "OyuncakKutusu"
kutuModel.Parent = harita

local kutuMerkez = Vector3.new(90, 0, -90)
local kutuRenk = Color3.fromRGB(245, 185, 65)
parcaOlustur({ Ad = "Taban", Boyut = Vector3.new(38, 1.5, 38), Konum = kutuMerkez + Vector3.new(0, 0.75, 0), Renk = kutuRenk, Materyal = Enum.Material.Wood, Ebeveyn = kutuModel })
parcaOlustur({ Ad = "OnDuvar", Boyut = Vector3.new(38, 10, 2), Konum = kutuMerkez + Vector3.new(0, 5, 18), Renk = kutuRenk, Materyal = Enum.Material.Wood, Ebeveyn = kutuModel })
parcaOlustur({ Ad = "ArkaDuvar", Boyut = Vector3.new(38, 10, 2), Konum = kutuMerkez + Vector3.new(0, 5, -18), Renk = kutuRenk, Materyal = Enum.Material.Wood, Ebeveyn = kutuModel })
parcaOlustur({ Ad = "SolDuvar", Boyut = Vector3.new(2, 10, 34), Konum = kutuMerkez + Vector3.new(-18, 5, 0), Renk = kutuRenk, Materyal = Enum.Material.Wood, Ebeveyn = kutuModel })
parcaOlustur({ Ad = "SagDuvar", Boyut = Vector3.new(2, 10, 34), Konum = kutuMerkez + Vector3.new(18, 5, 0), Renk = kutuRenk, Materyal = Enum.Material.Wood, Ebeveyn = kutuModel })
-- Kutu kenarina tirmanma rampasi
parcaOlustur({
	Ad = "KutuRampasi",
	Sinif = "WedgePart",
	Boyut = Vector3.new(12, 10, 22),
	CFrame = CFrame.lookAt(kutuMerkez + Vector3.new(-30, 5, 0), kutuMerkez + Vector3.new(-42, 5, 0)),
	Renk = Color3.fromRGB(220, 145, 55),
	Materyal = Enum.Material.Wood,
	Ebeveyn = kutuModel,
})

-- 8. Buyuk SmoothPlastic Toplar (siper ve dekor)
local toplar = {
	{ Ad = "TopKirmizi", Cap = 12, Konum = Vector3.new(-32, 6, 52), Renk = Color3.fromRGB(240, 75, 95) },
	{ Ad = "TopMavi", Cap = 14, Konum = Vector3.new(54, 7, -32), Renk = Color3.fromRGB(75, 165, 245) },
	{ Ad = "TopSari", Cap = 10, Konum = Vector3.new(-52, 5, -34), Renk = Color3.fromRGB(250, 220, 70) },
	{ Ad = "TopMor", Cap = 11, Konum = Vector3.new(34, 5.5, 62), Renk = Color3.fromRGB(185, 110, 235) },
}

for _, t in ipairs(toplar) do
	parcaOlustur({
		Ad = t.Ad,
		Sekil = Enum.PartType.Ball,
		Boyut = Vector3.new(t.Cap, t.Cap, t.Cap),
		Konum = t.Konum,
		Renk = t.Renk,
		Materyal = Enum.Material.SmoothPlastic,
	})
end

-- 9. 8 SpawnLocation (kenarlara dagitilmis, gorunmez, carpisma kapali)
local dogmaKonumlari = {
	Vector3.new(0, 1, -112),
	Vector3.new(45, 1, -108),
	Vector3.new(112, 1, -20),
	Vector3.new(112, 1, 30),
	Vector3.new(0, 1, 112),
	Vector3.new(-45, 1, 108),
	Vector3.new(-112, 1, 20),
	Vector3.new(-112, 1, -30),
}

for i, konum in ipairs(dogmaKonumlari) do
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "DogmaNoktasi" .. i
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = konum
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = harita
end

-- 10. Aydinlatma (Lighting)
Lighting.ClockTime = 14
Lighting.Brightness = 2.5

for _, cocuk in ipairs(Lighting:GetChildren()) do
	if cocuk:IsA("Atmosphere") or cocuk:IsA("BloomEffect") or cocuk:IsA("ColorCorrectionEffect") then
		cocuk:Destroy()
	end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.2
atmosphere.Offset = 0
atmosphere.Haze = 1
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.35
bloom.Size = 24
bloom.Threshold = 1.2
bloom.Parent = Lighting

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Saturation = 0.15
colorCorrection.Contrast = 0.05
colorCorrection.Parent = Lighting
