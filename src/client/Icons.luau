--!strict
-- Small vector-style widget icons: no external images or uploaded assets.
local Icons={}
function Icons.resource(parent:Instance,name:string):Frame
 local icon=Instance.new("Frame");icon.Name=name.."Icon";icon.Size=UDim2.fromOffset(36,36);icon.BackgroundTransparency=1;icon.BorderSizePixel=0;icon.Parent=parent
 local function shape(label:string,x:number,y:number,w:number,h:number,color:Color3,rotation:number?,round:boolean?):Frame
  local f=Instance.new("Frame");f.Name=label;f.Position=UDim2.fromScale(x,y);f.Size=UDim2.fromScale(w,h);f.Rotation=rotation or 0;f.BackgroundColor3=color;f.BorderSizePixel=0;f.Parent=icon
  if round then local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=f end
  return f
 end
 local gold=Color3.fromRGB(255,217,65);local orange=Color3.fromRGB(218,119,26)
 if name=="Cash" then
  shape("CoinShadow",.14,.18,.76,.76,Color3.fromRGB(117,70,25),0,true)
  shape("Coin",.1,.1,.76,.76,orange,0,true)
  local face=shape("CoinFace",.18,.14,.6,.6,gold,0,true)
  local gradient=Instance.new("UIGradient");gradient.Color=ColorSequence.new(Color3.fromRGB(255,244,153),gold);gradient.Rotation=55;gradient.Parent=face
  local stamp=Instance.new("TextLabel");stamp.Name="EmbossedDollar";stamp.Position=UDim2.fromScale(.18,.12);stamp.Size=UDim2.fromScale(.6,.66);stamp.BackgroundTransparency=1;stamp.Text="$";stamp.Font=Enum.Font.GothamBold;stamp.TextScaled=true;stamp.TextColor3=Color3.fromRGB(180,104,22);stamp.Parent=icon
  shape("CoinGlint",.23,.22,.2,.045,Color3.fromRGB(255,255,215),-35,true)
 elseif name=="Energy" then
  for _,layer in ipairs({{Name="BoltDepth",Offset=.045,Color=orange},{Name="BoltFace",Offset=0,Color=gold}}) do
   for _,p in ipairs({{.39,.08,.21,.44,30},{.25,.43,.47,.16,-7},{.4,.49,.2,.44,30}}) do
    shape(layer.Name,p[1]+layer.Offset,p[2]+layer.Offset,p[3],p[4],layer.Color,p[5])
   end
  end
  shape("BoltGlint",.43,.15,.055,.22,Color3.fromRGB(255,253,196),30,true)
 else
  local colors={Color3.fromRGB(67,227,220),Color3.fromRGB(157,112,249)}
  for arc=0,1 do
   for n=0,6 do
    local angle=math.rad(arc*180+20+n*19)
    local color=colors[arc+1]
    shape("RebirthArc",.46+math.cos(angle)*.31,.46+math.sin(angle)*.31,.18,.095,color,math.deg(angle)+90,true)
   end
   local a=math.rad(arc*180+146)
   local x,y=.46+math.cos(a)*.31,.46+math.sin(a)*.31
   shape("Arrowhead",x,y,.23,.12,colors[arc+1],arc*180+20)
   shape("Arrowhead",x+.04,y-.05,.12,.23,colors[arc+1],arc*180+20)
  end
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
 elseif name=="Settings" then
  shape(.28,.28,.44,.44,true,true)
  for i=0,7 do local a=i*math.pi/4;local tooth=shape(.44+math.sin(a)*.32,.44+math.cos(a)*.32,.12,.2,false);tooth.Rotation=-i*45 end
 else
  local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.TextColor3=Color3.new(1,1,1)
  text.Text=({Energy="ϟ",Cash="$",Rebirths="↻",Settings="⚙"})[name] or "•"
  text.Font=Enum.Font.GothamBold;text.TextSize=30;text.Parent=icon
 end
 return icon
end
return Icons
