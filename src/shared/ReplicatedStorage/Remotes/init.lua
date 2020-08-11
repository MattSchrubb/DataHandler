local Remotes = {}

wait()
for _,remote in pairs(script:GetChildren()) do
	Remotes[remote.Name] = remote
end

return Remotes