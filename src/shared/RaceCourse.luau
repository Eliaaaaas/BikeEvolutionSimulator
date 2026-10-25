--!strict
local points=require(script.Parent.CourseData)
local Course={Points=points,Length=0}
local lengths={0}
for i=2,#points do
 local a,b=points[i-1],points[i]
 Course.Length+=math.sqrt((b.X-a.X)^2+(b.Z-a.Z)^2)
 lengths[i]=Course.Length
end
function Course.sample(distance: number): any
 distance=math.clamp(distance,0,Course.Length)
 local low,high=2,#points
 while low<high do local middle=math.floor((low+high)/2);if lengths[middle]<distance then low=middle+1 else high=middle end end
 local a,b=points[low-1],points[low]
 local segment=lengths[low]-lengths[low-1];local t=(distance-lengths[low-1])/segment
 return {X=a.X+(b.X-a.X)*t,Y=a.Y,Z=a.Z+(b.Z-a.Z)*t,DX=(b.X-a.X)/segment,DZ=(b.Z-a.Z)/segment}
end
return table.freeze(Course)
