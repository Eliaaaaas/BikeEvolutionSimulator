--!strict
-- Author entries by stable ID here once design decisions exist. false means unresolved.
local Metadata = {}
export type Entry = { Name: string?, Rarity: string?, Multiplier: number?,
 Design: { AssetId: string?, IconId: string?, Description: string? }? }
Metadata.Vehicles = {} :: {[number]: Entry}
Metadata.Eggs = {} :: {[number]: Entry}
Metadata.Pets = {} :: {[number]: Entry}
function Metadata.resolve(entry: Entry?): any
 local source: Entry = entry or {}
 assert(source.Multiplier == nil or (source.Multiplier == source.Multiplier and source.Multiplier >= 0 and source.Multiplier <= 1e300), "Invalid content multiplier")
 local design: { AssetId: string?, IconId: string?, Description: string? } = source.Design or {}
 return {
  Name = source.Name or false, Rarity = source.Rarity or false, Multiplier = source.Multiplier or false,
  Design = table.freeze({ AssetId = design.AssetId or false, IconId = design.IconId or false, Description = design.Description or false }),
  ContentStatus = if source.Name and source.Rarity and source.Multiplier and design.AssetId and design.IconId and design.Description then "Configured" else "Pending",
 }
end
for _, entries in ipairs({ Metadata.Vehicles, Metadata.Eggs, Metadata.Pets }) do table.freeze(entries) end
return table.freeze(Metadata)
