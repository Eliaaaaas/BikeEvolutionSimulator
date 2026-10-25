--!strict
local PlayerDataService = require(script.PlayerDataService)
local RemoteService = require(script.RemoteService)
RemoteService.start(PlayerDataService)
PlayerDataService.start()
