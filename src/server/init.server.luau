--!strict
-- Publish diagnostics before any dependency is required. A failed stage is visible to clients.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local status=Instance.new("Folder");status.Name="BikeRuntime";status.Parent=ReplicatedStorage
status:SetAttribute("State","Starting")
local studio=RunService:IsStudio()
local preview=studio and workspace:GetAttribute("StudioPreviewData")~=false
local diagnostic=studio or (game.PrivateServerId~="" and game.PrivateServerOwnerId~=0 and script:GetAttribute("DiagnosticsEnabled")==true)
status:SetAttribute("Diagnostics",diagnostic)
status:SetAttribute("DataMode",if preview then "STUDIO PREVIEW • NICHT DAUERHAFT" elseif studio then "ISOLIERTER STUDIO-TESTSTORE" else "PERSISTENT")
local function stage(name:string,callback:()->())
 status:SetAttribute("Stage",name)
 local ok,err=pcall(function():any callback();return true end)
 if not ok then
  warn("[BikeBootstrap] "..name..": "..tostring(err))
  status:SetAttribute("State","Failed")
  status:SetAttribute("Error",if diagnostic then string.sub(tostring(err),1,1200) else "Initialisierung fehlgeschlagen: "..name)
  error("Bike bootstrap failed at "..name,0)
 end
 status:SetAttribute(name,"OK")
end
stage("WorldContract",function()
 local contract=require(ReplicatedStorage.Shared.RuntimeContract)
 local missing=contract.inspect(game)
 assert(#missing==0,"Missing world components: "..table.concat(missing,", "))
end)
local data:any;local gameplay:any
stage("Dependencies",function()
 data=require(script.PlayerDataService)
 local Gameplay=require(script.GameplayService)
 data.configure({Preview=preview,StoreName=if studio and not preview then "BikeEvolution_StudioTest_v2" else nil})
 gameplay=Gameplay.new(data)
end)
stage("Remotes",function() require(script.RemoteService).start(gameplay) end)
stage("Interactions",function() gameplay.start() end)
stage("Profiles",function() data.start() end)
status:SetAttribute("State","Ready")
