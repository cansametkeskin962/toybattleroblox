-- Dovus sistemi: sunucu otoriteli M1, Q, R, blok, hasar ve ulti.
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

local sonSaldiri = {}
local komboDurum = {}
local blokDurum = {}
local seriSayac = {}
local aktifR = {}
local sonAim = {}
local stunlar = {}

local function durumGonder(player)
	local veri = Veri.Get(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Para") then
		leaderstats.Para.Value = veri.Para
	end
	local acik = {}
	for ad, acikMi in pairs(veri.Acik) do
		if acikMi then
			acik[ad] = true
		end
	end
	durumRemote:FireClient(player, { Para = veri.Para, Acik = acik, Secili = Veri.GetSecili(player) })
end

local function gecerliVektorMu(v)
	return typeof(v) == "Vector3"
		and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and v.Magnitude > 0.001 and v.Magnitude < 1e6
end

local function yonBul(v, root)
	if gecerliVektorMu(v) then
		return v.Unit
	end
	return root.CFrame.LookVector
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

local function itmeUygula(root, hiz, sure)
	if not root or not root.Parent then return end
	local att = Instance.new("Attachment")
	att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = 100000
	lv.VectorVelocity = hiz
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = root
	root.AssemblyLinearVelocity = hiz
	Debris:AddItem(lv, sure)
	Debris:AddItem(att, sure)
end

local function stun(karakter, sure)
	local hum = karakter and karakter:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end
	local eski = hum.WalkSpeed
	hum.WalkSpeed = 0
	stunlar[karakter] = (stunlar[karakter] or 0) + 1
	task.delay(sure, function()
		if hum.Parent and hum.Health > 0 then
			stunlar[karakter] = math.max((stunlar[karakter] or 1) - 1, 0)
			if stunlar[karakter] == 0 then
				local oyuncak = Config.Oyuncaklar[karakter:GetAttribute("Oyuncak") or "Kovboy"]
				hum.WalkSpeed = oyuncak and oyuncak.Hiz or eski
			end
		end
	end)
end

local function hasarVer(hedefChar, miktar, saldiranPlayer)
	local hum = hedefChar and hedefChar:FindFirstChildOfClass("Humanoid")
	local root = hedefChar and hedefChar:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then return false end
	local sonHasar = miktar
	if hedefChar:GetAttribute("Blok") == true then
		sonHasar *= Config.BlokHasarCarpani
	end
	sonHasar = math.max(1, math.round(sonHasar))
	if saldiranPlayer then
		local sonVuran = hum:FindFirstChild("SonVuran") or Instance.new("ObjectValue")
		sonVuran.Name = "SonVuran"
		sonVuran.Value = saldiranPlayer
		sonVuran.Parent = hum
		hum:SetAttribute("SonVuranZaman", os.clock())
		local saldiranChar = saldiranPlayer.Character
		if saldiranChar then
			saldiranChar:SetAttribute("Ulti", math.clamp((saldiranChar:GetAttribute("Ulti") or 0) + sonHasar * Config.UltiKazanc, 0, 100))
		end
	end
	hum:TakeDamage(sonHasar)
	efektRemote:FireAllClients("hasar", { konum = root.Position + Vector3.new(0, 2.5, 0), miktar = sonHasar })
	return true
end

local function beklemeBaslat(player, tus, sure)
	local kayit = sonSaldiri[player] or {}
	sonSaldiri[player] = kayit
	local simdi = os.clock()
	if kayit[tus] and simdi - kayit[tus] < sure then return false end
	kayit[tus] = simdi
	if sure > 0 then beklemeRemote:FireClient(player, tus, sure) end
	return true
end

local function hedefleriVur(merkez, yaricap, haric, miktar, oyuncu, itme)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { haric }
	local vurulan = {}
	for _, parca in ipairs(Workspace:GetPartBoundsInRadius(merkez, yaricap, params)) do
		local hedef, hum = karakterBul(parca)
		if hedef and hedef ~= haric and not vurulan[hedef] and hum and hum.Health > 0 then
			vurulan[hedef] = true
			local hedefRoot = hedef:FindFirstChild("HumanoidRootPart")
			if hasarVer(hedef, miktar, oyuncu) and hedefRoot and itme then
				local fark = hedefRoot.Position - merkez
				local yatay = Vector3.new(fark.X, 0, fark.Z)
				itmeUygula(hedefRoot, (yatay.Magnitude > 0 and yatay.Unit or Vector3.new(0, 0, -1)) * itme + Vector3.new(0, 26, 0), 0.22)
			end
			if hedefRoot then
				efektRemote:FireAllClients("vurus", { konum = hedefRoot.Position, saldiran = oyuncu })
			end
		end
	end
end

blokRemote.OnServerEvent:Connect(function(player, aktif)
	if type(aktif) ~= "boolean" then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum or hum.Health <= 0 then return end
	blokDurum[player] = aktif
	char:SetAttribute("Blok", aktif)
	local oyuncak = Config.Oyuncaklar[char:GetAttribute("Oyuncak") or Veri.GetSecili(player)] or Config.Oyuncaklar.Kovboy
	hum.WalkSpeed = aktif and 8 or oyuncak.Hiz
end)

saldirRemote.OnServerEvent:Connect(function(player, tus, hedefYonu)
	if tus == "RNisan" then
		if gecerliVektorMu(hedefYonu) and aktifR[player] == "Kovboy" then
			sonAim[player] = hedefYonu.Unit
		end
		return
	end
	if tus ~= "M1" and tus ~= "Q" and tus ~= "R" then return end
	if not gecerliVektorMu(hedefYonu) or blokDurum[player] then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not char or not hum or not root or hum.Health <= 0 then return end
	local oyuncakAdi = char:GetAttribute("Oyuncak") or Veri.GetSecili(player)
	local oyuncak = Config.Oyuncaklar[oyuncakAdi] or Config.Oyuncaklar.Kovboy
	local ayar = oyuncak[tus]
	if not ayar then return end

	if tus == "R" then
		local ulti = char:GetAttribute("Ulti") or 0
		if ulti < 100 then return end
		char:SetAttribute("Ulti", 0)
	else
		local jetAktif = oyuncakAdi == "Astronot" and tus == "Q" and aktifR[player] == "Jet"
		if not jetAktif and not (oyuncakAdi == "Astronot" and tus == "Q") then
			if not beklemeBaslat(player, tus, ayar.Bekleme) then return end
		end
	end

	local yon = yonBul(hedefYonu, root)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { char }

	if tus == "M1" then
		local kombo = komboDurum[player] or { sayac = 0, sonVurus = 0 }
		komboDurum[player] = kombo
		local simdi = os.clock()
		if simdi - kombo.sonVurus > Config.KomboSifirlama then kombo.sayac = 0 end
		kombo.sayac = kombo.sayac % 3 + 1
		kombo.sonVurus = simdi
		efektRemote:FireAllClients("yumruk", { karakter = char, kombo = kombo.sayac })
		local kutu = root.CFrame * CFrame.new(0, 0, -ayar.Menzil * 0.55)
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }
		local vurulan = {}
		for _, parca in ipairs(Workspace:GetPartBoundsInBox(kutu, Vector3.new(5, 5, ayar.Menzil), params)) do
			local hedef, hedefHum = karakterBul(parca)
			if hedef and hedef ~= char and not vurulan[hedef] and hedefHum and hedefHum.Health > 0 then
				vurulan[hedef] = true
				local hedefRoot = hedef:FindFirstChild("HumanoidRootPart")
				if hasarVer(hedef, ayar.Hasar, player) and hedefRoot then
					efektRemote:FireAllClients("vurus", { konum = hedefRoot.Position, saldiran = player })
					if kombo.sayac == 3 then itmeUygula(hedefRoot, yon * ayar.SonVurusItme + Vector3.new(0, 18, 0), 0.18) end
				end
			end
		end
		return
	end

	if oyuncakAdi == "Kovboy" and tus == "Q" then
		local bas = root.Position + Vector3.new(0, 0.7, 0)
		local sonuc = Workspace:Raycast(bas, yon * ayar.Menzil, rayParams)
		local son = sonuc and sonuc.Position or bas + yon * ayar.Menzil
		local tuttu = false
		if sonuc then
			local hedef, hedefHum = karakterBul(sonuc.Instance)
			if hedef and hedef ~= char and hedefHum and hedefHum.Health > 0 then
				local hedefRoot = hedef:FindFirstChild("HumanoidRootPart")
				if hedefRoot and hasarVer(hedef, ayar.Hasar, player) then
					tuttu = true
					hedefRoot.CFrame = CFrame.lookAt(root.Position + yon * 4, root.Position + yon * 5)
					stun(hedef, 0.6)
				end
			end
		end
		efektRemote:FireAllClients("firlat", { karakter = char })
		efektRemote:FireAllClients("kement", { karakter = char, baslangic = bas, bitis = son, tuttu = tuttu })
	elseif oyuncakAdi == "Kovboy" and tus == "R" then
		aktifR[player] = "Kovboy"
		sonAim[player] = yon
		efektRemote:FireAllClients("kolIleri", { karakter = char })
		task.spawn(function()
			local bitis = os.clock() + 3
			local eski = hum.WalkSpeed
			hum.WalkSpeed = eski * 0.5
			while os.clock() < bitis and char.Parent and hum.Health > 0 do
				local aim = sonAim[player] or root.CFrame.LookVector
				for _, el in ipairs({ "RightHand", "LeftHand" }) do
					local parca = char:FindFirstChild(el)
					local bas = parca and parca.Position or root.Position
					local sonuc = Workspace:Raycast(bas, aim * ayar.Menzil, rayParams)
					local son = sonuc and sonuc.Position or bas + aim * ayar.Menzil
					efektRemote:FireAllClients("tabanca", { baslangic = bas, bitis = son })
					if sonuc then
						local hedef = karakterBul(sonuc.Instance)
						if hedef and hedef ~= char then hasarVer(hedef, ayar.Hasar, player) end
					end
				end
				task.wait(0.12)
			end
			if hum.Parent and hum.Health > 0 then hum.WalkSpeed = eski end
			aktifR[player] = nil
		end)
	elseif oyuncakAdi == "Astronot" and tus == "Q" then
		if aktifR[player] == "Jet" then
			aktifR[player] = nil
			return
		end
		aktifR[player] = "Jet"
		efektRemote:FireAllClients("jetBasla", { karakter = char })
		local att = Instance.new("Attachment")
		att.Parent = root
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = att
		lv.MaxForce = 100000
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = root
		local bitis = os.clock() + ayar.Sure
		task.spawn(function()
			while aktifR[player] == "Jet" and os.clock() < bitis and char.Parent and hum.Health > 0 do
				lv.VectorVelocity = hum.MoveDirection * 30 + Vector3.new(0, 28, 0)
				RunService.Heartbeat:Wait()
			end
			if lv.Parent then lv:Destroy() end
			if att.Parent then att:Destroy() end
			aktifR[player] = nil
			efektRemote:FireAllClients("jetBitis", { karakter = char })
			beklemeBaslat(player, "Q", ayar.Bekleme)
		end)
	elseif oyuncakAdi == "Astronot" and tus == "R" then
		local sonuc = Workspace:Raycast(root.Position, yon * ayar.Menzil, rayParams)
		local nokta = sonuc and sonuc.Position or root.Position + yon * ayar.Menzil
		if not sonuc then
			local zemin = Workspace:Raycast(nokta + Vector3.new(0, 80, 0), Vector3.new(0, -180, 0), rayParams)
			nokta = zemin and zemin.Position or nokta
		end
		efektRemote:FireAllClients("lazerUyari", { konum = nokta })
		task.delay(1, function()
			if not char.Parent then return end
			efektRemote:FireAllClients("lazer", { konum = nokta, karakter = char })
			for _ = 1, 10 do
				hedefleriVur(nokta, 8, char, ayar.Hasar, player, nil)
				task.wait(0.2)
			end
		end)
	elseif oyuncakAdi == "Domuz" and tus == "Q" then
		itmeUygula(root, yon * (ayar.Menzil / 0.4), 0.4)
		efektRemote:FireAllClients("dalis", { konum = root.Position, yon = yon, karakter = char })
		task.spawn(function()
			local bas = os.clock()
			while os.clock() - bas < 0.4 and char.Parent and hum.Health > 0 do
				local hedefler = Workspace:GetPartBoundsInRadius(root.Position, 4.5)
				for _, parca in ipairs(hedefler) do
					local hedef = karakterBul(parca)
					if hedef and hedef ~= char and hasarVer(hedef, ayar.Hasar, player) then
						local hedefRoot = hedef:FindFirstChild("HumanoidRootPart")
						if hedefRoot then itmeUygula(hedefRoot, yon * 55 + Vector3.new(0, 26, 0), 0.2) end
						return
					end
				end
				task.wait(0.03)
			end
		end)
	elseif oyuncakAdi == "Domuz" and tus == "R" then
		itmeUygula(root, Vector3.new(0, 70, 0), 0.25)
		efektRemote:FireAllClients("yumrukYere", { karakter = char })
		task.spawn(function()
			task.wait(0.25)
			local bas = os.clock()
			while char.Parent and hum.Health > 0 and os.clock() - bas < 2.5 and hum.FloorMaterial == Enum.Material.Air do task.wait(0.04) end
			if char.Parent and hum.Health > 0 then
				efektRemote:FireAllClients("deprem", { konum = root.Position, karakter = char })
				hedefleriVur(root.Position, 20, char, ayar.Hasar, player, 55)
			end
		end)
	end
end)

local function karakterDinle(player, char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end
	char:SetAttribute("Ulti", 0)
	hum.Died:Connect(function()
		blokDurum[player] = false
		aktifR[player] = nil
		seriSayac[player] = 0
		local sonVuran = hum:FindFirstChild("SonVuran")
		local zaman = hum:GetAttribute("SonVuranZaman")
		local katil = sonVuran and sonVuran.Value
		if katil and katil:IsA("Player") and katil ~= player and katil.Parent and type(zaman) == "number" and os.clock() - zaman <= 8 then
			local ls = katil:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Oldurme") then ls.Oldurme.Value += 1 end
			Veri.EklePara(katil, Config.OlduruPara)
			task.spawn(Veri.Kaydet, katil)
			durumGonder(katil)
			bildirimRemote:FireAllClients(katil.Name .. ", " .. player.Name .. "'yi devirdi!", Color3.fromRGB(255, 220, 85))
		end
	end)
end

local function oyuncuDinle(player)
	seriSayac[player] = 0
	player.CharacterAdded:Connect(function(char) karakterDinle(player, char) end)
	if player.Character then task.spawn(karakterDinle, player, player.Character) end
end
Players.PlayerAdded:Connect(oyuncuDinle)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(oyuncuDinle, player) end
Players.PlayerRemoving:Connect(function(player)
	sonSaldiri[player] = nil
	komboDurum[player] = nil
	blokDurum[player] = nil
	seriSayac[player] = nil
	aktifR[player] = nil
	sonAim[player] = nil
end)

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 and root.Position.Y < -50 then hum.Health = 0 end
	end
end)
