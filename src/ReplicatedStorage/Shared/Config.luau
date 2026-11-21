-- Ortak ayarlar. Server ve client ikisi de okur. Denge buradan ayarlanir.
local Config = {}

Config.DogmaSuresi = 3 -- olunce kac sn sonra dogar
Config.OlduruPara = 10 -- oldurme basina para
Config.OlayAraligi = 90 -- surpriz olay araligi (sn)
Config.BlokHasarCarpani = 0.3 -- blok yaparken alinan hasar orani
Config.KomboSifirlama = 1.2 -- M1 vuruslari arasi bu kadar gecerse kombo basa doner

-- Oyuncaklar. Fiyat 0 = bedava.
Config.Oyuncaklar = {
	Kovboy = {
		Sira = 1,
		Fiyat = 0,
		Can = 100,
		Hiz = 18,
		Renk = Color3.fromRGB(196, 120, 60),
		Aciklama = "Kement ile ceker, tabancayla uzaktan vurur.",
		M1 = { Hasar = 7, Menzil = 6, Bekleme = 0.35, SonVurusItme = 45 },
		Q = { Ad = "Kement", Hasar = 8, Menzil = 40, Bekleme = 6 },
		E = { Ad = "Tabanca", Hasar = 14, Menzil = 80, Bekleme = 4 },
	},
	Astronot = {
		Sira = 2,
		Fiyat = 0,
		Can = 110,
		Hiz = 16,
		Renk = Color3.fromRGB(235, 235, 245),
		Aciklama = "Jetpack ile ziplar, yere carpip etraftakileri ucurur.",
		M1 = { Hasar = 8, Menzil = 6, Bekleme = 0.4, SonVurusItme = 50 },
		Q = { Ad = "Jetpack", Hasar = 0, Menzil = 0, Bekleme = 5 },
		E = { Ad = "Yere Carpma", Hasar = 20, Menzil = 14, Bekleme = 8 },
	},
	Domuz = {
		Sira = 3,
		Fiyat = 150,
		Can = 140,
		Hiz = 15,
		Renk = Color3.fromRGB(255, 160, 180),
		Aciklama = "Kumbara domuz. Kafa atarak dalar, gobekle zipliyor.",
		M1 = { Hasar = 9, Menzil = 6, Bekleme = 0.45, SonVurusItme = 60 },
		Q = { Ad = "Dalis", Hasar = 15, Menzil = 30, Bekleme = 6 },
		E = { Ad = "Gobek Zipla", Hasar = 18, Menzil = 12, Bekleme = 7 },
	},
}

-- RemoteEvent adlari (server ReplicatedStorage/Remotes altinda olusturur)
Config.Remote = {
	SecimYap = "SecimYap", -- client->server (oyuncakAdi)
	SatinAl = "SatinAl", -- client->server (oyuncakAdi)
	Saldir = "Saldir", -- client->server (tus "M1"|"Q"|"E", hedefYonu Vector3)
	Blok = "Blok", -- client->server (aktif bool)
	Durum = "Durum", -- server->client ({Para, Acik={ad=true}, Secili})
	Bildirim = "Bildirim", -- server->client(lar) (metin, renk Color3?)
	Efekt = "Efekt", -- server->herkes (tur string, veri table)
	Bekleme = "Bekleme", -- server->client (tus, saniye) yetenek kullanildi
}

return Config
