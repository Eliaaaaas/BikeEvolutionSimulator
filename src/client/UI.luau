--!strict
-- Roblox widgets only; no economy or training authority on the client.
local UserInputService = game:GetService("UserInputService")
local UI = {}
local colors = {Ink=Color3.fromRGB(28,76,88),Cream=Color3.fromRGB(249,255,237),Teal=Color3.fromRGB(34,177,164),
 Gold=Color3.fromRGB(255,205,81),Orange=Color3.fromRGB(249,151,75),Blue=Color3.fromRGB(75,177,230),Purple=Color3.fromRGB(154,131,227)}
local function create(className: string, parent: Instance?, props: any): any
 local object: any = Instance.new(className)
 for key,value in pairs(props) do object[key]=value end
 object.Parent=parent
 return object
end
local function round(object: Instance, radius: number)
 create("UICorner",object,{CornerRadius=UDim.new(0,radius)})
end
local function label(parent: Instance, text: string, size: UDim2, position: UDim2, textSize: number): any
 return create("TextLabel",parent,{BackgroundTransparency=1,Text=text,Size=size,Position=position,
  Font=Enum.Font.GothamBold,TextSize=textSize,TextColor3=colors.Ink,TextWrapped=true})
end
local function button(parent: Instance,text: string,color: Color3,size: UDim2,position: UDim2): any
 local result=create("TextButton",parent,{Text=text,Size=size,Position=position,Font=Enum.Font.GothamBold,
  TextSize=15,TextColor3=colors.Ink,BackgroundColor3=color,AutoButtonColor=true,BorderSizePixel=0,TextWrapped=true})
 round(result,14)
 return result
end
local function panel(parent: Instance,size: UDim2,position: UDim2): any
 local result=create("Frame",parent,{Size=size,Position=position,BackgroundColor3=colors.Cream,BackgroundTransparency=0.08,BorderSizePixel=0})
 round(result,18)
 create("UIStroke",result,{Color=Color3.fromRGB(255,255,255),Thickness=1.5,Transparency=0.35})
 return result
end
function UI.new(playerGui: Instance): any
 local gui=create("ScreenGui",playerGui,{Name="PalmBayUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
  ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets})
 local root=create("Frame",gui,{Size=UDim2.new(1,-20,1,-20),Position=UDim2.fromOffset(10,10),BackgroundTransparency=1})
 local top=panel(root,UDim2.new(1,0,0,106),UDim2.new())
 label(top,"PALM BAY  •  BIKE EVOLUTION",UDim2.new(1,-16,0,22),UDim2.fromOffset(8,5),13)
 local energy=label(top,"⚡ Energy\n…",UDim2.new(0.33,0,0,48),UDim2.new(0,0,0,27),17)
 local cash=label(top,"● Cash\n…",UDim2.new(0.33,0,0,48),UDim2.new(0.33,0,0,27),17)
 local rebirths=label(top,"↻ Rebirths\n…",UDim2.new(0.34,0,0,48),UDim2.new(0.66,0,0,27),17)
 local multiplier=label(top,"Trainingsmultiplikator ×1",UDim2.new(1,-12,0,22),UDim2.fromOffset(6,79),13)
 local bottom=panel(root,UDim2.new(1,0,0,190),UDim2.new(0,0,1,-190))
 local status=label(bottom,"Spielerdaten werden sicher geladen …",UDim2.new(1,-16,0,34),UDim2.fromOffset(8,4),13)
 local training=button(bottom,"⚡ TRAINING",colors.Gold,UDim2.new(0.5,-12,0,58),UDim2.fromOffset(8,42))
 local rebirth=button(bottom,"↻ REBIRTH",colors.Orange,UDim2.new(0.5,-12,0,58),UDim2.new(0.5,4,0,42))
 local previews={}
 for i,entry in ipairs({{Name="Garage",Color=colors.Blue},{Name="Pets",Color=colors.Purple},{Name="Race",Color=colors.Orange},{Name="Worlds",Color=colors.Teal}}) do
  local b=button(bottom,entry.Name.."\nVORSCHAU",entry.Color,UDim2.new(0.25,-10,0,58),UDim2.new((i-1)*0.25,6,0,110))
  b.TextSize=12;previews[entry.Name]=b
 end
 label(bottom,"Automatisch 1×/Sek. • Tippen = Extra-Impuls",UDim2.new(1,-8,0,18),UDim2.new(0,4,1,-20),11)
 local shade=create("TextButton",root,{Text="",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(20,61,75),
  BackgroundTransparency=0.25,Visible=false,AutoButtonColor=false,ZIndex=10})
 local modal=panel(shade,UDim2.new(0.92,0,0,280),UDim2.fromScale(0.04,0.5))
 modal.AnchorPoint=Vector2.new(0,0.5);modal.ZIndex=11
 create("UISizeConstraint",modal,{MaxSize=Vector2.new(560,400)})
 local title=label(modal,"",UDim2.new(1,-24,0,36),UDim2.fromOffset(12,10),21);title.ZIndex=12
 local body=label(modal,"",UDim2.new(1,-28,0,115),UDim2.fromOffset(14,50),16);body.ZIndex=12
 local confirm=button(modal,"Bestätigen",colors.Gold,UDim2.new(0.5,-18,0,55),UDim2.new(0.5,6,1,-68));confirm.ZIndex=12
 local cancel=button(modal,"Schließen",colors.Teal,UDim2.new(0.5,-18,0,55),UDim2.new(0,12,1,-68));cancel.ZIndex=12
 -- Keep the built-in mobile thumbstick/jump controls uncovered.
 local function layout()
  local size=root.AbsoluteSize
  if UserInputService.TouchEnabled and size.X>size.Y then
   bottom.Size=UDim2.new(0.54,0,0,190)
   bottom.Position=UDim2.new(0.23,0,1,-190)
  else
   bottom.Size=UDim2.new(1,0,0,190)
   bottom.Position=UDim2.new(0,0,1,-190-(if UserInputService.TouchEnabled then 130 else 0))
  end
 end
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 layout()
 local selected: any = nil
 cancel.Activated:Connect(function() shade.Visible=false;selected=nil end)
 confirm.Activated:Connect(function()
  local callback=selected;selected=nil;shade.Visible=false
  if callback then callback() end
 end)
 local api: any={Gui=gui,Energy=energy,Cash=cash,Rebirths=rebirths,Multiplier=multiplier,Status=status,
  Training=training,Rebirth=rebirth,Previews=previews}
 function api.dialog(heading: string, message: string, action: (() -> ())?)
  title.Text=heading;body.Text=message;selected=action;confirm.Visible=action~=nil;shade.Visible=true
 end
 function api.modalOpen(): boolean return shade.Visible end
 return api
end
return UI
