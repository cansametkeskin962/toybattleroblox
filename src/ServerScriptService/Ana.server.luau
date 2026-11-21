-- Remotes kurulumu, oyuncu girisi, satin alma, oyuncak secimi ve karakter gorunumu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Veri = require(ServerScriptService:WaitForChild("Veri"))
local Gorunum = require(ServerScriptService:WaitForChild("Gorunum"))

-- Dogma ayarlarinin uygulanmasi
Players.CharacterAutoLoads = true
Players.RespawnTime = Config.DogmaSuresi

-- Remotes klasorunu ve RemoteEvent'leri olustur
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

for _, remoteAdi in pairs(Config.Remote) do
	if not remotes:FindFirstChild(remoteAdi) then
		local re = Instance.new("RemoteEvent")
		re.Name = remoteAdi
		re.Parent = remotes
	end
end

local secimYapRemote = remotes:WaitForChild(Config.Remote.SecimYap)
local satinAlRemote = remotes:WaitForChild(Config.Remote.SatinAl)
local durumRemote = remotes:WaitForChild(Config.Remote.Durum)
local bildirimRemote = remotes:WaitForChild(Config.Remote.Bildirim)

local secimBekleme = {}

local function durumGonder(player)
	local veri = Veri.Get(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local paraDeger = leaderstats:FindFirstChild("Para")
		if paraDeger then
			paraDeger.Value = veri.Para
		end
	end

	local acikKopya = {}
	for ad, acikMi in pairs(veri.Acik) do
		if acikMi then
			acikKopya[ad] = true
		end
	end

	durumRemote:FireClient(player, {
		Para = veri.Para,
		Acik = acikKopya,
		Secili = Veri.GetSecili(player),
	})
end

local function kaynakliParca(ozellikler)
	local p = Instance.new("Part")
	p.Name = ozellikler.Ad or "AksesuarParca"
	p.Size = ozellikler.Boyut
	p.Color = ozellikler.Renk
	p.Material = ozellikler.Materyal or Enum.Material.SmoothPlastic
	p.Transparency = ozellikler.Seffaflik or 0
	p.CanCollide = false
	p.Massless = true
	p.Anchored = false
	if ozellikler.Sekil then
		p.Shape = ozellikler.Sekil
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p:SetAttribute("OyuncakAksesuar", true)

	local bagli = ozellikler.Bagli
	local ofset = ozellikler.Ofset
	p.CFrame = bagli.CFrame * ofset
	p.Parent = ozellikler.Ebeveyn

	local weld = Instance.new("Weld")
	weld.Part0 = bagli
	weld.Part1 = p
	weld.C0 = ofset
	weld.Parent = p

	return p
end

local function gorunumBoya(character, renk)
	for _, cocuk in ipairs(character:GetChildren()) do
		if cocuk:IsA("BasePart") then
			cocuk.Color = renk
		elseif cocuk:IsA("Shirt") or cocuk:IsA("Pants") or cocuk:IsA("ShirtGraphic") then
			cocuk:Destroy()
		elseif cocuk:IsA("Accessory") and not cocuk:GetAttribute("OyuncakAksesuar") then
			cocuk:Destroy()
		end
	end

	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	bodyColors.HeadColor3 = renk
	bodyColors.LeftArmColor3 = renk
	bodyColors.RightArmColor3 = renk
	bodyColors.LeftLegColor3 = renk
	bodyColors.RightLegColor3 = renk
	bodyColors.TorsoColor3 = renk
end

local function aksesuarEkle(character, oyuncakAdi, oyuncak)
	local head = character:FindFirstChild("Head")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not head then
		return
	end

	local aksesuarKlasor = Instance.new("Folder")
	aksesuarKlasor.Name = "OyuncakAksesuarlari"
	aksesuarKlasor.Parent = character

	if oyuncakAdi == "Kovboy" then
		local kahverengi = Color3.fromRGB(115, 68, 34)
		-- Sapka kenari (disk)
		kaynakliParca({
			Ad = "SapkaKenar",
			Sekil = Enum.PartType.Cylinder,
			Boyut = Vector3.new(0.2, 2.7, 2.7),
			Renk = kahverengi,
			Bagli = head,
			Ofset = CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Ebeveyn = aksesuarKlasor,
		})
		-- Sapka ustu (silindir)
		kaynakliParca({
			Ad = "SapkaUst",
			Sekil = Enum.PartType.Cylinder,
			Boyut = Vector3.new(0.95, 1.5, 1.5),
			Renk = kahverengi,
			Bagli = head,
			Ofset = CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Ebeveyn = aksesuarKlasor,
		})
		-- Sapka seridi
		kaynakliParca({
			Ad = "SapkaSerit",
			Sekil = Enum.PartType.Cylinder,
			Boyut = Vector3.new(0.22, 1.56, 1.56),
			Renk = Color3.fromRGB(220, 170, 55),
			Bagli = head,
			Ofset = CFrame.new(0, 0.78, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Ebeveyn = aksesuarKlasor,
		})
	elseif oyuncakAdi == "Astronot" then
		-- Seffaf mavi kask kuresi
		kaynakliParca({
			Ad = "Kask",
			Sekil = Enum.PartType.Ball,
			Boyut = Vector3.new(2.25, 2.25, 2.25),
			Renk = Color3.fromRGB(125, 210, 255),
			Materyal = Enum.Material.Glass,
			Seffaflik = 0.55,
			Bagli = head,
			Ofset = CFrame.new(0, 0.05, 0),
			Ebeveyn = aksesuarKlasor,
		})
		-- Sirtta jetpack kutusu
		if torso then
			kaynakliParca({
				Ad = "JetpackGovde",
				Boyut = Vector3.new(1.35, 1.5, 0.7),
				Renk = Color3.fromRGB(200, 208, 220),
				Bagli = torso,
				Ofset = CFrame.new(0, 0.1, 0.85),
				Ebeveyn = aksesuarKlasor,
			})
			kaynakliParca({
				Ad = "JetpackSol",
				Sekil = Enum.PartType.Cylinder,
				Boyut = Vector3.new(1.3, 0.45, 0.45),
				Renk = Color3.fromRGB(145, 155, 170),
				Bagli = torso,
				Ofset = CFrame.new(-0.42, -0.05, 0.9) * CFrame.Angles(0, 0, math.rad(90)),
				Ebeveyn = aksesuarKlasor,
			})
			kaynakliParca({
				Ad = "JetpackSag",
				Sekil = Enum.PartType.Cylinder,
				Boyut = Vector3.new(1.3, 0.45, 0.45),
				Renk = Color3.fromRGB(145, 155, 170),
				Bagli = torso,
				Ofset = CFrame.new(0.42, -0.05, 0.9) * CFrame.Angles(0, 0, math.rad(90)),
				Ebeveyn = aksesuarKlasor,
			})
		end
	elseif oyuncakAdi == "Domuz" then
		local koyuPembe = Color3.fromRGB(255, 118, 155)
		-- Pembe burun (kucuk silindir)
		kaynakliParca({
			Ad = "DomuzBurun",
			Sekil = Enum.PartType.Cylinder,
			Boyut = Vector3.new(0.45, 0.72, 0.72),
			Renk = koyuPembe,
			Bagli = head,
			Ofset = CFrame.new(0, -0.08, -0.68) * CFrame.Angles(0, math.rad(90), 0),
			Ebeveyn = aksesuarKlasor,
		})
		-- Sol ve sag kulak
		kaynakliParca({
			Ad = "SolKulak",
			Boyut = Vector3.new(0.45, 0.5, 0.25),
			Renk = koyuPembe,
			Bagli = head,
			Ofset = CFrame.new(-0.55, 0.65, -0.05) * CFrame.Angles(0, 0, math.rad(18)),
			Ebeveyn = aksesuarKlasor,
		})
		kaynakliParca({
			Ad = "SagKulak",
			Boyut = Vector3.new(0.45, 0.5, 0.25),
			Renk = koyuPembe,
			Bagli = head,
			Ofset = CFrame.new(0.55, 0.65, -0.05) * CFrame.Angles(0, 0, math.rad(-18)),
			Ebeveyn = aksesuarKlasor,
		})
	end

	-- Bas ustu BillboardGui ile oyuncak adi
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OyuncakEtiket"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(140, 34)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.MaxDistance = 80
	billboard.AlwaysOnTop = false
	billboard.Parent = head

	local etiket = Instance.new("TextLabel")
	etiket.Size = UDim2.fromScale(1, 1)
	etiket.BackgroundTransparency = 1
	etiket.Text = oyuncakAdi
	etiket.TextColor3 = oyuncak.Renk
	etiket.TextStrokeColor3 = Color3.fromRGB(25, 25, 25)
	etiket.TextStrokeTransparency = 0.25
	etiket.Font = Enum.Font.GothamBold
	etiket.TextScaled = true
	etiket.Parent = billboard
end

local function karakterHazirla(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	local head = character:WaitForChild("Head", 5)
	if not humanoid or not head or not character.Parent then
		return
	end

	local oyuncakAdi = Veri.GetSecili(player)
	local oyuncak = Config.Oyuncaklar[oyuncakAdi] or Config.Oyuncaklar.Kovboy
	if not Config.Oyuncaklar[oyuncakAdi] then
		oyuncakAdi = "Kovboy"
	end

	character:SetAttribute("Oyuncak", oyuncakAdi)
	character:SetAttribute("Blok", false)

	humanoid.MaxHealth = oyuncak.Can
	humanoid.Health = oyuncak.Can
	humanoid.WalkSpeed = oyuncak.Hiz

	gorunumBoya(character, oyuncak.Renk)
	aksesuarEkle(character, oyuncakAdi, oyuncak)
	local modelli = Gorunum.Giydir(character, oyuncak)

	-- Gec yuklenen avatar kiyafet/aksesuarlarini da temizle
	local baglanti
	baglanti = character.ChildAdded:Connect(function(cocuk)
		if not character.Parent then
			if baglanti then
				baglanti:Disconnect()
			end
			return
		end
		if cocuk:IsA("Shirt") or cocuk:IsA("Pants") or cocuk:IsA("ShirtGraphic") then
			task.defer(function()
				if cocuk.Parent then
					cocuk:Destroy()
				end
			end)
		elseif cocuk:IsA("Accessory") and not cocuk:GetAttribute("OyuncakAksesuar") then
			task.defer(function()
				if cocuk.Parent then
					cocuk:Destroy()
				end
			end)
		elseif cocuk:IsA("BodyColors") then
			task.defer(function()
				if cocuk.Parent then
					cocuk.HeadColor3 = oyuncak.Renk
					cocuk.LeftArmColor3 = oyuncak.Renk
					cocuk.RightArmColor3 = oyuncak.Renk
					cocuk.LeftLegColor3 = oyuncak.Renk
					cocuk.RightLegColor3 = oyuncak.Renk
					cocuk.TorsoColor3 = oyuncak.Renk
				end
			end)
		elseif cocuk:IsA("BasePart") and cocuk.Name ~= "OyuncakModel" then
			cocuk.Color = oyuncak.Renk
			if modelli then
				cocuk.Transparency = 1
			end
		end
	end)

	character.AncestryChanged:Connect(function(_, yeniEbeveyn)
		if not yeniEbeveyn and baglanti then
			baglanti:Disconnect()
		end
	end)
end

-- Oyuncu girisi
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		karakterHazirla(player, character)
	end)

	local veri = Veri.Yukle(player)
	if not player.Parent then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local oldurme = Instance.new("IntValue")
	oldurme.Name = "Oldurme"
	oldurme.Value = 0
	oldurme.Parent = leaderstats

	local para = Instance.new("IntValue")
	para.Name = "Para"
	para.Value = veri.Para
	para.Parent = leaderstats

	durumGonder(player)

	-- Veri yuklenirken karakter coktan dogmussa guncelle
	if player.Character then
		local mevcutOyuncak = player.Character:GetAttribute("Oyuncak")
		if mevcutOyuncak ~= Veri.GetSecili(player) then
			player:LoadCharacter()
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	secimBekleme[player] = nil
end)

-- Oyuncak secimi
secimYapRemote.OnServerEvent:Connect(function(player, oyuncakAdi)
	if type(oyuncakAdi) ~= "string" then
		return
	end
	if not Config.Oyuncaklar[oyuncakAdi] then
		return
	end

	local simdi = os.clock()
	if secimBekleme[player] and (simdi - secimBekleme[player]) < 0.8 then
		return
	end
	secimBekleme[player] = simdi

	if not Veri.AcikMi(player, oyuncakAdi) then
		bildirimRemote:FireClient(player, "Bu oyuncak kilitli! Once satin al.", Color3.fromRGB(255, 95, 95))
		return
	end

	Veri.SetSecili(player, oyuncakAdi)
	durumGonder(player)
	bildirimRemote:FireClient(player, oyuncakAdi .. " secildi!", Config.Oyuncaklar[oyuncakAdi].Renk)
	player:LoadCharacter()
end)

-- Oyuncak satin alma
satinAlRemote.OnServerEvent:Connect(function(player, oyuncakAdi)
	if type(oyuncakAdi) ~= "string" then
		return
	end
	local oyuncak = Config.Oyuncaklar[oyuncakAdi]
	if not oyuncak then
		return
	end

	if Veri.AcikMi(player, oyuncakAdi) then
		bildirimRemote:FireClient(player, oyuncakAdi .. " zaten acik!", Color3.fromRGB(255, 220, 90))
		return
	end

	local mevcutPara = Veri.GetPara(player)
	if mevcutPara < oyuncak.Fiyat then
		bildirimRemote:FireClient(
			player,
			"Yetersiz para! Gereken: " .. tostring(oyuncak.Fiyat),
			Color3.fromRGB(255, 95, 95)
		)
		return
	end

	Veri.SetPara(player, mevcutPara - oyuncak.Fiyat)
	Veri.Ac(player, oyuncakAdi)
	task.spawn(Veri.Kaydet, player)
	durumGonder(player)
	bildirimRemote:FireClient(player, oyuncakAdi .. " satin alindi!", Color3.fromRGB(100, 235, 130))
end)
