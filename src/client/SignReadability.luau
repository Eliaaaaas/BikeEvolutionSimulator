--!strict
-- Studio/private diagnostics only. No automatic concealment, resizing or replacement of bad geometry.
local Sign={}
function Sign.inspect(gui:SurfaceGui):{string}
 local issues={}
 local part=gui.Parent
 if not part or not part:IsA("BasePart") or gui.Adornee~=part then table.insert(issues,"Adornee mismatch") end
 if gui.SizingMode~=Enum.SurfaceGuiSizingMode.PixelsPerStud or gui.PixelsPerStud<64 then table.insert(issues,"Incorrect canvas sizing") end
 if gui.Face~=Enum.NormalId.Front and gui.Face~=Enum.NormalId.Back then table.insert(issues,"Incorrect caption face") end
 local text=gui:FindFirstChild("Caption")
 if not text or not text:IsA("TextLabel") or text.Text=="" then table.insert(issues,"Missing caption");return issues end
 if not text.TextScaled or text.ClipsDescendants or text.TextStrokeTransparency>=1 or text.ZIndex<1 then table.insert(issues,"Incorrect caption properties") end
 -- Bounds/Fits are renderer measurements, not constants to fabricate in the asset generator.
 local bounds=text.TextBounds
 if bounds.X>0 and bounds.Y>0 then
  if not text.TextFits or bounds.X>text.AbsoluteSize.X+1 or bounds.Y>text.AbsoluteSize.Y+1 then table.insert(issues,"Caption does not fit") end
 end
 return issues
end
function Sign.new(_settings:any,ui:any)
 local runtime=game:GetService("ReplicatedStorage"):WaitForChild("BikeRuntime")
 if runtime:GetAttribute("Diagnostics")~=true then return end
 task.delay(1,function()
  if not ui.Gui.Parent then return end
  local checked=0;local measured=0;local failures={}
  for _,object in ipairs(workspace:GetDescendants()) do
   if object:IsA("SurfaceGui") and object.Name=="SignCaption" then
    checked+=1
    local caption=object:FindFirstChild("Caption")
    if caption and caption:IsA("TextLabel") and caption.TextBounds.X>0 and caption.TextBounds.Y>0 then measured+=1 end
    local issues=Sign.inspect(object)
    if #issues>0 then table.insert(failures,object:GetFullName()..": "..table.concat(issues,", ")) end
   end
  end
  runtime:SetAttribute("SignDiagnostics",tostring(checked).." captions / "..tostring(measured).." measured / "..tostring(checked-measured).." pending / "..tostring(#failures).." problems")
  if #failures>0 then
   local message=string.sub(table.concat(failures,"; "),1,1000)
   runtime:SetAttribute("SignError",message);warn("[SignDiagnostics]",message)
  else runtime:SetAttribute("SignError",nil) end
 end)
end
return Sign
