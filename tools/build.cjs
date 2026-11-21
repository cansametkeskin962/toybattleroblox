// src/ klasorunden Roblox yerlesim dosyasi (.rbxlx) uretir. Rojo gerekmez.
// Kullanim: node tools/build.cjs   -> build/ToyBattlegrounds.rbxlx
// Kurallar (Rojo ile ayni): *.server.luau = Script, *.client.luau = LocalScript,
// diger *.luau = ModuleScript, klasor = Folder (servis adlari servis olur).
const fs = require('fs')
const path = require('path')

const KOK = path.join(__dirname, '..')
const SRC = path.join(KOK, 'src')
const CIKTI = path.join(KOK, 'build', 'ToyBattlegrounds.rbxlx')

const SINIF = {
  ServerScriptService: 'ServerScriptService',
  ReplicatedStorage: 'ReplicatedStorage',
  ServerStorage: 'ServerStorage',
  StarterPlayer: 'StarterPlayer',
  StarterPlayerScripts: 'StarterPlayerScripts',
  StarterCharacterScripts: 'StarterCharacterScripts',
  StarterGui: 'StarterGui',
  Workspace: 'Workspace',
  Lighting: 'Lighting',
  SoundService: 'SoundService',
}

let ref = 0
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
const cdata = s => '<![CDATA[' + s.replace(/]]>/g, ']]]]><![CDATA[>') + ']]>'

function item(sinif, ad, ic, kaynak) {
  let x = `<Item class="${sinif}" referent="RBX${ref++}"><Properties><string name="Name">${esc(ad)}</string>`
  if (kaynak !== undefined) x += `<ProtectedString name="Source">${cdata(kaynak)}</ProtectedString>`
  return x + '</Properties>' + (ic || '') + '</Item>\n'
}

function dosya(tam, ad) {
  const kaynak = fs.readFileSync(tam, 'utf8')
  if (ad.endsWith('.server.luau')) return item('Script', ad.slice(0, -12), '', kaynak)
  if (ad.endsWith('.client.luau')) return item('LocalScript', ad.slice(0, -12), '', kaynak)
  if (ad.endsWith('.luau')) return item('ModuleScript', ad.slice(0, -5), '', kaynak)
  return ''
}

function klasor(tam, ad) {
  let ic = ''
  for (const c of fs.readdirSync(tam).sort()) {
    const t = path.join(tam, c)
    ic += fs.statSync(t).isDirectory() ? klasor(t, c) : dosya(t, c)
  }
  return item(SINIF[ad] || 'Folder', ad, ic)
}

let govde = ''
for (const c of fs.readdirSync(SRC).sort()) {
  const t = path.join(SRC, c)
  if (fs.statSync(t).isDirectory()) govde += klasor(t, c)
}
fs.mkdirSync(path.dirname(CIKTI), { recursive: true })
fs.writeFileSync(CIKTI, '<roblox version="4">\n' + govde + '</roblox>\n')
console.log('Yazildi:', CIKTI, ref, 'nesne')
