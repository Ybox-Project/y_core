local qbShared = {}
--TODO: wtf is a config doing in shared?
qbShared.ForceJobDefaultDutyAtLogin = true -- true: Force duty state to jobdefaultDuty | false: set duty state from database last saved
qbShared.Vehicles = require 'shared.vehicles'

---@type table<number, Vehicle>
qbShared.VehicleHashes = {}

for _, v in pairs(qbShared.Vehicles) do
    qbShared.VehicleHashes[v.hash] = v
end

return qbShared
