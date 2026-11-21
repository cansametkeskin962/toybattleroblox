-- Surpriz harita olaylari: Kedi uyandi ve Seker yagmuru.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Veri = require(ServerScriptService:WaitForChild("Veri"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local durumRemote = remotes:WaitForChild(Config.Remote.Durum)
local bildirimRemote = remotes:WaitForChild(Config.Remote.Bildirim)
local efektRemote = remotes:WaitForChild(Config.Remote.Efekt)

local PENCE_YARICAP = 10
local PENCE_HASAR = 35

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

local function yukariItme(root, hiz)
	if not root or not root.Parent then
		return
	end
	local att = Instance.new("Attachment")
	att.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 100000
	lv.VectorVelocity = hiz
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = root

	root.AssemblyLinearVelocity = hiz

	Debris:AddItem(lv, 0.2)
	Debris:AddItem(att, 0.2)
end

local function rastgeleOyuncuKonumuBul()
	local canliKonumlar = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 then
			table.insert(canliKonumlar, root.Position)
		end
	end

	local hedefNokta
	if #canliKonumlar > 0 then
		hedefNokta = canliKonumlar[math.random(1, #canliKonumlar)]
	else
		hedefNokta = Vector3.new(math.random(-50, 50), 8, math.random(-50, 50))
	end

	-- Uyari dairesini zemine/platforma oturtmak icin asagi raycast at
	local rayParams = RaycastParams.new()
	local harita = Workspace:FindFirstChild("Harita")
	if harita then
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = { harita }
	end
	local sonuc = Workspace:Raycast(hedefNokta + Vector3.new(0, 6, 0), Vector3.new(0, -80, 0), rayParams)
	if sonuc then
		return sonuc.Position
	end
	return Vector3.new(hedefNokta.X, 0, hedefNokta.Z)
end

local function kediPencesiOlustur(konum)
	local penceModel = Instance.new("Model")
	penceModel.Name = "KediPencesi"

	local turuncu = Color3.fromRGB(245, 145, 55)
	local beyaz = Color3.fromRGB(250, 245, 240)
	local pembe = Color3.fromRGB(255, 155, 180)

	local function parca(ad, sekil, boyut, ofset, renk)
		local p = Instance.new("Part")
		p.Name = ad
		p.Shape = sekil
		p.Size = boyut
		p.Color = renk
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = CFrame.new(konum + ofset)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = penceModel
		return p
	end

	-- Avuc ve kol (yuvarlak parcalar)
	local merkez = parca("Avuc", Enum.PartType.Ball, Vector3.new(14, 10, 14), Vector3.new(0, 4, 0), turuncu)
	parca("Bilek", Enum.PartType.Cylinder, Vector3.new(30, 11, 11), Vector3.new(0, 20, 0), turuncu).CFrame =
		CFrame.new(konum + Vector3.new(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90))
	parca("BilekUcu", Enum.PartType.Ball, Vector3.new(11, 6, 11), Vector3.new(0, 7, 0), beyaz)

	-- 4 parmak ve pati yastigi
	local parmakOfsetler = {
		Vector3.new(-5.5, 2.5, -5.5),
		Vector3.new(-2, 2.5, -7),
		Vector3.new(2, 2.5, -7),
		Vector3.new(5.5, 2.5, -5.5),
	}
	for i, ofset in ipairs(parmakOfsetler) do
		parca("Parmak" .. i, Enum.PartType.Ball, Vector3.new(4.5, 4.5, 4.5), ofset, beyaz)
		parca("Yastik" .. i, Enum.PartType.Ball, Vector3.new(2.2, 1.5, 2.2), ofset + Vector3.new(0, -1.6, 0), pembe)
	end
	parca("AnaYastik", Enum.PartType.Ball, Vector3.new(6.5, 2, 5.5), Vector3.new(0, 0.5, 0), pembe)

	penceModel.PrimaryPart = merkez
	penceModel.Parent = Workspace
	return penceModel
end

local function penceTasi(penceModel, baslangicY, bitisY, konumXZ, sure)
	local baslangic = os.clock()
	local pivotBas = penceModel:GetPivot()
	local rotasyon = pivotBas - pivotBas.Position
	while true do
		local gecen = os.clock() - baslangic
		local oran = math.clamp(gecen / sure, 0, 1)
		local y = baslangicY + (bitisY - baslangicY) * oran
		penceModel:PivotTo(CFrame.new(konumXZ.X, y, konumXZ.Z) * rotasyon)
		if oran >= 1 then
			break
		end
		task.wait()
	end
end

local function kediOlaviBaslat()
	bildirimRemote:FireAllClients("Kedi uyandi!", Color3.fromRGB(255, 145, 40))
	task.wait(3)

	for _ = 1, 6 do
		local hedefKonum = rastgeleOyuncuKonumuBul()

		-- Kirmizi uyari dairesi (Neon, yari seffaf disk)
		local uyari = Instance.new("Part")
		uyari.Name = "KediUyari"
		uyari.Shape = Enum.PartType.Cylinder
		uyari.Size = Vector3.new(0.3, PENCE_YARICAP * 2, PENCE_YARICAP * 2)
		uyari.CFrame = CFrame.new(hedefKonum + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.rad(90))
		uyari.Color = Color3.fromRGB(255, 45, 45)
		uyari.Material = Enum.Material.Neon
		uyari.Transparency = 0.45
		uyari.Anchored = true
		uyari.CanCollide = false
		uyari.Parent = Workspace

		Debris:AddItem(uyari, 3)
		task.wait(1.2)

		-- Dev kedi pencesi yukaridan iner
		local pence = kediPencesiOlustur(hedefKonum + Vector3.new(0, 42, 0))
		Debris:AddItem(pence, 3)

		local avuc = pence.PrimaryPart
		local inisY = hedefKonum.Y + 4
		local baslangicY = avuc.Position.Y
		penceTasi(pence, baslangicY, inisY, hedefKonum, 0.16)

		-- Carpma aninda daire icindekilere 35 hasar + yukari itme (SonVuran degismez)
		efektRemote:FireAllClients("carpma", {
			konum = hedefKonum,
			yaricap = PENCE_YARICAP,
		})

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local yatayMesafe = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(hedefKonum.X, 0, hedefKonum.Z)).Magnitude
				local dikeyFark = math.abs(root.Position.Y - hedefKonum.Y)
				if yatayMesafe <= PENCE_YARICAP and dikeyFark <= 14 then
					hum:TakeDamage(PENCE_HASAR)
					efektRemote:FireAllClients("hasar", {
						konum = root.Position + Vector3.new(0, 2.5, 0),
						miktar = PENCE_HASAR,
					})
					yukariItme(root, Vector3.new(0, 62, 0))
				end
			end
		end

		if uyari.Parent then
			uyari:Destroy()
		end

		task.wait(1)
		if pence.Parent then
			penceTasi(pence, inisY, baslangicY, hedefKonum, 0.25)
			pence:Destroy()
		end

		task.wait(0.5)
	end
end

local function sekerYagmuruBaslat()
	bildirimRemote:FireAllClients("Seker yagmuru!", Color3.fromRGB(255, 140, 225))

	local renkler = {
		Color3.fromRGB(255, 110, 175),
		Color3.fromRGB(115, 225, 255),
		Color3.fromRGB(255, 230, 100),
		Color3.fromRGB(145, 245, 150),
		Color3.fromRGB(205, 145, 255),
	}

	for i = 1, 15 do
		local seker = Instance.new("Part")
		seker.Name = "Seker" .. i
		seker.Shape = Enum.PartType.Ball
		seker.Size = Vector3.new(2.6, 2.6, 2.6)
		seker.Color = renkler[math.random(1, #renkler)]
		seker.Material = Enum.Material.Neon
		seker.Anchored = false
		seker.CanCollide = true
		seker.Position = Vector3.new(math.random(-90, 90), 65 + math.random(0, 15), math.random(-90, 90))
		seker.Parent = Workspace

		local isik = Instance.new("PointLight")
		isik.Color = seker.Color
		isik.Range = 10
		isik.Brightness = 1.5
		isik.Parent = seker

		local toplandi = false
		seker.Touched:Connect(function(carpan)
			if toplandi or not carpan or not carpan.Parent then
				return
			end
			local player = Players:GetPlayerFromCharacter(carpan.Parent)
			if not player then
				return
			end
			local hum = carpan.Parent:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then
				return
			end

			toplandi = true
			Veri.EklePara(player, 3)
			durumGonder(player)
			bildirimRemote:FireClient(player, "+3 Para! (Seker)", Color3.fromRGB(255, 165, 235))
			seker:Destroy()
		end)

		Debris:AddItem(seker, 30)
		task.wait(0.15)
	end
end

-- Olay dongusu
task.spawn(function()
	local sira = 0
	while true do
		task.wait(Config.OlayAraligi)
		if #Players:GetPlayers() > 0 then
			sira += 1
			if sira % 2 == 1 then
				kediOlaviBaslat()
			else
				sekerYagmuruBaslat()
			end
		end
	end
end)
