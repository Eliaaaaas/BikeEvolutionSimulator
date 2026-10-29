--!strict
-- Packaged Roblox audio names verified in Roblox-Client-Tracker rbxManifest.txt.
-- No asset IDs, network audio, permissions or paid uploads required.
local SoundService=game:GetService("SoundService")
local Audio={}
local cues={Button="volume_slider.ogg",Training="action_jump.mp3",Selected="action_jump_land.mp3",
 Unlock="action_get_up.mp3",Rebirth="action_get_up.mp3",Success="volume_slider.ogg"}
function Audio.new(settings:any):any
 local pool={};local last: {[string]:number}={}
 local api={}
 function api.play(cue:string)
  if not settings.Sound or settings.Volume<=0 or not cues[cue] then return end
  if os.clock()-(last[cue] or -math.huge)<(if cue=="Training" then 0.18 else 0.08) then return end
  last[cue]=os.clock()
  if #pool>=6 then local oldest=table.remove(pool,1);if oldest then oldest:Destroy() end end
  local sound=Instance.new("Sound");sound.SoundId="rbxasset://sounds/"..cues[cue];sound:SetAttribute("CueLevel",if cue=="Training" then 0.12 else 0.3);sound.Volume=settings.Volume*(sound:GetAttribute("CueLevel") or 0.3)
  sound.PlaybackSpeed=if cue=="Training" then 1.7 elseif cue=="Rebirth" then 1.25 else 1
  sound.Parent=SoundService;table.insert(pool,sound);sound:Play()
  task.delay(3,function() local index=table.find(pool,sound);if index then table.remove(pool,index);sound:Destroy() end end)
 end
 function api.refresh()
  for _,sound in ipairs(pool) do sound.Volume=if settings.Sound then settings.Volume*(sound:GetAttribute("CueLevel") or 0.3) else 0 end
 end
 return api
end
return Audio
