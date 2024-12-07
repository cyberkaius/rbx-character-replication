-- run after changes:
-- zap src/config.zap

opt server_output = "./server/Zap/init.luau"
opt client_output = "./client/Zap/init.luau"

event RequestReplication = {
	from: Client,
	type: Unreliable,
	call: SingleAsync,
	data: struct {  
		x: f32,
		y: f32,
		z: f32,
		yRotation: f32,
	},
}

event BroadcastReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		tick: u8,
		map: struct {
			entity: u8,
			x: f32,
			y: f32,
			z: f32,
			yRotation: f32,
		}[1 .. 50]
	}
}

funct RequestServerTick = {
    call: Async,
    rets: u8
}

event CreateCharacter = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		entityId: u8,
		player: Instance(Player),
		cframe: CFrame,
	}
}

event RemoveCharacter = {
	from: Server,
	type: Reliable,
	call: SingleAsync,
	data: struct {
		entityId: u8,
	}
}