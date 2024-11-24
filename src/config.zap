-- run after changes:
-- zap src/config.zap

opt server_output = "./server/Zap/init.luau"
opt client_output = "./client/Zap/init.luau"

event RequestReplication = {
	from: Client,
	type: Unreliable,
	call: SingleAsync,
	data: struct {  
		cframe: CFrame
	},
}

event BroadcastReplication = {
	from: Server,
	type: Unreliable,
	call: SingleAsync,
	data: struct {  
		root: Instance(BasePart),
		cframe: CFrame, 
	}[1 .. 31]
}