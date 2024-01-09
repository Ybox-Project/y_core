local isServer = IsDuplicityVersion()

local qbx = {}
qbx.string = {}
qbx.math = {}
qbx.table = {}

---Returns the given string with its trailing whitespaces removed.
---@param str string
---@return string
function qbx.string.trim(str)
    local trimmed = str:gsub('^%s*(.-)%s*$', '%1')
    return trimmed
end

---Returns the given string with its first character capitalized.
---@param str string
---@return string
function qbx.string.capitalize(str)
    local capitalized = str:gsub('^%l', string.upper)
    return capitalized
end

---Rounds and returns the given number.
---@param num number
---@param decimalPlaces? integer
---@return number rounded integer if `decimalPlaces` isn't passed, number otherwise
function qbx.math.round(num, decimalPlaces)
    if not decimalPlaces then return math.floor(num + 0.5) end
    local power = 10 ^ decimalPlaces
    return math.floor((num * power) + 0.5) / power
end

---Maps and returns the values of the given table by the given subfield.
---@param tble table
---@param subfield any
---@return table<any, table[]>
function qbx.table.mapBySubfield(tble, subfield)
    local map = {}

    for _, subTable in pairs(tble) do
        local subfieldValue = subTable[subfield]

        if subfieldValue then
            if not map[subfieldValue] then
                map[subfieldValue] = {}
            end

            map[subfieldValue][#map[subfieldValue] + 1] = subTable
        end
    end

    return map
end

---Returns the number plate of the given vehicle.
---@param vehicle integer
---@return string
function qbx.getVehiclePlate(vehicle)
    return qbx.string.trim(GetVehicleNumberPlateText(vehicle))
end

---Generates and returns a random number plate with the given pattern.
---Note that the generated plate may or may not be already used by an existing vehicle.
---For more info about the pattern see [`lib.string.random`](https://overextended.dev/ox_lib/Modules/String/Shared#stringrandom) from ox_lib.
---@param pattern? string
---@return string
function qbx.generateRandomPlate(pattern)
    pattern = pattern or '........'
    return lib.string.random(pattern):upper()
end

---Returns the cardinal direction that the given entity is staring towards, or nil if the entity doesn't exist.
---```
---                 North
---     45°           0°           315°
---       \    .- - - - - - -.    /
---          X                 X
---        .'   \           /   '.
---       |        \     /        |
--- West  |           X           |  East
---       |        /     \        |
---        '.   /           \   .'
---          X                 X
---       /    '- - - - - - -'    \
---     135°                      225°
---                 South
---```
---(art inspired by [`SET_PED_TURNING_THRESHOLDS`](https://github.com/citizenfx/fivem/blob/0b61c93a3308360ea70d443398eab17f47453e11/code/components/extra-natives-five/src/PedExtraNatives.cpp#L390-L400))
---@param entity integer
---@return 'North' | 'South' | 'East' | 'West'
function qbx.getCardinalDirection(entity)
    -- heading is between 0 - 360 (excluding 360)
    local heading = GetEntityHeading(entity) % 360

    if heading < 45 or heading >= 315 then
        return 'North'
    end

    if heading >= 45 and heading < 135 then
        return 'West'
    end

    if heading >= 135 and heading < 225 then
        return 'South'
    end

    -- heading >= 225 and heading < 315
    return 'East'
end

if isServer then
    ---@class LibSpawnVehicleParams
    ---@field model integer
    ---@field coords vector4
    ---@field pedToWarp? integer
    ---@field props? table https://overextended.dev/ox_lib/Modules/VehicleProperties/Client#vehicle-properties

    ---Creates a vehicle on the server-side and returns its `netId`.
    ---
    ---The `CreateVehicleServerSetter` native uses only the server to create a vehicle instead of using the client as well.
    ---To get the vehicle on the client first check and wait for it to exist using the `NetworkDoesEntityExistWithNetworkId` native,
    ---then get the vehicle's id by using `NetToVeh`.
    --[[

    lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end)
    ]]
    ---@param params LibSpawnVehicleParams
    ---@return integer netId
    function qbx.spawnVehicle(params)
        local model = params.model
        local coords = params.coords
        local ped = params.pedToWarp
        local props = params.props

        local tempVehicle = CreateVehicle(model, 0, 0, 0, 0, true, true)
        while not DoesEntityExist(tempVehicle) do Wait(0) end

        local vehicleType = GetVehicleType(tempVehicle)
        DeleteEntity(tempVehicle)

        local veh = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)
        while not DoesEntityExist(veh) do Wait(0) end
        while GetVehicleNumberPlateText(veh) == '' do Wait(0) end

        if ped then
            SetPedIntoVehicle(ped, veh, -1)
        end

        local owner = lib.waitFor(function()
            local owner = NetworkGetEntityOwner(veh)
            if owner ~= -1 then return owner end
        end, 5000)

        local netId = NetworkGetNetworkIdFromEntity(veh)
        TriggerClientEvent('qbx_core:client:vehicleSpawned', owner, netId, props)
        return netId
    end
else
    ---@class LibDrawTextParams
    ---@field text string
    ---@field scale? integer default: `0.35`
    ---@field font? integer default: `4`
    ---@field color? vector4 rgba, white by default

    ---@class LibDrawText2DParams : LibDrawTextParams
    ---@field coords vector2
    ---@field width? number default: `1.0`
    ---@field height? number default: `1.0`

    ---Draws text onto the screen in 2D space for a single frame.
    ---@param params LibDrawText2DParams
    function qbx.drawText2d(params)
        local text = params.text
        local coords = params.coords
        local scale = params.scale or 0.35
        local font = params.font or 4
        local color = params.color or vec4(255, 255, 255, 255)
        local width = params.width or 1.0
        local height = params.height or 1.0

        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(coords.x - width / 2, coords.y - height / 2 + 0.005)
    end

    ---@class LibDrawText3DParams : LibDrawTextParams
    ---@field coords vector3

    ---Draws text onto the screen in 3D space for a single frame.
    ---@param params LibDrawText3DParams
    function qbx.drawText3d(params) -- luacheck: ignore
        local text = params.text
        local coords = params.coords
        local scale = params.scale or 0.35
        local font = params.font or 4
        local color = params.color or vec4(255, 255, 255, 255)

        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        SetDrawOrigin(coords.x, coords.y, coords.z, 0)
        EndTextCommandDisplayText(0.0, 0.0)

        local factor = #text / 370
        DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
        ClearDrawOrigin()
    end

    ---Gets and returns an entity handle and network id from a state bag name
    ---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
    ---@async
    ---@param bagName string
    ---@return integer entity, integer netId
    function qbx.getEntityAndNetIdFromBagName(bagName)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        local entity = lib.waitFor(function()
            if NetworkDoesEntityExistWithNetworkId(netId) then
                return NetworkGetEntityFromNetworkId(netId)
            end
        end, ('statebag timed out while awaiting entity creation! (%s)'):format(bagName), 10000)

        if not entity then
            lib.print.error(('statebag received invalid entity! (%s)'):format(bagName))
            return 0, 0
        end

        return entity, netId
    end

    ---Returns a state bag handler made for entities
    ---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
    ---@param keyFilter string
    ---@param cb fun(entity: number, netId: number, value: any, bagName: string)
    ---@return number
    function qbx.entityStateHandler(keyFilter, cb)
        return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value)
            local entity, netId = qbx.getEntityAndNetIdFromBagName(bagName)
            if entity then
                cb(entity, netId, value, bagName)
            end
        end)
    end

    ---Deletes the specified vehicle and returns whether it was successful.
    ---@param vehicle integer
    ---@return boolean deleted
    function qbx.deleteVehicle(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        return not DoesEntityExist(vehicle)
    end

    ---Returns the model name of the given vehicle.
    ---@param vehicle integer
    ---@return string
    function qbx.getVehicleDisplayName(vehicle)
        return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    end

    ---Returns the brand name of the given vehicle.
    ---@param vehicle integer
    ---@return string
    function qbx.getVehicleMakeName(vehicle)
        return GetLabelText(GetMakeNameFromVehicleModel(GetEntityModel(vehicle)))
    end

    ---Returns the street name and cross section name at the given coords.
    ---@param coords vector3
    ---@return { main: string, cross: string }
    function qbx.getStreetName(coords)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        return { main = GetStreetNameFromHashKey(street1), cross = GetStreetNameFromHashKey(street2) }
    end

    ---Returns the name of the zone at the given coords.
    ---@param coords vector3
    ---@return string
    function qbx.getZoneName(coords)
        return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    end

    ---Set an extra on the given vehicle.
    ---@param vehicle integer
    ---@param extra integer
    ---@param enable boolean
    function qbx.setVehicleExtra(vehicle, extra, enable)
        if not DoesExtraExist(vehicle, extra) then return end
        SetVehicleExtra(vehicle, extra, not enable)
    end

    ---Enables all the extras of the given vehicle.
    ---@param vehicle integer
    function qbx.resetVehicleExtras(vehicle)
        for i = 1, 20 do
            qbx.setVehicleExtra(vehicle, i, true)
        end
    end

    ---Sets all the extras of the given vehicle.
    ---@param vehicle integer
    ---@param extras table<integer, boolean>
    function qbx.setVehicleExtras(vehicle, extras)
        qbx.resetVehicleExtras(vehicle)

        for id, enable in pairs(extras) do
            qbx.setVehicleExtra(vehicle, id, enable)
        end
    end

    qbx.armsWithoutGloves = lib.table.freeze({
        male = lib.table.freeze({
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true,
            [10] = true,
            [11] = true,
            [12] = true,
            [13] = true,
            [14] = true,
            [15] = true,
            [18] = true,
            [26] = true,
            [52] = true,
            [53] = true,
            [54] = true,
            [55] = true,
            [56] = true,
            [57] = true,
            [58] = true,
            [59] = true,
            [60] = true,
            [61] = true,
            [62] = true,
            [112] = true,
            [113] = true,
            [114] = true,
            [118] = true,
            [125] = true,
            [132] = true
        }),

        female = lib.table.freeze({
            [0] = true,
            [1] = true,
            [2] = true,
            [3] = true,
            [4] = true,
            [5] = true,
            [6] = true,
            [7] = true,
            [8] = true,
            [9] = true,
            [10] = true,
            [11] = true,
            [12] = true,
            [13] = true,
            [14] = true,
            [15] = true,
            [19] = true,
            [59] = true,
            [60] = true,
            [61] = true,
            [62] = true,
            [63] = true,
            [64] = true,
            [65] = true,
            [66] = true,
            [67] = true,
            [68] = true,
            [69] = true,
            [70] = true,
            [71] = true,
            [129] = true,
            [130] = true,
            [131] = true,
            [135] = true,
            [142] = true,
            [149] = true,
            [153] = true,
            [157] = true,
            [161] = true,
            [165] = true
        }),
    })

    ---Returns if the local ped is wearing gloves.
    ---@return boolean
    function qbx.isWearingGloves()
        local armIndex = GetPedDrawableVariation(cache.ped, 3)
        local model = GetEntityModel(cache.ped)
        local tble = qbx.armsWithoutGloves[model == `mp_m_freemode_01` and 'male' or 'female']
        return not tble[armIndex]
    end

    ---Attempts to load an audio bank and returns whether it was successful.
    ---Remember to use `ReleaseScriptAudioBank` since you can only load up to 10 banks.
    ---@param audioBank string
    ---@param timeout number?
    ---@return boolean
    function qbx.loadAudioBank(audioBank, timeout)
        return lib.waitFor(function()
            if RequestScriptAudioBank(audioBank, false) then
                return true
            end
        end, ('timed out while requesting audio bank! (%s)'):format(audioBank), timeout or 500) or false
    end

    ---@class LibPlayAudioParams
    ---@field audioName string
    ---@field audioRef string
    ---@field returnSoundId? boolean
    ---@field audioSource? number | vector3 entity handle or vector3 coords
    ---@field range? number only used if `audioSource` is a vector3 coordinate

    ---Plays a sound with the provided audio name and audio ref.
    ---If `returnSoundId` is false or not specified the soundId is released,
    ---otherwise the function returns the soundId without releasing it.
    ---@param params LibPlayAudioParams
    ---@return number? soundId
    function qbx.playAudio(params)
        local audioName = params.audioName
        local audioRef = params.audioRef
        local returnSoundId = params.returnSoundId or false
        local source = params.audioSource
        local range = params.range or 5.0

        local soundId = GetSoundId()

        local sourceType = type(source)
        if sourceType == 'vector3' then
            local coords = source
            PlaySoundFromCoord(soundId, audioName, coords.x, coords.y, coords.z, audioRef, false, range, false)
        elseif sourceType == 'number' then
            PlaySoundFromEntity(soundId, audioName, source, audioRef, false, false)
        else
            PlaySoundFrontend(soundId, audioName, audioRef, true)
        end

        if returnSoundId then
           return soundId
        end

        ReleaseSoundId(soundId)
    end
end

_ENV.qbx = qbx
