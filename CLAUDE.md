# Toy Battlegrounds (Roblox) — kurallar

Oyuncak temali Roblox "Battlegrounds" arena dovusu. Unreal projesinden (ProjectToyFight) tasindi. Plan ve kararlar: `D:\unreal projeler\ProjectToyFight - Kopya 5.8\KONUSMA_NOTLARI.md`.

## Kullaniciyla
- Turkce, kisa. Rapor: "Yapildi: X. Dene: Y."
- Token sirasi: Antigravity Claude > Antigravity Gemini > OpenRouter (`node "D:\unreal projeler\ProjectToyFight - Kopya 5.8\.claude\openrouter\or-calistir.cjs"`) > Claude.

## Calisma duzeni
- Kod `src/` altinda Luau dosyalari (Rojo duzeni). Studio'da elle kod yazilmaz, dosyada tutulur.
- ASIL YOL: Rojo 7.4.4 (`%LOCALAPPDATA%\rojo\rojo.exe`, Studio eklentisi kurulu). Kullanici yayinlanmis oyunu Studio'da acar, `baslat.cmd` calistirir, Rojo eklentisinden Connect. Kod canli gecer, Studio'daki modeller korunur ($ignoreUnknownInstances).
- Modeller: `modeller/Roblox/*.fbx` (`tools/roblox_fbx.py` ile Blender'dan: ayakta, parca adi R_RRGGBB = renk). Studio'da import -> ReplicatedStorage/Oyuncaklar/<Ad> (Kovboy, Astronot, Domuz). Gorunum.luau once orayi, yoksa Config ModelId'yi kullanir.
- Copilot CLI kurulu (`copilot`, npm global); kullanici girisi gerekir.
- Eski yol: `node tools/build.cjs` -> `build/ToyBattlegrounds.rbxlx`. Kullanici Studio'da acar (Turkiye'de Roblox icin VPN gerekir).
- Dosya turu: `*.server.luau` Script, `*.client.luau` LocalScript, `*.luau` ModuleScript.
- Harita kodla kurulur (`src/ServerScriptService/Harita.server.luau`), yerlesim dosyasinda Workspace yok.
- Git: branch `main`, commit mesaji Turkce ASCII. Anil ile: herkes kendi branch'i, `EKIP.md` once okunur.

## Oyun ozeti
- Sunucu hep acik, istedigin an gir. Karakter sec (Kovboy, Astronot, Domuz), M1 kombo + Q/E yetenek + F blok. Olunce 3 sn sonra dog.
- Oldurme = para. Para ile oyuncak acilir. Skor tablosu (leaderstats). 90 sn'de bir surpriz olay (kedi pencesi).
- Basit, renkli, eglenceli. Gucu parayla satma.
