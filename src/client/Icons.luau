--!strict
-- Small vector-style widget icons: no external images or uploaded assets.
local Icons={}
function Icons.resource(parent:Instance,name:string):Frame
 local icon=Instance.new("Frame");icon.Name=name.."Icon";icon.Size=UDim2.fromOffset(36,36);icon.BackgroundTransparency=1;icon.BorderSizePixel=0;icon.Parent=parent
 if name=="Cash" then
  -- A coin silhouette, not a dollar icon or surrounding resource tile.
  local coin=Instance.new("Frame");coin.Name="Coin";coin.Size=UDim2.fromScale(0.76,0.76);coin.Position=UDim2.fromScale(0.12,0.12);coin.BackgroundColor3=Color3.fromRGB(219,151,34);coin.BorderSizePixel=0;coin.Parent=icon
  local round=Instance.new("UICorner");round.CornerRadius=UDim.new(1,0);round.Parent=coin
  local face=Instance.new("Frame");face.Name="CoinFace";face.Size=UDim2.fromScale(0.76,0.76);face.Position=UDim2.fromScale(0.12,0.12);face.BackgroundColor3=Color3.fromRGB(255,218,86);face.BorderSizePixel=0;face.Parent=coin
  local inner=round:Clone();inner.Parent=face
  local stamp=Instance.new("TextLabel");stamp.Size=UDim2.fromScale(1,1);stamp.BackgroundTransparency=1;stamp.Text="I";stamp.Font=Enum.Font.GothamBold;stamp.TextSize=17;stamp.TextColor3=Color3.fromRGB(174,113,22);stamp.Parent=face
 else
  local symbol=Instance.new("TextLabel");symbol.Name="Symbol";symbol.Size=UDim2.fromScale(1,1);symbol.BackgroundTransparency=1
  symbol.Text=if name=="Energy" then "ϟ" else "↻";symbol.Font=Enum.Font.GothamBold;symbol.TextScaled=true
  symbol.TextColor3=if name=="Energy" then Color3.fromRGB(255,221,72) else Color3.fromRGB(95,235,235)
  symbol.TextStrokeColor3=Color3.fromRGB(14,45,61);symbol.TextStrokeTransparency=0.3;symbol.Parent=icon
 end
 return icon
end
function Icons.draw(parent:Instance,name:string):Frame
 if name=="Energy" or name=="Cash" or name=="Rebirths" then
  local icon=Icons.resource(parent,name);icon.Position=UDim2.fromOffset(10,7);icon.Size=UDim2.fromOffset(32,32);return icon
 end
 local icon=Instance.new("Frame");icon.Name="Icon";icon.Size=UDim2.fromOffset(32,32);icon.Position=UDim2.fromOffset(10,7);icon.BackgroundTransparency=1;icon.Parent=parent
 local function shape(x:number,y:number,w:number,h:number,round:boolean,outline:boolean?):Frame
  local f=Instance.new("Frame");f.Size=UDim2.fromScale(w,h);f.Position=UDim2.fromScale(x,y);f.BackgroundColor3=Color3.new(1,1,1);f.BorderSizePixel=0;f.Parent=icon
  if round then local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f end
  if outline then f.BackgroundTransparency=1;local stroke=Instance.new("UIStroke");stroke.Thickness=2;stroke.Color=Color3.new(1,1,1);stroke.Parent=f end
  return f
 end
 if name=="Garage" then
  shape(0.02,0.48,0.4,0.4,true,true);shape(0.58,0.48,0.4,0.4,true,true)
  local a=shape(0.25,0.42,0.5,0.06,false);a.Rotation=-30
  local b=shape(0.4,0.27,0.06,0.42,false);b.Rotation=-30;shape(0.6,0.22,0.3,0.06,false)
 elseif name=="Shop" then
  shape(.15,.38,.7,.5,true,true);shape(.29,.18,.42,.32,true,true)
  shape(.32,.5,.1,.2,true);shape(.58,.5,.1,.2,true)
 elseif name=="Pets" then
  shape(0.22,0.47,0.58,0.4,true)
  for i=0,3 do shape(0.03+i*0.24,0.12+(if i==0 or i==3 then 0.1 else 0),0.19,0.25,true) end
 elseif name=="Race" then
  shape(0.12,0.1,0.07,0.85,false)
  for x=0,2 do for y=0,1 do if (x+y)%2==0 then shape(0.2+x*0.22,0.12+y*0.2,0.22,0.2,false) end end end
 elseif name=="Worlds" then
  shape(0.08,0.08,0.84,0.84,true,true);shape(0.3,0.08,0.4,0.84,true,true);shape(0.1,0.48,0.8,0.04,false)
 else
  local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.TextColor3=Color3.new(1,1,1)
  text.Text=({Energy="ϟ",Cash="$",Rebirths="↻",Settings="⚙"})[name] or "•"
  text.Font=Enum.Font.GothamBold;text.TextSize=30;text.Parent=icon
 end
 return icon
end
return Icons
