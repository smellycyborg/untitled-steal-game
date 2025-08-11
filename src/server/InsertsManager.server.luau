for _, instance in game:GetService("ReplicatedStorage"):WaitForChild("Inserts"):GetChildren() do
    instance.Parent = game:GetService("ReplicatedStorage")
end
