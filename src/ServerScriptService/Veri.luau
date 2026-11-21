-- Oyuncu verisi (Para ve Acik oyuncaklar) DataStore + bellek ici onbellek yonetimi.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Veri = {}
local oyuncuVerileri = {}
local veriStore = nil

local okStore, sonucStore = pcall(function()
	return DataStoreService:GetDataStore("ToyBattlegrounds_Veri_v1")
end)
if okStore then
	veriStore = sonucStore
end

local function varsayilanVeriOlustur()
	local acik = {}
	for ad, bilgi in pairs(Config.Oyuncaklar) do
		if bilgi.Fiyat == 0 then
			acik[ad] = true
		end
	end
	return {
		Para = 0,
		Acik = acik,
		Secili = "Kovboy",
		YuklemeHatasi = false,
	}
end

local function ucretsizleriAc(veri)
	for ad, bilgi in pairs(Config.Oyuncaklar) do
		if bilgi.Fiyat == 0 then
			veri.Acik[ad] = true
		end
	end
	if not Config.Oyuncaklar[veri.Secili] or not veri.Acik[veri.Secili] then
		veri.Secili = "Kovboy"
	end
end

function Veri.Yukle(player)
	if oyuncuVerileri[player] then
		return oyuncuVerileri[player]
	end

	local veri = varsayilanVeriOlustur()
	oyuncuVerileri[player] = veri

	if veriStore and player.UserId > 0 then
		local anahtar = "oyuncu_" .. tostring(player.UserId)
		local ok, kayit = pcall(function()
			return veriStore:GetAsync(anahtar)
		end)

		if ok then
			if type(kayit) == "table" then
				if type(kayit.Para) == "number" then
					veri.Para = math.max(0, math.floor(kayit.Para))
				end
				if type(kayit.Acik) == "table" then
					for ad, acikMi in pairs(kayit.Acik) do
						if type(ad) == "string" and acikMi == true and Config.Oyuncaklar[ad] then
							veri.Acik[ad] = true
						end
					end
				end
				if type(kayit.Secili) == "string" and Config.Oyuncaklar[kayit.Secili] then
					veri.Secili = kayit.Secili
				end
			end
		else
			-- Studio API erisimi kapaliysa veya gecici hata varsa bellekte devam et
			veri.YuklemeHatasi = true
		end
	end

	ucretsizleriAc(veri)
	return veri
end

function Veri.Get(player)
	local veri = oyuncuVerileri[player]
	if not veri then
		veri = varsayilanVeriOlustur()
		oyuncuVerileri[player] = veri
	end
	return veri
end

function Veri.Set(player, alan, deger)
	local veri = Veri.Get(player)
	if alan == "Para" and type(deger) == "number" then
		veri.Para = math.max(0, math.floor(deger))
	elseif alan == "Acik" and type(deger) == "table" then
		veri.Acik = deger
		ucretsizleriAc(veri)
	elseif alan == "Secili" and type(deger) == "string" and Config.Oyuncaklar[deger] then
		veri.Secili = deger
	end
end

function Veri.GetPara(player)
	return Veri.Get(player).Para
end

function Veri.SetPara(player, miktar)
	local veri = Veri.Get(player)
	veri.Para = math.max(0, math.floor(miktar))
end

function Veri.EklePara(player, miktar)
	local veri = Veri.Get(player)
	veri.Para = math.max(0, math.floor(veri.Para + miktar))
end

function Veri.AcikMi(player, oyuncakAdi)
	local veri = Veri.Get(player)
	return veri.Acik[oyuncakAdi] == true
end

function Veri.Ac(player, oyuncakAdi)
	if not Config.Oyuncaklar[oyuncakAdi] then
		return
	end
	local veri = Veri.Get(player)
	veri.Acik[oyuncakAdi] = true
end

function Veri.GetSecili(player)
	local veri = Veri.Get(player)
	if not Config.Oyuncaklar[veri.Secili] or not veri.Acik[veri.Secili] then
		veri.Secili = "Kovboy"
	end
	return veri.Secili
end

function Veri.SetSecili(player, oyuncakAdi)
	if not Config.Oyuncaklar[oyuncakAdi] then
		return
	end
	local veri = Veri.Get(player)
	veri.Secili = oyuncakAdi
end

function Veri.Kaydet(player)
	local veri = oyuncuVerileri[player]
	if not veri or veri.YuklemeHatasi then
		return
	end
	if not veriStore or player.UserId <= 0 then
		return
	end

	local anahtar = "oyuncu_" .. tostring(player.UserId)
	local kayitPaketi = {
		Para = veri.Para,
		Acik = veri.Acik,
		Secili = veri.Secili,
	}

	pcall(function()
		veriStore:SetAsync(anahtar, kayitPaketi)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	Veri.Kaydet(player)
	oyuncuVerileri[player] = nil
end)

game:BindToClose(function()
	local oyuncular = Players:GetPlayers()
	local bekleyen = #oyuncular
	if bekleyen == 0 then
		return
	end

	for _, player in ipairs(oyuncular) do
		task.spawn(function()
			Veri.Kaydet(player)
			bekleyen -= 1
		end)
	end

	local baslangic = os.clock()
	local maxBekleme = if RunService:IsStudio() then 2 else 8
	while bekleyen > 0 and (os.clock() - baslangic) < maxBekleme do
		task.wait(0.1)
	end
end)

return Veri
