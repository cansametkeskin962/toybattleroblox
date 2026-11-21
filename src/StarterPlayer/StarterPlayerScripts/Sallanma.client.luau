-- Oyuncak modelli karakterleri yururken paytak paytak sallar (sadece gorsel, her client kendi cizer).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		local kok = ch and ch:FindFirstChild("HumanoidRootPart")
		local kaynak = kok and kok:FindFirstChild("OyuncakKaynak")
		if kaynak then
			local v = kok.AssemblyLinearVelocity
			local hiz = math.clamp(Vector3.new(v.X, 0, v.Z).Magnitude / 16, 0, 1)
			local faz = t * 11 + p.UserId % 7
			local yalpa = math.sin(faz) * 0.18 * hiz
			local zipla = math.abs(math.sin(faz)) * 0.35 * hiz
			local nefes = math.sin(t * 2 + p.UserId % 5) * 0.04
			kaynak.C0 = CFrame.new(0, zipla + nefes, 0) * CFrame.Angles(-0.08 * hiz, 0, yalpa)
		end
	end
end)
