--!strict
local TweenService=game:GetService("TweenService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Format=require(Shared:WaitForChild("Format"))
local Effects={}
local energyColors={Color3.fromRGB(136,255,155),Color3.fromRGB(255,230,110),Color3.fromRGB(112,232,255)}
function Effects.new(gui:ScreenGui,settings:any):any
 local live: {TextLabel}={}
 local api={}
 local function clear()
  for _,label in ipairs(live) do label:Destroy() end;table.clear(live)
 end
 local function show(value:string,reward:boolean)
  if #live>=(if reward then 1 else 6) and reward then clear() end
  if #live>=6 then local first=table.remove(live,1);if first then first:Destroy() end end
  local label=Instance.new("TextLabel");label.Name="ConfirmedEffect";label.AnchorPoint=Vector2.new(1,0.5)
  label.Size=UDim2.fromOffset(if reward then 320 else 180,if reward then 80 else 42)
  label.Position=UDim2.new(1,-16,if reward then 0.2 else 0.55,-#live*32)
  label.Text=value;label.TextColor3=if reward then Color3.fromRGB(255,236,128) else energyColors[#live%#energyColors+1]
  label.TextStrokeTransparency=0.5;label.TextStrokeColor3=Color3.fromRGB(17,95,95);label.Font=Enum.Font.GothamBold
  label.TextSize=if reward then 24 else 23;label.TextWrapped=true;label.BackgroundTransparency=1;label.ZIndex=40;label.Parent=gui;table.insert(live,label)
  if reward then
   local gradient=Instance.new("UIGradient");gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,214,85)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(129,255,155)),ColorSequenceKeypoint.new(1,Color3.fromRGB(105,227,255))});gradient.Parent=label
  end
  if settings.Animations then
   TweenService:Create(label,TweenInfo.new(if reward then 1.7 else 0.8,Enum.EasingStyle.Quad),{Position=label.Position-UDim2.fromOffset(0,45),TextTransparency=1,TextStrokeTransparency=1}):Play()
  end
  task.delay(if reward then 1.8 else 0.9,function() local i=table.find(live,label);if i then table.remove(live,i);label:Destroy() end end)
 end
 function api.training(amount:number) if settings.Popups then show("+"..Format.multiplier(amount).." Energy",false) end end
 function api.rebirth(rebirths:number) show("REBIRTH!\nMultiplikator ×"..Format.multiplier(1+rebirths*0.5),true) end
 function api.refresh() if not settings.Popups or not settings.Animations then clear() end end
 return api
end
return Effects
