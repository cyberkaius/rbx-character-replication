local Interpolation = require(script.Parent.Interpolation)

local Tick = {}

local frequency = Interpolation.packetFrequency

Tick.raw = 1
Tick.wrapCount = 1

function Tick.increment()
    Tick.raw += 1

    if Tick.raw >= 255 then
        Tick.raw = 1
        Tick.wrapCount += 1
    end
end

function Tick.toTimestamp(u8: number): number
    return u8 * frequency + (Tick.wrapCount * frequency * 255)
end

return Tick