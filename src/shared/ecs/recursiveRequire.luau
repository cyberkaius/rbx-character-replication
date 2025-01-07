local function recursiveRequire(instance: Instance)
	for _, v in instance:GetChildren() do
		recursiveRequire(v)
		
		if v:IsA("ModuleScript") then
			_ = (require :: any)(v)
			continue
		end
	end
end