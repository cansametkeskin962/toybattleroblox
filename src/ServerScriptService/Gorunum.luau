-- Oyuncak modelini (Studio'da import edilip "Save to Roblox" yapilan) karaktere giydirir.
-- Config.Oyuncaklar[ad].ModelId > 0 ise Roblox govdesi gizlenir, oyuncak modeli kaynaklanir.
local InsertService = game:GetService("InsertService")

local Gorunum = {}
local onbellek = {} -- ModelId -> Model sablonu (ya da false: yuklenemedi)

local function sablonAl(id)
	if onbellek[id] ~= nil then
		return onbellek[id] or nil
	end
	local tamam, sonuc = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if not tamam or not sonuc then
		warn("[Gorunum] Model yuklenemedi, id: " .. tostring(id) .. " " .. tostring(sonuc))
		onbellek[id] = false
		return nil
	end
	-- LoadAsset bir Model dondurur, icinde asil nesne olur
	local model = Instance.new("Model")
	for _, c in ipairs(sonuc:GetChildren()) do
		c.Parent = model
	end
	sonuc:Destroy()
	onbellek[id] = model
	return model
end

-- true donerse oyuncak modeli giydirildi
function Gorunum.Giydir(character, oyuncak)
	local id = oyuncak.ModelId or 0
	if id <= 0 then
		return false
	end
	local kok = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local sablon = sablonAl(id)
	if not kok or not humanoid or not sablon then
		return false
	end

	local model = sablon:Clone()
	local parcalar = {}
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			table.insert(parcalar, p)
		end
	end
	if #parcalar == 0 then
		model:Destroy()
		return false
	end

	-- Boyut: karakter boyuna olcekle
	local _, boyut = model:GetBoundingBox()
	local hedefBoy = oyuncak.ModelBoy or 5.5
	if boyut.Y > 0 then
		model:ScaleTo(hedefBoy / boyut.Y)
	end

	-- Ayaklar yere gelsin: model altini kok parcanin altina hizala
	local kutuCf, kutuBoyut = model:GetBoundingBox()
	local ayakY = kok.Position.Y - kok.Size.Y / 2 - humanoid.HipHeight
	local donus = CFrame.Angles(0, math.rad(oyuncak.ModelDonus or 0), 0)
	local merkez = kok.CFrame * donus
	local hedef = CFrame.new(merkez.Position.X, ayakY + kutuBoyut.Y / 2, merkez.Position.Z) * merkez.Rotation
	model:PivotTo(hedef * kutuCf:ToObjectSpace(model:GetPivot()))

	-- Sallanma icin tek kaynak: kok -> OyuncakKok (client C0 ile oynatir)
	local oyuncakKok = Instance.new("Part")
	oyuncakKok.Name = "OyuncakKok"
	oyuncakKok.Size = Vector3.new(0.2, 0.2, 0.2)
	oyuncakKok.Transparency = 1
	oyuncakKok.CanCollide = false
	oyuncakKok.CanQuery = false
	oyuncakKok.CanTouch = false
	oyuncakKok.Massless = true
	oyuncakKok.CFrame = kok.CFrame
	oyuncakKok.Parent = model
	for _, p in ipairs(parcalar) do
		local w = Instance.new("WeldConstraint")
		w.Part0 = oyuncakKok
		w.Part1 = p
		w.Parent = p
	end
	local kaynak = Instance.new("Weld")
	kaynak.Name = "OyuncakKaynak"
	kaynak.Part0 = kok
	kaynak.Part1 = oyuncakKok
	kaynak.C0 = CFrame.new()
	kaynak.Parent = kok

	model.Name = "OyuncakModel"
	model.Parent = character

	-- Roblox govdesini ve kodla eklenen basit aksesuarlari gizle
	for _, c in ipairs(character:GetDescendants()) do
		if c:IsA("BasePart") and not c:IsDescendantOf(model) then
			c.Transparency = 1
		elseif c:IsA("Decal") and not c:IsDescendantOf(model) then
			c.Transparency = 1
		end
	end
	for _, c in ipairs(character:GetChildren()) do
		if c:GetAttribute("OyuncakAksesuar") then
			c:Destroy()
		end
	end
	character:SetAttribute("OyuncakModelli", true)
	return true
end

return Gorunum
