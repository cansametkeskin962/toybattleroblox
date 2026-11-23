-- Ortak ayarlar. Server ve client ikisi de okur. Denge buradan ayarlanir.
local Config = {}

Config.DogmaSuresi = 3 -- olunce kac sn sonra dogar
Config.OlduruPara = 10 -- oldurme basina para
Config.OlayAraligi = 90 -- surpriz olay araligi (sn)
Config.BlokHasarCarpani = 0.3 -- blok yaparken alinan hasar orani
Config.KomboSifirlama = 1.2 -- M1 vuruslari arasi bu kadar gecerse kombo basa doner
Config.UltiKazanc = 1.0 -- verilen hasar basina ulti puani
Config.UltiTest = true -- TEST: ulti hep dolu (R 6 sn'de bir). Yayindan once false yap.

-- Oyuncaklar. Fiyat 0 = bedava.
Config.Oyuncaklar = {
	Kovboy = {
		Sira = 1,
		Fiyat = 0,
		ModelId = 105910732008948, -- Studio'da import + Save to Roblox sonrasi asset id
		ModelBoy = 5.5,
		ModelDonus = 0, -- model ters bakiyorsa 180
		Can = 100,
		Hiz = 18,
		Renk = Color3.fromRGB(196, 120, 60),
		Aciklama = "Kementle ceker, cift tabancayla ates eder.",
		M1 = { Hasar = 7, Menzil = 6, Bekleme = 0.35, SonVurusItme = 45 },
		Q = { Ad = "Kement", Aciklama = "Ilmegi savurur, nisana yakin dusmani yakalayip ceker.", Hasar = 8, Menzil = 45, Bekleme = 6, Yardim = 12 },
		R = { Ad = "Cifte Tabanca", Aciklama = "3 saniye boyunca iki elden ates eder.", Hasar = 5, Menzil = 90, Sure = 3, Bekleme = 0 },
	},
	Astronot = {
		Sira = 2,
		Fiyat = 0,
		ModelId = 130509278229811, -- Studio'da import + Save to Roblox sonrasi asset id
		ModelBoy = 5.5,
		ModelDonus = 0, -- model ters bakiyorsa 180
		Can = 110,
		Hiz = 16,
		Renk = Color3.fromRGB(235, 235, 245),
		Aciklama = "Jetpackle ucar, isin tabancasiyla delici isin atar.",
		M1 = { Hasar = 8, Menzil = 6, Bekleme = 0.4, SonVurusItme = 50 },
		Q = { Ad = "Jetpack", Aciklama = "3 saniye kontrollu ucar; tekrar Q ile bitirir.", Hasar = 0, Menzil = 0, Sure = 3, Bekleme = 7 },
		R = { Ad = "Plazma Isini", Aciklama = "Kisa sarjdan sonra ileri, herkesi delen dev isin atar.", Hasar = 55, Menzil = 90, Genislik = 3.5, Sarj = 0.5, Bekleme = 0 },
	},
	Domuz = {
		Sira = 3,
		Fiyat = 0, -- test icin 0, sonra 150
		ModelId = 74513126962519, -- Studio'da import + Save to Roblox sonrasi asset id
		ModelBoy = 5.5,
		ModelDonus = 0, -- model ters bakiyorsa 180
		Can = 140,
		Hiz = 15,
		Renk = Color3.fromRGB(255, 160, 180),
		Aciklama = "Kafa atarak dalar, gobek depremiyle herkesi savurur.",
		M1 = { Hasar = 9, Menzil = 6, Bekleme = 0.45, SonVurusItme = 60 },
		Q = { Ad = "Dalis", Aciklama = "Ileriye hizla dalip ilk rakibi savurur.", Hasar = 15, Menzil = 30, Bekleme = 6 },
		R = { Ad = "Gobek Depremi", Aciklama = "Buyuk ziplayis sonrasi 20 studluk sok dalgasi yaratir.", Hasar = 30, Menzil = 20, Sure = 2.5, Bekleme = 0 },
	},
}

-- RemoteEvent adlari (server ReplicatedStorage/Remotes altinda olusturur)
Config.Remote = {
	SecimYap = "SecimYap", -- client->server (oyuncakAdi)
	SatinAl = "SatinAl", -- client->server (oyuncakAdi)
	Saldir = "Saldir", -- client->server (tus "M1"|"Q"|"R"|"RNisan", hedefYonu Vector3)
	Blok = "Blok", -- client->server (aktif bool)
	Durum = "Durum", -- server->client ({Para, Acik={ad=true}, Secili})
	Bildirim = "Bildirim", -- server->client(lar) (metin, renk Color3?)
	Efekt = "Efekt", -- server->herkes (tur string, veri table)
	Bekleme = "Bekleme", -- server->client (tus, saniye) yetenek kullanildi
}

return Config
