// Ajan cevabindaki "=== DOSYA: yol ===" + ```lua blok``` parcalarini dosyaya yazar.
// Kullanim: node tools/cikar.cjs <cevap.txt>
const fs = require('fs')
const path = require('path')
const KOK = path.join(__dirname, '..')
const metin = fs.readFileSync(process.argv[2], 'utf8')
const re = /=== DOSYA:\s*(\S+)\s*===\s*```(?:lua|luau)?\r?\n([\s\S]*?)\r?\n```/g
let m, n = 0
while ((m = re.exec(metin))) {
  const yol = m[1].replace(/\\/g, '/')
  if (!yol.startsWith('src/') || yol.includes('..')) { console.log('ATLANDI', yol); continue }
  const tam = path.join(KOK, yol)
  fs.mkdirSync(path.dirname(tam), { recursive: true })
  fs.writeFileSync(tam, m[2] + '\n')
  console.log('yazildi', yol, m[2].length)
  n++
}
console.log(n, 'dosya')
