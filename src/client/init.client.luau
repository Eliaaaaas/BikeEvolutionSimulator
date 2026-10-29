--!strict
-- This dependency-free ribbon survives an error in any application module.
local player=game:GetService("Players").LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="BikeDiagnostics";gui.ResetOnSpawn=false
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.DisplayOrder=100;gui.Parent=player:WaitForChild("PlayerGui")
local label=Instance.new("TextLabel");label.Size=UDim2.new(0.65,0,0,74);label.Position=UDim2.new(0.35,0,0,88)
label.BackgroundColor3=Color3.fromRGB(21,63,83);label.BackgroundTransparency=0.12
label.TextColor3=Color3.fromRGB(255,231,147);label.Font=Enum.Font.GothamBold;label.TextSize=12
label.TextWrapped=true;label.Text="CLIENT STARTET • warte auf Server";label.Parent=gui
local runtime=game:GetService("ReplicatedStorage"):WaitForChild("BikeRuntime",15)
local clientStage="Starte Anwendung"
local failed=false
local function refresh()
 if not runtime then label.Text="SERVER FEHLT • BikeRuntime wurde nicht erzeugt. Output und Server-Script prüfen.";return end
 local state=runtime:GetAttribute("State")
 label.Visible=failed or runtime:GetAttribute("Diagnostics")==true or state~="Ready" or runtime:GetAttribute("BikeState")=="Failed"
 label.Text=tostring(runtime:GetAttribute("DataMode")).."\nSERVER "..tostring(state).." / "..tostring(runtime:GetAttribute("Stage")).." • CLIENT "..clientStage.."\n"..tostring(runtime:GetAttribute("BikeError") or runtime:GetAttribute("SignError") or runtime:GetAttribute("Error") or "")
end
if runtime then runtime.AttributeChanged:Connect(refresh) end
refresh()
local ok,err=pcall(function()
 require(script.ClientApp).start(function(stage:string) clientStage=stage;refresh() end)
end)
if not ok then failed=true;clientStage="FEHLER: "..tostring(err);warn("[BikeClient]",err);refresh() end
