export type Snapshots = {
    log: {Frame},
    bufferSize: number,
}

export type Frame = {
    frameNumber: number,
    timestamp: number,
    cframe: CFrame
}

local Snapshots = {}

function Snapshots.new(bufferSize: number): Snapshots
    return {
        log = {},
        bufferSize = bufferSize,
    }
end

function Snapshots.getLog(self: Snapshots): {Frame}
    return self.log
end

function Snapshots.addFrame(self: Snapshots, frame: number, data: CFrame)
    table.insert(self.log, {
        frameNumber = frame,
        timestamp = os.clock(),
        cframe = data
    })

    if #self.log > self.bufferSize then
        table.remove(self.log, 1)
    end
end

function Snapshots.getLatestFrame(self: Snapshots): Frame?
    return self.log[#self.log]
end

return Snapshots
