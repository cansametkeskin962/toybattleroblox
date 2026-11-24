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

local ultiKilit = {} -- [player] = bu zamana kadar ulti dolmaz

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
		if saldiranChar and not (ultiKilit[saldiranPlayer] and os.clock() < ultiKilit[saldiranPlayer]) then
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

-- Kamera nisaninin dunyadaki noktasi (gogusten nisan yonune ilk carpma)
local function nisanNoktasi(root, aim, menzil, rp)
	local goz = root.Position + Vector3.new(0, 0.7, 0)
	local r = Workspace:Raycast(goz, aim * menzil, rp)
	return r and r.Position or goz + aim * menzil
end

-- Ele gecici silah modeli. Namlu ucu "Namlu" attachment'i. tur: "tabanca" | "isin"
local function silahYap(char, elAdi, tur)
	local el = char:FindFirstChild(elAdi)
	if not el then return nil end
	local model = Instance.new("Model")
	model.Name = "GeciciSilah"
	local function parca(ad, boyut, renk, cf, sekil, malzeme)
		local p = Instance.new("Part")
		p.Name = ad
		p.Size = boyut
		p.Color = renk
		p.Material = malzeme or Enum.Material.SmoothPlastic
		if sekil then p.Shape = sekil end
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		-- silah uzayi: -Z namlu yonu; elde -Y kol ucu yonu
		p.CFrame = el.CFrame * CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(-90), 0, 0) * cf
		local w = Instance.new("WeldConstraint")
		w.Part0 = el
		w.Part1 = p
		w.Parent = p
		p.Parent = model
		return p
	end
	local ucZ
	if tur == "isin" then
		local govde = parca("Govde", Vector3.new(0.6, 0.6, 1.4), Color3.fromRGB(235, 235, 245), CFrame.new(0, 0.25, -0.45))
		parca("Tutamak", Vector3.new(0.35, 0.8, 0.4), Color3.fromRGB(70, 75, 95), CFrame.new(0, -0.2, 0) * CFrame.Angles(math.rad(-15), 0, 0))
		parca("Halka1", Vector3.new(0.15, 0.85, 0.85), Color3.fromRGB(90, 220, 255), CFrame.new(0, 0.25, -0.75) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder, Enum.Material.Neon)
		parca("Halka2", Vector3.new(0.15, 0.85, 0.85), Color3.fromRGB(90, 220, 255), CFrame.new(0, 0.25, -0.35) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder, Enum.Material.Neon)
		parca("Uc", Vector3.new(0.45, 0.45, 0.45), Color3.fromRGB(150, 240, 255), CFrame.new(0, 0.25, -1.2), Enum.PartType.Ball, Enum.Material.Neon)
		ucZ = -1.45
		local _ = govde
	else
		parca("Govde", Vector3.new(0.28, 0.4, 1.1), Color3.fromRGB(70, 70, 80), CFrame.new(0, 0.2, -0.35), nil, Enum.Material.Metal)
		parca("NamluBoru", Vector3.new(0.7, 0.2, 0.2), Color3.fromRGB(45, 45, 50), CFrame.new(0, 0.28, -1.0) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder, Enum.Material.Metal)
		parca("Tutamak", Vector3.new(0.26, 0.65, 0.34), Color3.fromRGB(120, 70, 35), CFrame.new(0, -0.2, 0.05) * CFrame.Angles(math.rad(-15), 0, 0), nil, Enum.Material.Wood)
		parca("Tetik", Vector3.new(0.08, 0.2, 0.2), Color3.fromRGB(40, 40, 45), CFrame.new(0, -0.05, -0.25))
		ucZ = -1.38
	end
	local ref = model:FindFirstChild("Govde")
	local namlu = Instance.new("Attachment")
	namlu.Name = "Namlu"
	namlu.Parent = ref
	namlu.WorldCFrame = el.CFrame * CFrame.new(0, -0.35, 0) * CFrame.Angles(math.rad(-90), 0, 0) * CFrame.new(0, tur == "isin" and 0.25 or 0.28, ucZ)
	model.Parent = char
	return model
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
		if gecerliVektorMu(hedefYonu) and (aktifR[player] == "Kovboy" or aktifR[player] == "Isin") then
			local a = hedefYonu.Unit
			if a.Y < 0 then a = Vector3.new(a.X, 0, a.Z).Unit end
			sonAim[player] = a
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
		if Config.UltiTest then
			if os.clock() < (ultiKilit[player] or 0) then return end
		elseif ulti < 100 then
			return
		end
		char:SetAttribute("Ulti", Config.UltiTest and 100 or 0)
		ultiKilit[player] = os.clock() + 6 -- ulti kendi hasariyla dolmasin
	else
		local jetAktif = oyuncakAdi == "Astronot" and tus == "Q" and aktifR[player] == "Jet"
		if not jetAktif and not (oyuncakAdi == "Astronot" and tus == "Q") then
			if not beklemeBaslat(player, tus, ayar.Bekleme) then return end
		end
	end

	local yon = yonBul(hedefYonu, root)
	-- asagi nisan yere carpmasin: yukari serbest, asagi yok
	if yon.Y < 0 and oyuncakAdi == "Kovboy" then
		local duz = Vector3.new(yon.X, 0, yon.Z)
		yon = duz.Magnitude > 0.01 and duz.Unit or root.CFrame.LookVector
	end
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
		-- vururken kucuk bir adim ileri
		local ileri = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if ileri.Magnitude > 0.1 then itmeUygula(root, ileri.Unit * (kombo.sayac == 3 and 26 or 18), 0.08) end
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
		-- once ilmek basin ustunde doner, 0.3 sn sonra savrulur
		efektRemote:FireAllClients("firlat", { karakter = char })
		efektRemote:FireAllClients("kementDon", { karakter = char })
		task.delay(0.3, function()
			if not char.Parent or hum.Health <= 0 then return end
			local el = char:FindFirstChild("RightHand")
			local bas = el and el.Position or root.Position + Vector3.new(0, 1, 0)
			local aim = yon
			-- yumusak nisan: nisana Yardim derece yakin dusman varsa ona kilitlen
			local enIyi, enIyiDot = nil, math.cos(math.rad(ayar.Yardim or 12))
			for _, aday in ipairs(Workspace:GetDescendants()) do
				if aday:IsA("Humanoid") and aday.Health > 0 and aday.Parent ~= char then
					local aRoot = aday.Parent:FindFirstChild("HumanoidRootPart")
					if aRoot then
						local fark = aRoot.Position - bas
						if fark.Magnitude <= ayar.Menzil and fark.Magnitude > 0.1 then
							local d = fark.Unit:Dot(yon)
							if d > enIyiDot then
								local gorus = Workspace:Raycast(bas, fark, rayParams)
								if not gorus or gorus.Instance:IsDescendantOf(aday.Parent) then
									enIyi, enIyiDot = aday.Parent, d
								end
							end
						end
					end
				end
			end
			local hedef, hedefRoot
			local son
			if enIyi then
				hedef = enIyi
				hedefRoot = enIyi:FindFirstChild("HumanoidRootPart")
				son = hedefRoot.Position
			else
				local sonuc = Workspace:Spherecast(bas, 2, aim * ayar.Menzil, rayParams)
				son = sonuc and sonuc.Position or bas + aim * ayar.Menzil
				if sonuc then
					local h, hHum = karakterBul(sonuc.Instance)
					if h and h ~= char and hHum and hHum.Health > 0 then
						hedef, hedefRoot = h, h:FindFirstChild("HumanoidRootPart")
					end
				end
			end
			local tuttu = false
			if hedef and hedefRoot and hasarVer(hedef, ayar.Hasar, player) then
				tuttu = true
				stun(hedef, 0.9)
			end
			efektRemote:FireAllClients("kement", { karakter = char, baslangic = bas, bitis = son, tuttu = tuttu, hedef = tuttu and hedef or nil })
			if tuttu then
				-- 0.15 sn ilmek ucar, sonra 0.3 sn'de cek
				task.wait(0.15)
				local cekBas = hedefRoot.Position
				local t0 = os.clock()
				while os.clock() - t0 < 0.3 and hedefRoot.Parent and root.Parent do
					local a = (os.clock() - t0) / 0.3
					local varis = root.Position + root.CFrame.LookVector * 4
					local p = cekBas:Lerp(varis, a) + Vector3.new(0, math.sin(a * math.pi) * 3, 0)
					hedefRoot.CFrame = CFrame.lookAt(p, Vector3.new(root.Position.X, p.Y, root.Position.Z))
					hedefRoot.AssemblyLinearVelocity = Vector3.zero
					RunService.Heartbeat:Wait()
				end
			end
		end)
	elseif oyuncakAdi == "Kovboy" and tus == "R" then
		aktifR[player] = "Kovboy"
		sonAim[player] = yon
		efektRemote:FireAllClients("kolIleri", { karakter = char })
		local silahlar = { silahYap(char, "RightHand", "tabanca"), silahYap(char, "LeftHand", "tabanca") }
		task.spawn(function()
			local bitis = os.clock() + 3
			local eski = hum.WalkSpeed
			hum.WalkSpeed = eski * 0.5
			while os.clock() < bitis and char.Parent and hum.Health > 0 do
				local aim = sonAim[player] or root.CFrame.LookVector
				local hedefN = nisanNoktasi(root, aim, ayar.Menzil, rayParams)
				for i, el in ipairs({ "RightHand", "LeftHand" }) do
					local parca = char:FindFirstChild(el)
					local namlu = silahlar[i] and silahlar[i]:FindFirstChild("Namlu", true)
					local bas = namlu and namlu.WorldPosition or (parca and parca.Position) or root.Position
					-- iki namlu da nisan noktasina dogru
					local fark = hedefN - bas
					local yonu = fark.Magnitude > 1 and fark.Unit or aim
					local sonuc = Workspace:Spherecast(bas, 0.8, yonu * ayar.Menzil, rayParams)
					local son = sonuc and sonuc.Position or bas + yonu * ayar.Menzil
					efektRemote:FireAllClients("tabanca", { baslangic = bas, bitis = son })
					if sonuc then
						local hedef = karakterBul(sonuc.Instance)
						if hedef and hedef ~= char then hasarVer(hedef, ayar.Hasar, player) end
					end
				end
				task.wait(0.12)
			end
			for _, s in ipairs(silahlar) do if s then s:Destroy() end end
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
		-- isin tabancasi + sarj, sonra ileri delici dev isin
		local silah = silahYap(char, "RightHand", "isin")
		aktifR[player] = "Isin"
		sonAim[player] = yon
		efektRemote:FireAllClients("isinPoz", { karakter = char })
		efektRemote:FireAllClients("isinSarj", { karakter = char, konum = silah and silah:FindFirstChild("Namlu", true) and silah:FindFirstChild("Namlu", true).WorldPosition or root.Position })
		local eski = hum.WalkSpeed
		hum.WalkSpeed = 4
		task.delay(ayar.Sarj or 0.5, function()
			if not char.Parent or hum.Health <= 0 then
				if silah then silah:Destroy() end
				return
			end
			local namlu = silah and silah:FindFirstChild("Namlu", true)
			local bas = namlu and namlu.WorldPosition or root.Position + Vector3.new(0, 1, 0)
			local aim = sonAim[player] or yon
			-- namlu sagda: isini nisan noktasina dogru cevir
			local hedefN = nisanNoktasi(root, aim, ayar.Menzil, rayParams)
			if (hedefN - bas).Magnitude > 3 then aim = (hedefN - bas).Unit end
			-- duvara kadar git, karakterlerin icinden gec
			local haric = { char }
			local son = bas + aim * ayar.Menzil
			for _ = 1, 10 do
				local p = RaycastParams.new()
				p.FilterType = Enum.RaycastFilterType.Exclude
				p.FilterDescendantsInstances = haric
				local r = Workspace:Raycast(bas, aim * ayar.Menzil, p)
				if not r then break end
				local h = karakterBul(r.Instance)
				if h then
					table.insert(haric, h)
				elseif r.Instance.Transparency >= 0.95 or not r.Instance.CanCollide then
					table.insert(haric, r.Instance)
				else
					son = r.Position
					break
				end
			end
			efektRemote:FireAllClients("isin", { baslangic = bas, bitis = son, karakter = char })
			local uzunluk = (son - bas).Magnitude
			local vurulan = {}
			for _, aday in ipairs(Workspace:GetDescendants()) do
				if aday:IsA("Humanoid") and aday.Health > 0 and aday.Parent ~= char and not vurulan[aday.Parent] then
					local aRoot = aday.Parent:FindFirstChild("HumanoidRootPart")
					if aRoot then
						local t = math.clamp((aRoot.Position - bas):Dot(aim), 0, uzunluk)
						if (bas + aim * t - aRoot.Position).Magnitude <= (ayar.Genislik or 3.5) then
							vurulan[aday.Parent] = true
							if hasarVer(aday.Parent, ayar.Hasar, player) then
								itmeUygula(aRoot, aim * 45 + Vector3.new(0, 20, 0), 0.2)
								efektRemote:FireAllClients("vurus", { konum = aRoot.Position, saldiran = player })
							end
						end
					end
				end
			end
			task.wait(0.4)
			if aktifR[player] == "Isin" then aktifR[player] = nil end
			if silah then silah:Destroy() end
			if hum.Parent and hum.Health > 0 then hum.WalkSpeed = eski end
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
	char:SetAttribute("Ulti", Config.UltiTest and 100 or 0)
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
