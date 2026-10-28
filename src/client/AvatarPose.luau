--!strict
-- Procedural R15 hand/foot IK; R6 uses joint posing. No uploaded animation IDs.
local Pose={}
function Pose.new(character:Model,bike:Model?):any
 local hum=character:FindFirstChildOfClass("Humanoid");if not hum then return nil end
 local record:any={Character=character,Motors={},IK={},Attachments={},Tracks={},Connections={},Dirty=false}
 local animator=hum:FindFirstChildOfClass("Animator")
 if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end end
 local animate=character:FindFirstChild("Animate")
 if animate and animate:IsA("LocalScript") then record.Animate=animate;record.Disabled=animate.Disabled;animate.Disabled=true end
 for _,motor in ipairs(character:GetDescendants()) do
  if motor:IsA("Motor6D") then record.Motors[motor]={C0=motor:GetAttribute("RiderBaseC0") or motor.C0,RestoreC0=motor.C0,Transform=motor.Transform} end
 end
 if bike and hum.RigType==Enum.HumanoidRigType.R15 then
  local frame=bike:FindFirstChild("Frame")
  local frameRoot=if frame then frame:FindFirstChild("Pivot") else nil
  if not frameRoot or not frameRoot:IsA("BasePart") then return record end
  local function contact(group:Instance?,name:string,side:number):BasePart?
   if not group then return nil end
   for _,part in ipairs(group:GetDescendants()) do
    if part:IsA("BasePart") and part.Name==name and frameRoot.CFrame:PointToObjectSpace(part.Position).X*side>0 then return part end
   end
   return nil
  end
  local function ik(side:string,limb:string,tip:string,part:BasePart?,sign:number)
   local a=character:FindFirstChild(side..limb);local b=character:FindFirstChild(side..tip)
   if not a or not b or not a:IsA("BasePart") or not b:IsA("BasePart") or not part then return end
   local target=Instance.new("Attachment");target.Name="LocalRiderTarget"
   target.Position=Vector3.new(0,part.Size.Y/2+.035,0);target.Parent=part;table.insert(record.Attachments,target)
   local pole=Instance.new("Attachment");pole.Name="LocalRiderPole"
   -- Pole remains on its anatomical side, outside the frame. It does NOT rotate with the crank.
   local arm=tip=="Hand"
   pole.Position=Vector3.new(sign*(if arm then 2.2 else math.max(1.3,b.Size.X+1)),if arm then 3.7 else 2.4,if arm then -1 else -1.5)
   pole.Parent=frameRoot;table.insert(record.Attachments,pole)
   local control=Instance.new("IKControl");control.Name="ProceduralBikeIK";control.Type=Enum.IKControlType.Position
   control.ChainRoot=a;control.EndEffector=b;control.Target=target;control.Pole=pole
   -- Solve the palm/sole contact rather than the center of the hand or foot.
   control.EndEffectorOffset=CFrame.new(0,-b.Size.Y*.45,0)
   control.Weight=1;control.SmoothTime=0;control.Priority=10;control.Parent=hum;table.insert(record.IK,control)
  end
  local steering=bike:FindFirstChild("Steering");local crank=bike:FindFirstChild("Crank")
  for _,side in ipairs({"Left","Right"}) do
   local sign=if side=="Left" then -1 else 1
   ik(side,"UpperArm","Hand",contact(steering,"Grip",sign),sign)
   ik(side,"UpperLeg","Foot",contact(crank or frame,if crank then "Pedal" else "FootRest",sign),sign)
  end
 end
 -- CharacterAdded may precede streamed limbs/appearance sizing. Rebuild rather than keeping incomplete IK forever.
 table.insert(record.Connections,character.DescendantAdded:Connect(function() record.Dirty=true end))
 for _,part in ipairs(character:GetChildren()) do
  if part:IsA("BasePart") then table.insert(record.Connections,part:GetPropertyChangedSignal("Size"):Connect(function() record.Dirty=true end)) end
 end
 return record
end
function Pose.update(record:any,phase:number,riding:boolean,weight:number)
 for _,control in ipairs(record.IK) do control.Weight=math.min(1,control.Weight+weight) end
 for motor,base in pairs(record.Motors) do
  if not motor.Parent then continue end
  local name=motor.Name;local angle=0
  if riding and #record.IK>0 and (string.find(name,"Hip") or string.find(name,"Shoulder") or string.find(name,"Knee") or string.find(name,"Elbow") or string.find(name,"Ankle") or string.find(name,"Wrist")) then motor.C0=base.C0;motor.Transform=CFrame.identity;continue end
  if string.find(name,"Hip") then angle=if riding then -0.6+math.sin(phase+(if string.find(name,"Left") then 0 else math.pi))*0.6 else math.sin(phase+(if string.find(name,"Left") then 0 else math.pi))*0.55 end
  if string.find(name,"Shoulder") then angle=if riding then -0.95 else math.sin(phase+(if string.find(name,"Left") then math.pi else 0))*0.25 end
  if name=="Waist" then angle=if riding then -0.4 else -0.08 end
  motor.C0=motor.C0:Lerp(base.C0*CFrame.Angles(angle,0,0),weight)
  motor.Transform=CFrame.identity
 end
end
function Pose.fade(record:any,weight:number)
 for motor,base in pairs(record.Motors) do if motor.Parent then motor.C0=motor.C0:Lerp(base.RestoreC0,weight) end end
 for _,control in ipairs(record.IK) do control.Weight=math.max(0,control.Weight-weight) end
end
function Pose.destroy(record:any)
 for _,connection in ipairs(record.Connections) do connection:Disconnect() end
 for motor,base in pairs(record.Motors) do if motor.Parent then motor.C0=base.RestoreC0;motor.Transform=base.Transform end end
 for _,control in ipairs(record.IK) do control:Destroy() end
 for _,target in ipairs(record.Attachments) do target:Destroy() end
 if record.Animate and record.Animate.Parent then record.Animate.Disabled=record.Disabled end
end
return Pose
