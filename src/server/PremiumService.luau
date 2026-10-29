--!strict
local Players=game:GetService("Players")
local Market=game:GetService("MarketplaceService")
local Http=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared:WaitForChild("PremiumConfig"))
local Rules=require(Shared:WaitForChild("PremiumRules"))
local Service={}
function Service.new(data:any):any
 assert(Rules.registryValid(Config),"Invalid/duplicate Roblox product or pass IDs in PremiumConfig")
 local owned:{[Player]:{[string]:boolean}}={}
 local checked:{[Player]:number}={}
 local api:any={}
 function api.entitled(player:Player,kind:string):boolean return owned[player]~=nil and owned[player][kind]==true end
 function api.bonus(player:Player,profile:any,kind:string):number
  return Rules.bonus(profile,kind,owned[player] and owned[player][kind])
 end
 function api.receipt(receipt:any):any
  if type(receipt)~="table" or type(receipt.PlayerId)~="number" or type(receipt.PurchaseId)~="string" then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local player=Players:GetPlayerByUserId(receipt.PlayerId)
  local product=Rules.product(receipt.ProductId)
  if not player or not product or data.status(player)=="StudioPreviewReady" then return Enum.ProductPurchaseDecision.NotProcessedYet end
  local saved=data.receipt(player,function(profile:any):boolean
   return Rules.grant(profile,receipt.PurchaseId,receipt.ProductId,product,Http:GenerateGUID(false))
  end)
  return if saved then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
 end
 function api.prompt(player:Player,key:string): (boolean,string?)
  local pass=Config.Passes[key];local product=Config.Products[key]
  local def=pass or product
  if not def or def.Id<=0 or def.Unavailable or not data.snapshot(player) or data.status(player)=="StudioPreviewReady" then return false,"ProductUnavailable" end
  local profile=data.read(player)
  if not profile then return false,"NotReady" end
  if product then
   local receipts=0;for _ in pairs(profile.Receipts) do receipts+=1 end
   if receipts>=Config.ReceiptLimit then return false,"ProductUnavailable" end
   if product.Cash and (profile.Cash+product.Cash)-profile.Cash~=product.Cash then return false,"ProductUnavailable" end
   if product.ExclusiveId then local count=0;for _ in pairs(profile.Pets) do count+=1 end;if count>=500 then return false,"InventoryFull" end end
   if product.Boost and profile.Boosts[product.Boost]+product.Seconds>Config.MaxBoostSeconds then return false,"ProductUnavailable" end
  end
  local ok=pcall(function()
   if pass then Market:PromptGamePassPurchase(player,def.Id) else Market:PromptProductPurchase(player,def.Id) end
  end)
  return ok,if ok then nil else "ServiceUnavailable"
 end
 local function check(player:Player)
  if checked[player] and os.clock()-checked[player]<5 then return end
  checked[player]=os.clock();local flags=owned[player] or {};owned[player]=flags
  for kind,pass in pairs(Config.Passes) do
   if pass.Id>0 and not pass.Unavailable then
    local ok,result=pcall(function() return Market:UserOwnsGamePassAsync(player.UserId,pass.Id) end)
    if player.Parent~=Players then return end
    flags[kind]=ok and result==true
    if not ok then warn("[Premium] Gamepass check failed",player.UserId,kind) end
   end
  end
 end
 function api.start()
  Market.ProcessReceipt=api.receipt
  Players.PlayerAdded:Connect(function(player) task.spawn(check,player) end)
  Players.PlayerRemoving:Connect(function(player) owned[player]=nil;checked[player]=nil end)
  Market.PromptGamePassPurchaseFinished:Connect(function(player,id,_purchased)
   -- Do not trust a client callback as ownership. Re-query Marketplace even after the prompt.
   if player.Parent==Players then checked[player]=nil;task.spawn(check,player) end
  end)
  for _,player in ipairs(Players:GetPlayers()) do task.spawn(check,player) end
  task.spawn(function()
   local last=os.clock()
   while true do
    task.wait(1);local now=os.clock();local elapsed=math.min(2,math.max(0,now-last));last=now
    for _,player in ipairs(Players:GetPlayers()) do
     local profile=data.context(player)
     if profile and profile.Boosts and (profile.Boosts.Energy>0 or profile.Boosts.Cash>0) then
      data.change(player,function(candidate:any):boolean
       for _,kind in ipairs({"Energy","Cash"}) do candidate.Boosts[kind]=math.max(0,candidate.Boosts[kind]-elapsed) end
       return true
      end)
     end
     if not checked[player] or now-checked[player]>=60 then task.spawn(check,player) end
    end
   end
  end)
 end
 return api
end
return Service
