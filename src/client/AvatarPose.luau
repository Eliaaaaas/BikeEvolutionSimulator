--!strict
-- Procedural R15 hand/foot IK; R6 uses joint posing. No uploaded animation IDs.
local Pose={}
function Pose.new(character:Model,bike:Model?):any
 local hum=character:FindFirstChildOfClass("Humanoid");if not hum then return nil end
 local record:any={Character=character,Motors={},IK={},Attachments={},Tracks={}}
 local animator=hum:FindFirstChildOfClass("Animator")
 if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end end
 local animate=character:FindFirstChild("Animate")
 if animate and animate:IsA("LocalScript") then record.Animate=animate;record.Disabled=animate.Disabled;animate.Disabled=true end
 for _,motor in ipairs(character:GetDescendants()) do
  if motor:IsA("Motor6D") then record.Motors[motor]={C0=motor:GetAttribute("RiderBaseC0") or motor.C0,RestoreC0=motor.C0,Transform=motor.Transform} end
 end
 if bike and hum.RigType==Enum.HumanoidRigType.R15 then
  local modelScale=bike:GetScale()
  local steering=bike:FindFirstChild("Steering") :: Model
  local crank=bike:FindFirstChild("Crank") :: Model
  local function ik(upper:string,lower:string,parent:BasePart,position:Vector3)
   local a=character:FindFirstChild(upper);local b=character:FindFirstChild(lower)
   if not a or not b or not a:IsA("BasePart") or not b:IsA("BasePart") then return end
   local target=Instance.new("Attachment");target.Name="LocalRiderTarget";target.Position=position*modelScale;target.Parent=parent;table.insert(record.Attachments,target)
   local control=Instance.new("IKControl");control.Name="ProceduralBikeIK";control.Type=Enum.IKControlType.Position
   control.ChainRoot=a;control.EndEffector=b;control.Target=target;control.Weight=1;control.SmoothTime=0.06;control.Parent=hum;table.insert(record.IK,control)
  end
  local steer=steering:FindFirstChild("Pivot") :: BasePart;local pedal=if crank then crank:FindFirstChild("Pivot") :: BasePart else bike:FindFirstChild("Root") :: BasePart
  for _,side in ipairs({"Left","Right"}) do
   local x=if side=="Left" then -1 else 1
   ik(side.."UpperArm",side.."Hand",steer,Vector3.new(x*1.13,0.7,-0.2))
   ik(side.."UpperLeg",side.."Foot",pedal,if crank then Vector3.new(x*0.65,x*0.7,0) else Vector3.new(x*0.8,1.7,0))
  end
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
 for motor,base in pairs(record.Motors) do if motor.Parent then motor.C0=base.RestoreC0;motor.Transform=base.Transform end end
 for _,control in ipairs(record.IK) do control:Destroy() end
 for _,target in ipairs(record.Attachments) do target:Destroy() end
 if record.Animate and record.Animate.Parent then record.Animate.Disabled=record.Disabled end
end
return Pose
