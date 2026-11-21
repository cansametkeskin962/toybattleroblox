-- Dovus sistemi: M1 kombo, blok, yetenekler, itme, hasar, oldurme ve seri bildirimleri.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Veri = require(ServerScriptService:WaitForChild("Veri"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local saldirRemote = remotes:WaitForChild(Config.Remote.Saldir)
local blokRemote = remotes:WaitForChild(Config.Remote.Blok)
local durumRemote = remotes:WaitForChild(Config.Remote.Durum)
local bildirimRemote = remotes:WaitForChild(Config.Remote.Bildirim)
local efektRemote = remotes:WaitForChild(Config.Remote.Efekt)
local beklemeRemote = remotes:WaitForChild(Config.Remote.Bekleme)

local sonSaldiri = {} -- [player] = { M1 = t, Q = t, E = t }
local komboDurum = {} -- [player] = { sayac = 0, sonVurus = 0 }
local blokDurum = {} -- [player] = bool
local seriSayac = {} -- [player] = number

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

local function gecerliVektorMu(v)
	if typeof(v) ~= "Vector3" then
		return false
	end
	if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
		return false
	end
	local mag = v.Magnitude
	return mag > 0.001 and mag < 1e6
end

local function yatayYonBul(hedefYonu, rootPart)
	if gecerliVektorMu(hedefYonu) then
		local yatay = Vector3.new(hedefYonu.X, 0, hedefYonu.Z)
		if yatay.Magnitude > 0.001 then
			return yatay.Unit
		end
	end
	local bakis = rootPart.CFrame.LookVector
	local yatayBakis = Vector3.new(bakis.X, 0, bakis.Z)
	if yatayBakis.Magnitude > 0.001 then
		return yatayBakis.Unit
	end
	return Vector3.new(0, 0, -1)
end

local function karakterBul(parca)
	local suanki = parca and parca.Parent
	while suanki and suanki ~= Workspace do
		local hum = suanki:FindFirstChildOfClass("Humanoid")
		if hum then
			return suanki, hum
		end
		suanki = suanki.Parent
	end
	return nil, nil
end

local function itmeUygula(hedefRoot, hizVektoru, sure)
	if not hedefRoot or not hedefRoot.Parent then
		return
	end
	local att = Instance.new("Attachment")
	att.Parent = hedefRoot

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 100000
	lv.VectorVelocity = hizVektoru
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = hedefRoot

	hedefRoot.AssemblyLinearVelocity = hizVektoru

	Debris:AddItem(lv, sure)
	Debris:AddItem(att, sure)
end

local function hasarVer(hedefChar, miktar, saldiranPlayer)
	if not hedefChar or not hedefChar.Parent then
		return false
	end
	local hedefHum = hedefChar:FindFirstChildOfClass("Humanoid")
	local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
	if not hedefHum or not hedefRoot or hedefHum.Health <= 0 then
		return false
	end

	local sonHasar = miktar
	if hedefChar:GetAttribute("Blok") == true then
		sonHasar = sonHasar * Config.BlokHasarCarpani
	end
	sonHasar = math.max(1, math.round(sonHasar))

	if saldiranPlayer then
		local sonVuranDeger = hedefHum:FindFirstChild("SonVuran")
		if not sonVuranDeger then
			sonVuranDeger = Instance.new("ObjectValue")
			sonVuranDeger.Name = "SonVuran"
			sonVuranDeger.Parent = hedefHum
		end
		sonVuranDeger.Value = saldiranPlayer
		hedefHum:SetAttribute("SonVuranZaman", os.clock())
	end

	hedefHum:TakeDamage(sonHasar)
	efektRemote:FireAllClients("hasar", {
		konum = hedefRoot.Position + Vector3.new(0, 2.5, 0),
		miktar = sonHasar,
	})
	return true
end

local function beklemeKontrolVeBaslat(player, tus, sure)
	local kayit = sonSaldiri[player]
	if not kayit then
		kayit = {}
		sonSaldiri[player] = kayit
	end
	local simdi = os.clock()
	if kayit[tus] and (simdi - kayit[tus]) < sure then
		return false
	end
	kayit[tus] = simdi
	beklemeRemote:FireClient(player, tus, sure)
	return true
end

-- Blok ac/kapat
blokRemote.OnServerEvent:Connect(function(player, aktif)
	if type(aktif) ~= "boolean" then
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum or hum.Health <= 0 then
		blokDurum[player] = false
		return
	end

	blokDurum[player] = aktif
	char:SetAttribute("Blok", aktif)

	local oyuncakAdi = char:GetAttribute("Oyuncak") or Veri.GetSecili(player)
	local oyuncak = Config.Oyuncaklar[oyuncakAdi] or Config.Oyuncaklar.Kovboy
	hum.WalkSpeed = if aktif then 8 else oyuncak.Hiz
end)

-- Saldiri ve yetenek isleyici
saldirRemote.OnServerEvent:Connect(function(player, tus, hedefYonu)
	if tus ~= "M1" and tus ~= "Q" and tus ~= "E" then
		return
	end
	if typeof(hedefYonu) ~= "Vector3" then
		return
	end
	if blokDurum[player] then
		return
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hum or not root or hum.Health <= 0 then
		return
	end

	local oyuncakAdi = char:GetAttribute("Oyuncak") or Veri.GetSecili(player)
	local oyuncak = Config.Oyuncaklar[oyuncakAdi] or Config.Oyuncaklar.Kovboy
	local ayar = oyuncak[tus]
	if not ayar then
		return
	end

	if not beklemeKontrolVeBaslat(player, tus, ayar.Bekleme) then
		return
	end

	local yon = yatayYonBul(hedefYonu, root)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { char }

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }

	-- M1 (3'lu kombo)
	if tus == "M1" then
		local kombo = komboDurum[player]
		if not kombo then
			kombo = { sayac = 0, sonVurus = 0 }
			komboDurum[player] = kombo
		end
		local simdi = os.clock()
		if (simdi - kombo.sonVurus) > Config.KomboSifirlama then
			kombo.sayac = 0
		end
		kombo.sayac = (kombo.sayac % 3) + 1
		kombo.sonVurus = simdi

		local kutuMerkez = root.CFrame * CFrame.new(0, 0, -ayar.Menzil * 0.55)
		local kutuBoyut = Vector3.new(5, 5, ayar.Menzil)
		local parcalar = Workspace:GetPartBoundsInBox(kutuMerkez, kutuBoyut, overlapParams)

		local vurulmuslar = {}
		for _, parca in ipairs(parcalar) do
			local hedefChar, hedefHum = karakterBul(parca)
			if hedefChar and not vurulmuslar[hedefChar] and hedefChar ~= char and hedefHum and hedefHum.Health > 0 then
				vurulmuslar[hedefChar] = true
				local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
				if hasarVer(hedefChar, ayar.Hasar, player) and hedefRoot then
					efektRemote:FireAllClients("vurus", {
						konum = hedefRoot.Position,
						kombo = kombo.sayac,
					})
					if kombo.sayac == 3 then
						local itmeYon = yatayYonBul(hedefRoot.Position - root.Position, root)
						itmeUygula(hedefRoot, itmeYon * ayar.SonVurusItme + Vector3.new(0, 18, 0), 0.18)
					end
				end
			end
		end
		return
	end

	-- Yetenekler (Q ve E)
	if oyuncakAdi == "Kovboy" then
		if tus == "Q" then
			-- Kement: ray ile ilk oyuncuyu bul, hasar + cek
			local baslangic = root.Position + Vector3.new(0, 0.5, 0)
			local sonuc = Workspace:Raycast(baslangic, yon * ayar.Menzil, rayParams)
			local bitis = if sonuc then sonuc.Position else (baslangic + yon * ayar.Menzil)
			local tuttu = false

			if sonuc then
				local hedefChar, hedefHum = karakterBul(sonuc.Instance)
				if hedefChar and hedefChar ~= char and hedefHum and hedefHum.Health > 0 then
					local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
					if hasarVer(hedefChar, ayar.Hasar, player) and hedefRoot then
						tuttu = true
						local cekisYonu = yatayYonBul(root.Position - hedefRoot.Position, hedefRoot)
						itmeUygula(hedefRoot, cekisYonu * 58 + Vector3.new(0, 14, 0), 0.25)
					end
				end
			end

			efektRemote:FireAllClients("kement", {
				baslangic = baslangic,
				bitis = bitis,
				tuttu = tuttu,
			})
		elseif tus == "E" then
			-- Tabanca: ray, hasar + kursun efekti
			local baslangic = root.Position + Vector3.new(0, 0.8, 0)
			local sonuc = Workspace:Raycast(baslangic, yon * ayar.Menzil, rayParams)
			local bitis = if sonuc then sonuc.Position else (baslangic + yon * ayar.Menzil)

			efektRemote:FireAllClients("kursun", {
				baslangic = baslangic,
				bitis = bitis,
			})

			if sonuc then
				local hedefChar, hedefHum = karakterBul(sonuc.Instance)
				if hedefChar and hedefChar ~= char and hedefHum and hedefHum.Health > 0 then
					local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
					if hasarVer(hedefChar, ayar.Hasar, player) and hedefRoot then
						efektRemote:FireAllClients("vurus", {
							konum = hedefRoot.Position,
							kombo = 1,
						})
					end
				end
			end
		end
	elseif oyuncakAdi == "Astronot" then
		if tus == "Q" then
			-- Jetpack: yukari ve ileri guclu itis
			itmeUygula(root, yon * 44 + Vector3.new(0, 68, 0), 0.25)
			efektRemote:FireAllClients("jet", {
				konum = root.Position,
				yon = yon,
				karakter = char,
			})
		elseif tus == "E" then
			-- Yere Carpma: Menzil yaricapinda hasar + yukari/disari itme
			local merkez = root.Position
			local parcalar = Workspace:GetPartBoundsInRadius(merkez, ayar.Menzil, overlapParams)
			local vurulmuslar = {}

			for _, parca in ipairs(parcalar) do
				local hedefChar, hedefHum = karakterBul(parca)
				if hedefChar and not vurulmuslar[hedefChar] and hedefChar ~= char and hedefHum and hedefHum.Health > 0 then
					vurulmuslar[hedefChar] = true
					local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
					if hasarVer(hedefChar, ayar.Hasar, player) and hedefRoot then
						local disYon = yatayYonBul(hedefRoot.Position - merkez, root)
						itmeUygula(hedefRoot, disYon * 45 + Vector3.new(0, 38, 0), 0.22)
					end
				end
			end

			efektRemote:FireAllClients("carpma", {
				konum = merkez - Vector3.new(0, 2.5, 0),
				yaricap = ayar.Menzil,
			})
		end
	elseif oyuncakAdi == "Domuz" then
		if tus == "Q" then
			-- Dalis: 0.4 sn ileri hizli dalis, yolda carptigi ilk oyuncuya hasar + itme
			local dalisHizi = yon * (ayar.Menzil / 0.4)
			itmeUygula(root, dalisHizi, 0.4)
			efektRemote:FireAllClients("dalis", {
				konum = root.Position,
				yon = yon,
				karakter = char,
			})

			task.spawn(function()
				local baslangic = os.clock()
				local vurdu = false
				while not vurdu and (os.clock() - baslangic) < 0.4 and char.Parent and hum.Health > 0 do
					local carpanlar = Workspace:GetPartBoundsInRadius(root.Position, 4.5, overlapParams)
					for _, parca in ipairs(carpanlar) do
						local hedefChar, hedefHum = karakterBul(parca)
						if hedefChar and hedefChar ~= char and hedefHum and hedefHum.Health > 0 then
							local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
							if hasarVer(hedefChar, ayar.Hasar, player) and hedefRoot then
								itmeUygula(hedefRoot, yon * 55 + Vector3.new(0, 26, 0), 0.2)
								efektRemote:FireAllClients("vurus", {
									konum = hedefRoot.Position,
									kombo = 3,
								})
								vurdu = true
								break
							end
						end
					end
					task.wait(0.03)
				end
			end)
		elseif tus == "E" then
			-- Gobek Zipla: ziplayip inince yaricap hasari
			itmeUygula(root, yon * 20 + Vector3.new(0, 58, 0), 0.2)

			task.spawn(function()
				task.wait(0.22)
				local bekleBasla = os.clock()
				while char.Parent and hum.Health > 0 and (os.clock() - bekleBasla) < 2.5 do
					if hum.FloorMaterial ~= Enum.Material.Air then
						break
					end
					task.wait(0.04)
				end

				if not char.Parent or hum.Health <= 0 then
					return
				end

				local inisMerkez = root.Position
				local parcalar = Workspace:GetPartBoundsInRadius(inisMerkez, ayar.Menzil, overlapParams)
				local vurulmuslar = {}
				for _, parca in ipairs(parcalar) do
					local hedefChar, hedefHum = karakterBul(parca)
					if hedefChar and not vurulmuslar[hedefChar] and hedefChar ~= char and hedefHum and hedefHum.Health > 0 then
						vurulmuslar[hedefChar] = true
						local hedefRoot = hedefChar:FindFirstChild("HumanoidRootPart")
						if hasarVer(hedefChar, ayar.Hasar, player) and hedefRoot then
							local disYon = yatayYonBul(hedefRoot.Position - inisMerkez, root)
							itmeUygula(hedefRoot, disYon * 40 + Vector3.new(0, 32, 0), 0.2)
						end
					end
				end

				efektRemote:FireAllClients("carpma", {
					konum = inisMerkez - Vector3.new(0, 2.5, 0),
					yaricap = ayar.Menzil,
				})
			end)
		end
	end
end)

-- Oldurme ve seri takibi
local function karakterDinle(player, char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then
		return
	end

	hum.Died:Connect(function()
		blokDurum[player] = false
		seriSayac[player] = 0

		local sonVuranDeger = hum:FindFirstChild("SonVuran")
		local sonVuranZaman = hum:GetAttribute("SonVuranZaman")
		local katil = sonVuranDeger and sonVuranDeger.Value

		if katil and katil:IsA("Player") and katil ~= player and katil.Parent and type(sonVuranZaman) == "number" then
			if (os.clock() - sonVuranZaman) <= 8 then
				local leaderstats = katil:FindFirstChild("leaderstats")
				if leaderstats then
					local oldurme = leaderstats:FindFirstChild("Oldurme")
					if oldurme then
						oldurme.Value += 1
					end
				end

				Veri.EklePara(katil, Config.OlduruPara)
				task.spawn(Veri.Kaydet, katil)
				durumGonder(katil)

				bildirimRemote:FireAllClients(
					katil.Name .. ", " .. player.Name .. "'yi devirdi!",
					Color3.fromRGB(255, 220, 85)
				)

				local yeniSeri = (seriSayac[katil] or 0) + 1
				seriSayac[katil] = yeniSeri
				if yeniSeri == 3 or yeniSeri == 5 then
					bildirimRemote:FireAllClients(
						katil.Name .. " seride! (" .. tostring(yeniSeri) .. ")",
						Color3.fromRGB(255, 145, 45)
					)
				end
			end
		end
	end)
end

local function oyuncuDinle(player)
	seriSayac[player] = 0
	player.CharacterAdded:Connect(function(char)
		karakterDinle(player, char)
	end)
	if player.Character then
		task.spawn(karakterDinle, player, player.Character)
	end
end
Players.PlayerAdded:Connect(oyuncuDinle)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(oyuncuDinle, p)
end

Players.PlayerRemoving:Connect(function(player)
	sonSaldiri[player] = nil
	komboDurum[player] = nil
	blokDurum[player] = nil
	seriSayac[player] = nil
end)

-- Haritadan dusen (Y < -50) olur
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 and root.Position.Y < -50 then
				hum.Health = 0
			end
		end
	end
end)
