local players = require 'server.storage.players'

---@class StorageFunctions
---@field insertBan fun(request: InsertBanRequest)
---@field fetchBan fun(request: GetBanRequest): BanEntity?
---@field deleteBan fun(request: GetBanRequest)
---@field upsertPlayerEntity fun(request: UpsertPlayerRequest)
---@field fetchPlayerSkin fun(citizenId: string): PlayerSkin?
---@field fetchPlayerEntity fun(citizenId: string): PlayerEntity?
---@field fetchAllPlayerEntities fun(license2: string, license?: string): PlayerEntity[]
---@field deletePlayer fun(citizenId: string): boolean success
---@field fetchIsUnique fun(type: UniqueIdType, value: string|number): boolean
---@field addPlayerToJob fun(citizenid: string, group: string, grade: integer)
---@field addPlayerToGang fun(citizenid: string, group: string, grade: integer)
---@field fetchPlayerGroups fun(citizenid: string): table<string, integer>, table<string, integer> jobs, gangs
---@field removePlayerFromJob fun(citizenid: string, group: string)
---@field removePlayerFromGang fun(citizenid: string, group: string)
---@field setPlayerMetadata fun(citizenid: string, metadata: PlayerMetadata): boolean success
---@field setPlayerPrimaryJob fun(citizenid: string, job: PlayerJob): boolean success
---@field setPlayerPrimaryGang fun(citizenid: string, gang: PlayerGang): boolean success
---@field setPlayerMoney fun(citizenid: string, money: Money): boolean success
---@field setPlayerCharInfo fun(citizenid: string, charinfo: PlayerCharInfo): boolean success

---@type StorageFunctions
return players