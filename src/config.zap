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
	},
}

event BroadcastReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {
		frame: u8,
		map: struct {
			root: Instance(BasePart),
			x: f32,
			y: f32,
			z: f32,
		}[1 .. 31]
	}
}