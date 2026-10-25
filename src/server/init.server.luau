--!strict
local PlayerDataService = require(script.PlayerDataService)
local RemoteService = require(script.RemoteService)
local GameplayService = require(script.GameplayService)
local gameplay = GameplayService.new(PlayerDataService)
RemoteService.start(gameplay)
gameplay.start()
PlayerDataService.start()
