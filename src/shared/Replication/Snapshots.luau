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
    if #self.log + 1 > self.bufferSize then
        table.remove(self.log, 1)
    end

    table.insert(self.log, {
        frameNumber = frame,
        timestamp = os.clock(),
        cframe = data
    })
end

function Snapshots.getLatestFrame(self: Snapshots): Frame?
    if #self.log > 1 then
        return self.log[#self.log]
    end

    return nil
end

function Snapshots.getPreviousFrame(self: Snapshots): Frame?
    if #self.log > 1 then
        return self.log[#self.log - 1]
    end

    return nil
end

return Snapshots
