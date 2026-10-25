--!strict
-- Small vector-style widget icons: no external images or uploaded assets.
local Icons={}
function Icons.draw(parent:Instance,name:string):Frame
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
  text.Text=({Energy="ϟ",Cash="$",Rebirths="↻",Upgrades="★",Settings="⚙"})[name] or "•"
  text.Font=Enum.Font.GothamBold;text.TextSize=30;text.Parent=icon
 end
 return icon
end
return Icons
