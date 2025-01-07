local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Jecs = require(ReplicatedStorage.packages.jecs)
local World = require(ReplicatedStorage.shared.ecs.world)

type Entity<T = nil> = Jecs.Entity<T>

type Components = {
    Name: Entity<string>,
    Position: Entity<Vector3>,
    Instance: Entity<Instance>,
    Model: Entity<Model>,
    Player: Entity<Player>,
    LocalPlayer: Entity<Player>,
    Character: Entity<Model>,
}

local components: Components = {
    Name = World:component(),
    Position = World:component(),
    Instance = World:component(),
    Model = World:component(),
    Player = World:component(),
    LocalPlayer = World:component(),
    Character = World:component(),
}

for name, component in components :: {[string]: Entity} do 
	World:set(component, components.Name, name)
end

return table.freeze(components)

