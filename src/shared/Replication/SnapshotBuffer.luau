local Transform = require(script.Parent.Transform)

export type Buffer = {
    snapshots: {Snapshot},
    bufferSize: number,
}

export type Snapshot = {
    timestamp: number, -- store timestamp as a raw tick on client
    transform: Transform.Transform
}

local SnapshotBuffer = {}

function SnapshotBuffer.new(bufferSize: number): Buffer
    return {
        snapshots = {},
        bufferSize = bufferSize,
    }
end

function SnapshotBuffer.getSnapshots(self: Buffer): {Snapshot}
    return self.snapshots
end

function SnapshotBuffer.getLatestSnapshot(self: Buffer): Snapshot?
    if #self.snapshots > 1 then
        return self.snapshots[#self.snapshots]
    end

    return nil
end

function SnapshotBuffer.addSnapshot(self: Buffer, snapshot: Snapshot)
    if #self.snapshots + 1 > self.bufferSize then
        table.remove(self.snapshots, 1)
    end

    -- Overwrite snapshots with duplicate timestamps
    for i, existingSnapshot in self.snapshots do
        if existingSnapshot.timestamp == snapshot.timestamp then
            self.snapshots[i] = snapshot
            return
        end
    end

    table.insert(self.snapshots, snapshot)

    local latestSnapshot = SnapshotBuffer.getLatestSnapshot(self)

    -- Sort snapshots if one arrives unordered
    if latestSnapshot and latestSnapshot.timestamp > snapshot.timestamp then
        table.sort(self.snapshots, function(a, b)
            return a.timestamp < b.timestamp
        end)
    end
end

function SnapshotBuffer.findClosestSnapshot(self: Buffer, renderTime: number): (Snapshot?, Snapshot?)
    local snapshotA: Snapshot?, snapshotB: Snapshot? = nil, nil

    for index, snapshot in self.snapshots do
        if snapshot.timestamp <= renderTime then
            snapshotA = snapshot
        end

        if snapshot.timestamp > renderTime then
            snapshotB = snapshot
            break
        end
    end

    if snapshotA == nil then
        snapshotA = self.snapshots[1]
        snapshotB = self.snapshots[2]
    end

    return snapshotA, snapshotB
end

return SnapshotBuffer
