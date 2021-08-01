-- kanaFurniture - Release 5 custom - For tes3mp v0.7-alpha
-- REQUIRES: decorateHelp (https://github.com/Nkfree/tes3mp-scripts/blob/master/0.7/decorateHelp.lua)
-- Purchase and place an assortment of furniture
-- Highlights selected object and adds minor tweaks
-- Added option to align selected object with another

-- NOTE FOR SCRIPTS: plName requires the name to be in all LOWERCASE

--[[ INSTALLATION:
1) shouldSave this file as "kanaFurniture.lua" in server/scripts/custom
2) Add [ kanaFurniture = require("custom.kanaFurniture") ] to the top of customScripts.lua

]]

local config = {}
config.whitelist = false --If true, the player must be given permission to place items in the cell that they're in (set using this script's kanaFurniture, or editing the world.json). Note that this only prevents placement, players can still move/remove items they've placed in the cell.
config.sellbackModifier = 0.75 -- The base cost that an item is multiplied by when selling the items back (0.75 is 75%)

--GUI Ids used for the script's GUIs. Shouldn't have to be edited.
config.MainGUI = 31363
config.BuyGUI = 31364
config.InventoryGUI = 31365
config.ViewGUI = 31366
config.InventoryOptionsGUI = 31367
config.ViewOptionsGUI = 31368
config.HighlightColorGUI = 31369
config.InfoMsgGUI = 31370

--Default highlight index, see highlightSpellIds
config.defaultHighlightIndex = 4

------------
--Indexed table of all available furniture. refIds should be in all lowercase
--Best resource I could find online was this: http://tamriel-rebuilt.org/content/resource-guide-models-morrowind (note, items that begin with TR are part of Tamriel Rebuilt, not basic Morrowind, and it certainly doesn't list all the furniture items)

local furnitureData = {
--Containers (Lowest quality container = 1 price per weight)
{name = "Barrel 1", refId = "barrel_01", price = 50},
{name = "Barrel 2", refId = "barrel_02", price = 50},
{name = "Crate 1", refId = "crate_01_empty", price = 200},
{name = "Crate 2", refId = "crate_02_empty", price = 200},
{name = "Basket", refId = "com_basket_01", price = 50},
{name = "Sack (Flat)", refId = "com_sack_01", price = 50},
{name = "Sack (Bag)", refId = "com_sack_02", price = 50},
{name = "Sack (Crumpled)", refId = "com_sack_03", price = 50},
{name = "Sack (Light)", refId = "com_sack_00", price = 50},
{name = "Urn 1", refId = "urn_01", price = 100},
{name = "Urn 2", refId = "urn_02", price = 100},
{name = "Urn 3", refId = "urn_03", price = 100},
{name = "Urn 4", refId = "urn_04", price = 100},
{name = "Urn 5", refId = "urn_05", price = 100},
{name = "Steel Keg", refId = "dwrv_barrel00_empty", price = 150},
{name = "Steel Quarter Keg", refId = "dwrv_barrel10_empty", price = 75},
--Chesty Containers
{name = "Cheap Chest", refId = "com_chest_11_empty", price = 150},
{name = "Cheap Chest (Open)", refId = "com_chest_11_open", price = 150},
{name = "Small Chest (Metal)", refId = "chest_small_01", price = 50}, --*2 price because fancier material
{name = "Small Chest (Wood)", refId = "chest_small_02", price = 25},

--Imperial Furniture Set
{name = "Imperial Closet", refId = "com_closet_01", price = 300},
{name = "Imperial Cupboard", refId = "com_cupboard_01", price = 100},
{name = "Imperial Drawers", refId = "com_drawers_01", price = 300},
{name = "Imperial Hutch", refId = "com_hutch_01", price = 75},
{name = "Imperial Chest (Cheap)", refId = "com_chest_01", price = 150},
{name = "Imperial Chest (Fine)", refId = "com_chest_02", price = 400}, --*2 price because fancier

--Dunmer Furniture Set
{name = "Dunmer Closet (Cheap)", refId = "de_p_closet_02", price = 300},
{name = "Dunmer Closet (Fine)", refId = "de_r_closet_01", price = 600}, --*2 for quality
{name = "Dunmer Desk", refId = "de_p_desk_01", price = 75},
{name = "Dunmer Drawers (Cheap)", refId = "de_drawers_02", price = 300},
{name = "Dunmer Drawers (Fine)", refId = "de_r_drawers_01", price = 600},
{name = "Dunmer Drawer Table (Large)", refId = "de_p_table_02", price = 25},
{name = "Dunmer Drawer Table (Small)", refId = "de_p_table_01", price = 25},
{name = "Dunmer Chest (Cheap)", refId = "de_r_chest_01", price = 200},
{name = "Dunmer Chest (Fine)", refId = "de_p_chest_02", price = 400}, --*2 because fancy

--General Furniture
{name = "Stool (Crude)", refId = "furn_de_ex_stool_02", price = 50},
{name = "Stool (Prayer)", refId = "furn_velothi_prayer_stool_01", price = 50},
{name = "Stool (Bar Stool)", refId = "furn_com_rm_barstool", price = 100},
{name = "Chair (Camp)", refId = "furn_com_pm_chair_02", price = 50},
{name = "Chair (General 1)", refId = "furn_com_rm_chair_03", price = 100},
{name = "Chair (General 2)", refId = "furn_de_p_chair_01", price = 100},
{name = "Chair (General 3)", refId = "furn_de_p_chair_02", price = 100},
{name = "Chair (Fine)", refId = "furn_de_r_chair_03", price = 200},
{name = "Chair (Padded)", refId = "furn_com_r_chair_01", price = 200},
{name = "Chair (Chieftain)", refId = "furn_chieftains_chair", price = 200},
{name = "Bench, Long (Cheap)", refId = "furn_de_p_bench_03", price = 200},
{name = "Bench, Short (Cheap)", refId = "furn_de_p_bench_04", price = 200},
{name = "Bench, Long (Fine)", refId = "furn_de_r_bench_01", price = 400},
{name = "Bench, Short (Fine)", refId = "furn_de_r_bench_02", price = 400},
{name = "Bench (Crude)", refId = "furn_de_p_bench_03", price = 150},
{name = "Common Bench 1", refId = "furn_com_p_bench_01", price = 200},
{name = "Common Bench 2", refId = "furn_com_rm_bench_02", price = 200},

{name = "Table, Big Oval (Fine)", refId = "furn_de_r_table_03", price = 800},
{name = "Table, Big Rectangle (Cheap)", refId = "furn_de_p_table_04", price = 400},
{name = "Table, Big Rectangle (Fine)", refId = "furn_de_r_table_07", price = 800},
{name = "Table, Low Round (Cheap) 1", refId = "furn_de_p_table_01", price = 400},
{name = "Table, Low Round (Cheap) 2", refId = "furn_de_p_table_06", price = 400},
{name = "Table, Low Round (Fine)", refId = "furn_de_r_table_08", price = 800},
{name = "Table, Small Square (Cheap)", refId = "furn_de_p_table_05", price = 400},
{name = "Table, Small Square (Fine)", refId = "furn_de_r_table_09", price = 800},
{name = "Table, Small Round (Cheap)", refId = "furn_de_p_table_02", price = 400},
{name = "Table, Square (Crude)", refId = "furn_de_ex_table_02", price = 200},
{name = "Table, Rectangle (Crude)", refId = "furn_de_ex_table_03", price = 200},

{name = "Table, Colony", refId = "furn_com_table_colony", price = 400},
{name = "Table, Rectangle 1", refId = "furn_com_rm_table_04", price = 400},
{name = "Table, Rectangle 2", refId = "furn_com_r_table_01", price = 800},
{name = "Table, Small Rectangle", refId = "furn_com_rm_table_05", price = 400},
{name = "Table, Round", refId = "furn_com_rm_table_03", price = 400},
{name = "Table, Oval", refId = "furn_de_table10", price = 800},

{name = "Bar Counter, Middle", refId = "furn_com_rm_bar_01", price = 200},
{name = "Bar Counter, End Cap 1", refId = "furn_com_rm_bar_04", price = 200},
{name = "Bar Counter, End Cap 2", refId = "furn_com_rm_bar_02", price = 200},
{name = "Bar Counter, Corner", refId = "furn_com_rm_bar_03", price = 200},

{name = "Bar Counter, Middle (Dunmer)", refId = "furn_de_bar_01", price = 200},
{name = "Bar Counter, End Cap 1 (Dunmer)", refId = "furn_de_bar_04", price = 200},
{name = "Bar Counter, End Cap 2 (Dunmer)", refId = "furn_de_bar_02", price = 200},
{name = "Bar Counter, Corner (Dunmer)", refId = "furn_de_bar_03", price = 200},

{name = "Bookshelf, Backed (Cheap)", refId = "furn_com_rm_bookshelf_02", price = 500},
{name = "Bookshelf, Backed (Fine)", refId = "furn_com_r_bookshelf_01", price = 1000},
{name = "Bookshelf, Standing (Cheap)", refId = "furn_de_p_bookshelf_01", price = 350},
{name = "Bookshelf, Standing (Fine)", refId = "furn_de_r_bookshelf_02", price = 700},

--Beds
{name = "Bedroll", refId = "active_de_bedroll", price = 100},
{name = "Standing Hammock", refId = "active_de_r_bed_02", price = 150},
{name = "Bunk Bed 1", refId = "active_com_bunk_01", price = 800},
{name = "Bunk Bed 2", refId = "active_com_bunk_02", price = 800},
{name = "Bunk Bed 3", refId = "active_de_p_bed_03", price = 800},
{name = "Bunk Bed 4", refId = "active_de_p_bed_09", price = 800},
{name = "Bed, Single 1 (Imperial, Dark, Red Patterned)", refId = "active_com_bed_02", price = 400},
{name = "Bed, Single 2 (Imperial, Light, Pale Red)", refId = "active_com_bed_03", price = 400},
{name = "Bed, Single 3 (Imperial, Dark, Pale Green)", refId = "active_com_bed_04", price = 400},
{name = "Bed, Single 4 (Imperial, Light, Grey)", refId = "active_com_bed_05", price = 400},
{name = "Bed, Single 5 (Dunmer, Grey-Brown)", refId = "active_de_p_bed_04", price = 400},
{name = "Bed, Single 6 (Dunmer, Pale Red)", refId = "active_de_p_bed_10", price = 400},
{name = "Bed, Single 7 (Dunmer, Blue Patterned)", refId = "active_de_p_bed_11", price = 400},
{name = "Bed, Single 8 (Dunmer, Blue Patterned)", refId = "active_de_p_bed_12", price = 400},
{name = "Bed, Single 9 (Dunmer, Red Patterned)", refId = "active_de_p_bed_13", price = 400},
{name = "Bed, Single 10 (Dunmer, Grey)", refId = "active_de_p_bed_14", price = 400},
{name = "Bed, Single 11 (Headboard, Blue Patterned)", refId = "active_de_pr_bed_07", price = 400},
{name = "Bed, Single 12 (Headboard, Blue Patterned)", refId = "active_de_pr_bed_21", price = 400},
{name = "Bed, Single 13 (Headboard, Red Patterned)", refId = "active_de_pr_bed_22", price = 400},
{name = "Bed, Single 14 (Headboard, Red Patterned)", refId = "active_de_pr_bed_23", price = 400},
{name = "Bed, Single 15 (Headboard, Grey-Brown)", refId = "active_de_pr_bed_24", price = 400},
{name = "Bed, Single 16 (Headboard, Pale Green)", refId = "active_de_pr_bed_24", price = 400},

{name = "Bed, Single Cot 1 (Dunmer, Blue Patterned)", refId = "active_de_r_bed_01", price = 400},
{name = "Bed, Single Cot 2 (Dunmer, Blue Patterned)", refId = "active_de_r_bed_17", price = 400},
{name = "Bed, Single Cot 3 (Dunmer, Red Patterned)", refId = "active_de_r_bed_18", price = 400},
{name = "Bed, Single Cot 4 (Dunmer, Red Patterned)", refId = "active_de_r_bed_19", price = 400},

{name = "Bed, Double 1 (Dunmer, Pale Green)", refId = "active_de_p_bed_05", price = 800},
{name = "Bed, Double 2 (Dunmer, Red Patterned)", refId = "active_de_p_bed_15", price = 800},
{name = "Bed, Double 3 (Dunmer, Red Patterned)", refId = "active_de_p_bed_16", price = 800},
{name = "Bed, Double 4 (Headboard, Pale Green)", refId = "active_de_pr_bed_27", price = 800},
{name = "Bed, Double 5 (Headboard, Red Patterned)", refId = "active_de_pr_bed_26", price = 800},
{name = "Bed, Double 6 (Headboard, Red Patterned)", refId = "active_de_pr_bed_08", price = 800},
{name = "Bed, Double 7 (Cot, Red Patterned)", refId = "active_de_r_bed_20", price = 800},
{name = "Bed, Double 8 (Cot, Red Patterned)", refId = "active_de_r_bed_06", price = 800},
{name = "Bed, Double 9 (Imperial, Four Poster, Blue)", refId = "active_com_bed_06", price = 800},

--Rugs
{name = "Dunmer Rug 1", refId = "furn_de_rug_01", price = 200},
{name = "Dunmer Rug 2", refId = "furn_de_rug_02", price = 200},
{name = "Wolf Rug", refId = "furn_colony_wolfrug01", price = 50},
{name = "Bearskin Rug", refId = "furn_rug_bearskin", price = 100},
{name = "Rug, Big Round 1 (Red)", refId = "furn_de_rug_big_01", price = 200},
{name = "Rug, Big Round 2 (Red)", refId = "furn_de_rug_big_02", price = 200},
{name = "Rug, Big Round 3 (Green)", refId = "furn_de_rug_big_03", price = 200},
{name = "Rug, Big Round 4 (Blue)", refId = "furn_de_rug_big_08", price = 200},
{name = "Rug, Big Rectangle 1 (Red)", refId = "furn_de_rug_big_04", price = 200},
{name = "Rug, Big Rectangle 2 (Red)", refId = "furn_de_rug_big_05", price = 200},
{name = "Rug, Big Rectangle 3 (Green)", refId = "furn_de_rug_big_06", price = 200},
{name = "Rug, Big Rectangle 4 (Green)", refId = "furn_de_rug_big_07", price = 200},
{name = "Rug, Big Rectangle 5 (Blue)", refId = "furn_de_rug_big_09", price = 200},

--Fireplaces
{name = "Firepit", refId = "furn_de_firepit", price = 100},
{name = "Firepit 2", refId = "furn_de_firepit_01", price = 100},
{name = "Fireplace (Simple Oven)", refId = "furn_t_fireplace_01", price = 500},
{name = "Fireplace (Forge)", refId = "furn_de_forge_01", price = 500},
{name = "Fireplace (Nord)", refId = "in_nord_fireplace_01", price = 1500},
{name = "Fireplace", refId = "furn_fireplace10", price = 2000},
{name = "Fireplace (Grand Imperial)", refId = "in_imp_fireplace_grand", price = 5000},

--Lighting
{name = "Yellow Paper Lantern", refId = "light_de_lantern_03", price = 25},
{name = "Blue Paper Lantern", refId = "light_de_lantern_08", price = 25},
{name = "Yellow Candles", refId = "light_com_candle_07", price = 25},
{name = "Blue Candles", refId = "light_com_candle_11", price = 25},
{name = "Blue Candles", refId = "light_com_candle_11", price = 25},
{name = "Wall Sconce (Three Candles)", refId = "light_com_sconce_02_128", price = 25},
{name = "Wall Sconce (Single Candle)", refId = "light_com_sconce_01", price = 25},
{name = "Standing Candleholder (Three Candles)", refId = "light_com_lamp_02_128", price = 50},
{name = "Chandelier, Simple (Four Candles)", refId = "light_com_chandelier_03", price = 50},

--Special Containers
{name = "Skeleton 1", refId = "contain_corpse00", price = 122}, --120 for weight + 2 for the bonemeal :P
{name = "Skeleton 2", refId = "contain_corpse10", price = 122},
{name = "Skeleton 3", refId = "contain_corpse20", price = 122},

--Misc
{name = "Anvil", refId = "furn_anvil00", price = 200},
{name = "Keg On Stand", refId = "furn_com_kegstand", price = 200},
{name = "Cauldron, Standing", refId = "furn_com_cauldron_01", price = 100},
{name = "Ashpit", refId = "in_velothi_ashpit_01", price = 100},
{name = "Shack Awning", refId = "ex_de_shack_awning_03", price = 100},
{name = "Mounted Bear Head (Brown)", refId = "bm_bearhead_brown", price = 200},
{name = "Mounted Wolf Head (White)", refId = "bm_wolfhead_white", price = 200},
{name = "Paper Wallscreen", refId = "furn_de_r_wallscreen_02", price = 100},

{name = "Banner (Imperial, Tapestry 2 - Tree)", refId = "furn_com_tapestry_02", price = 100},
{name = "Banner (Imperial, Tapestry 3)", refId = "furn_com_tapestry_03", price = 100},
{name = "Banner (Imperial, Tapestry 4 - Empire)", refId = "furn_com_tapestry_04", price = 100},
{name = "Banner (Imperial, Tapestry 5)", refId = "furn_com_tapestry_05", price = 100},

{name = "Banner (Dunmer, Tapestry 2)", refId = "furn_de_tapestry_02", price = 100},
{name = "Banner (Dunmer, Tapestry 5)", refId = "furn_de_tapestry_05", price = 100},
{name = "Banner (Dunmer, Tapestry 6)", refId = "furn_de_tapestry_06", price = 100},
{name = "Banner (Dunmer, Tapestry 7)", refId = "furn_de_tapestry_07", price = 100},

{name = "Banner (Temple 1)", refId = "furn_banner_temple_01_indoors", price = 100},
{name = "Banner (Temple 2)", refId = "furn_banner_temple_02_indoors", price = 100},
{name = "Banner (Temple 3)", refId = "furn_banner_temple_03_indoors", price = 100},

{name = "Banner (Akatosh)", refId = "furn_c_t_akatosh_01", price = 100},
{name = "Banner (Arkay)", refId = "furn_c_t_arkay_01", price = 100},
{name = "Banner (Dibella)", refId = "furn_c_t_dibella_01", price = 100},
{name = "Banner (Juilianos)", refId = "furn_c_t_julianos_01", price = 100},
{name = "Banner (Kynareth)", refId = "furn_c_t_kynareth_01", price = 100},
{name = "Banner (Mara)", refId = "furn_c_t_mara_01", price = 100},
{name = "Banner (Stendarr)", refId = "furn_c_t_stendarr_01", price = 100},
{name = "Banner (Zenithar)", refId = "furn_c_t_zenithar_01", price = 100},

{name = "Banner (Apprentice)", refId = "furn_c_t_apprentice_01", price = 100},
{name = "Banner (Golem)", refId = "furn_c_t_golem_01", price = 100},
{name = "Banner (Lady)", refId = "furn_c_t_lady_01", price = 100},
{name = "Banner (Lord)", refId = "furn_c_t_lord_01", price = 100},
{name = "Banner (Lover)", refId = "furn_c_t_lover_01", price = 100},
{name = "Banner (Ritual)", refId = "furn_c_t_ritual_01", price = 100},
{name = "Banner (Shadow)", refId = "furn_c_t_shadow_01", price = 100},
{name = "Banner (Steed)", refId = "furn_c_t_steed_01", price = 100},
{name = "Banner (Thief)", refId = "furn_c_t_theif_01", price = 100},
{name = "Banner (Tower)", refId = "furn_c_t_tower_01", price = 100},
{name = "Banner (Warrior)", refId = "furn_c_t_warrior_01", price = 100},
{name = "Banner (Wizard)", refId = "furn_c_t_wizard_01", price = 100},

--[[
--Dwarven Furniture Set
{name = "Heavy Dwemer Chest", refId = "dwrv_chest00", price = 200}, --NOTE: Contains 2 random dwarven items
{name = "Heavy Dwemer Chest", refId = "dwrv_chest00", price = 200},
{name = "Dwemer Cabinet", refId = "dwrv_cabinet10", price = 200},
{name = "Dwemer Desk", refId = "dwrv_desk00", price = 50},
{name = "Dwemer Drawers", refId = "dwrv_desk00", price = 300}, --NOTE: Contains paper + one dwarven coin
{name = "Dwemer Drawer Table", refId = "dwrv_table00", price = 50}, --NOTE: Contains dwarven coin
{name = "Dwemer Chair", refId = "furn_dwrv_chair00", price = 000},
{name = "Dwemer Shelf", refId = "furn_dwrv_bookshelf00", price = 000},

--in_dwe_slate00 to in_dwe_slate11
--furn_com_p_table_01
--furn_com_planter
]]
}
-- {name = "name", refId = "ref_id", price = 50},

------------
decorateHelp = require("custom.decorateHelp")
tableHelper = require("tableHelper")

local kanaFurniture = {}
------------
local playerBuyOptions = {} --Used to store the lists of items each player is offered so we know what they're trying to buy
local playerInventoryOptions = {} --
local playerInventoryChoice = {}
local playerViewOptions = {} -- [plName = [index = [uniqueIndex = x, refId = y] ]
--Highlight colors to choose from
local highlightColorChoices = {
	"White",
	"Ice Blue",
	"Yellow",
	"Orange",
	"Purple",
	"Violet"
}
--Sounds to be cancelled
local highlightSoundIds = {
	alteration = '"alteration cast"', 
	conjuration = '"conjuration cast"', 
	restoration = '"restoration cast"'
}
--Spells to be casted
local highlightSpellIds = {
	{id = '"frost shield"', soundId = highlightSoundIds.alteration},
	{id = '"shield of the armiger"', soundId = highlightSoundIds.restoration},
	{id = '"bound shield"', soundId = highlightSoundIds.conjuration},
	{id = '"fire shield"', soundId = highlightSoundIds.alteration},
	{id = "shield", soundId = highlightSoundIds.alteration},
	{id = '"shock shield"', soundId = highlightSoundIds.alteration},
}
local highlightTimers = {}


-- ===========
--  DATA ACCESS
-- ===========

local function getFurnitureInventoryTable()
	return WorldInstance.data.customVariables.kanaFurniture.inventories
end

local function getPermissionsTable()
	return WorldInstance.data.customVariables.kanaFurniture.permissions
end

local function getPlacedTable()
	return WorldInstance.data.customVariables.kanaFurniture.placed
end

local function getPlaced(cellDescription)
	return getPlacedTable()[cellDescription]
end

--[[ local function addPlacedEntry(uniqueIndex, cellDescription, plName, refId, shouldSave)
	local placed = getPlacedTable()

	if not placed[cellDescription] then
		placed[cellDescription] = {}
	end

	placed[cellDescription][uniqueIndex] = {owner = plName, refId = refId}

	if shouldSave then
		WorldInstance:QuicksaveToDrive()
	end
end ]]

local function addPlacedEntry(uniqueIndex, cellDescription, plName, refId)
	local placed = getPlacedTable()

	if not placed[cellDescription] then placed[cellDescription] = {} end
	if not placed[cellDescription][plName] then placed[cellDescription][plName] = {} end

	table.insert(placed[cellDescription][plName], {uniqueIndex = uniqueIndex, refId = refId})
end

local function removePlacedEntry(uniqueIndex, plName, cellDescription)
	local placed = getPlaced(cellDescription)

	for i=1, #placed[plName] do
		if placed[plName][i].uniqueIndex == uniqueIndex then
			placed[plName][i] = nil
			break
		end
	end
end

local function addInventoryFurniture(plName, refId)
	local fInventories = getFurnitureInventoryTable()

	if fInventories[plName] == nil then
		fInventories[plName] = {}
	end

	fInventories[plName][refId] = (fInventories[plName][refId] or 0) + 1
end

local function removeInventoryFurniture(plName, refId)
	local fInventories = getFurnitureInventoryTable()

	if fInventories[plName] == nil then
		fInventories[plName] = {}
	end

	fInventories[plName][refId] = (fInventories[plName][refId] or 0) - 1

	if fInventories[plName][refId] <= 0 then
		fInventories[plName][refId] = nil
	end
end

kanaFurniture.OnServerPostInit = function()
	--Create the script's required data if it doesn't exits
	if WorldInstance.data.customVariables.kanaFurniture == nil then
		WorldInstance.data.customVariables.kanaFurniture = {}
	end

	if WorldInstance.data.customVariables.kanaFurniture.placed == nil then
		WorldInstance.data.customVariables.kanaFurniture.placed = {}
	end

	if WorldInstance.data.customVariables.kanaFurniture.permissions == nil then
		WorldInstance.data.customVariables.kanaFurniture.permissions = {}
	end

	if WorldInstance.data.customVariables.kanaFurniture.inventories == nil then
		WorldInstance.data.customVariables.kanaFurniture.inventories = {}
	end

	if WorldInstance.data.customVariables.kanaFurniture.highlightChoices == nil then
		WorldInstance.data.customVariables.kanaFurniture.highlightChoices = {}
	end

	--Slight Hack for updating pnames to their new values. In release 1, the script stored player names as their login names, in release 2 it stores them as their all lowercase names.
	local placed = getPlacedTable()
	local updatedPlaced = {}
	for cellDescription, _ in pairs(placed) do
		if not updatedPlaced[cellDescription] then updatedPlaced[cellDescription] = {} end
		for name, data in pairs(placed[cellDescription]) do
			--If the name has uniqueIndex pattern it's outdated, so update it
			if name:match("^0%-") then
				if not updatedPlaced[cellDescription][string.lower(data.owner)] then updatedPlaced[cellDescription][string.lower(data.owner)] = {} end
				table.insert(updatedPlaced[cellDescription][string.lower(data.owner)], {uniqueIndex = name, refId = data.refId})
			end
		end
	end

	--Actually update the placed table if there are updated entries available
	if next(updatedPlaced) then
		WorldInstance.data.customVariables.kanaFurniture.placed = updatedPlaced
	end

	local permissions = getPermissionsTable()
	for cellDescription, _ in pairs(permissions) do
		local newNames = {}

		for plName, _ in pairs(permissions[cellDescription]) do
			table.insert(newNames, string.lower(plName))
		end

		permissions[cellDescription] = {}
		for _, newName in pairs(newNames) do
			permissions[cellDescription][newName] = true
		end
	end

	local inventories = getFurnitureInventoryTable()
	local newInventories = {}
	for plName, invData in pairs(inventories) do
		newInventories[string.lower(plName)] = invData
	end

	WorldInstance.data.customVariables.kanaFurniture.inventories = newInventories

	WorldInstance:QuicksaveToDrive()
end

-- ===========
--  OBJECT HIGHLIGHTING
-- ===========

local function createHighlightTimer(pid, cellDescription, uniqueIndex)
	if not highlightTimers[pid][uniqueIndex] and not (tableHelper.getCount(highlightTimers[pid]) > 2) then
		highlightTimers[pid][uniqueIndex] = tes3mp.CreateTimerEx("HighlightObject", 0, "iss", pid, cellDescription, uniqueIndex)
	end

	return highlightTimers[pid][uniqueIndex]
end

local function destroyHighlightTimer(pid, uniqueIndex)
	if highlightTimers[pid][uniqueIndex] then
		tes3mp.StopTimer(highlightTimers[pid][uniqueIndex])
		highlightTimers[pid][uniqueIndex] = nil
	end
end

function HighlightObject(pid, cellDescription, uniqueIndex)
	local choice = WorldInstance.data.customVariables.kanaFurniture.highlightChoices[pid]

	--Resolve different color for selected align object
	if uniqueIndex == decorateHelp.GetSelectedAlignRefIndex(pid) then
		for index, _ in ipairs(highlightColorChoices) do --Find first different color and use that to highlight the align object
			if highlightSpellIds[index] ~= choice then
				choice = highlightSpellIds[index]
				break
			end
		end
	end

	logicHandler.RunConsoleCommandOnObject(pid, 'ExplodeSpell ' .. choice.id, cellDescription, uniqueIndex, false)
	logicHandler.RunConsoleCommandOnObject(pid, 'StopSound ' .. choice.soundId, cellDescription, uniqueIndex, false)

	tes3mp.RestartTimer(highlightTimers[pid][uniqueIndex], 500)
end

local function onMainHighlightColor(pid)
	local message = "Proceed to choose your desired highlight color."
	local buttons = ""

	for _, text in ipairs(highlightColorChoices) do
		buttons = buttons .. text .. ";"
	end

	buttons = buttons .. "Close"

	tes3mp.CustomMessageBox(pid, config.HighlightColorGUI, message, buttons)
end

local function onHighlightOptionSelect(pid, loc)
	WorldInstance.data.customVariables.kanaFurniture.highlightChoices[pid] = highlightSpellIds[loc]
	WorldInstance:QuicksaveToDrive()
end

function kanaFurniture.OnStartHighlight(pid, cellDescription, uniqueIndex)
	local timer = createHighlightTimer(pid, cellDescription, uniqueIndex)

	if timer then
		tes3mp.StartTimer(timer)
	else
		tes3mp.SendMessage(pid, "Highlight timer could not be created. Contact server administrator.")
	end
end

function kanaFurniture.OnStopHighlight(pid, uniqueIndex)
	destroyHighlightTimer(pid, uniqueIndex)
end

function kanaFurniture.OnPlayerAuthentifiedHandler(pid)
	local shouldSave = false
	if highlightTimers[pid] == nil then highlightTimers[pid] = {} end

	if WorldInstance.data.customVariables.kanaFurniture.highlightChoices[pid] == nil then
		WorldInstance.data.customVariables.kanaFurniture.highlightChoices[pid] = highlightSpellIds[config.defaultHighlightIndex]
		shouldSave = true
	end

	if shouldSave then
		WorldInstance:QuicksaveToDrive()
	end
end

function kanaFurniture.OnPlayerDisconnectValidator(pid)
	for uniqueIndex, _ in pairs(highlightTimers[pid]) do
		kanaFurniture.OnStopHighlight(pid, uniqueIndex)
	end
end

-------------------------

local function getSellValue(baseValue)
	return math.max(0, math.floor(baseValue * config.sellbackModifier))
end

local function getName(pid)
	--Release 2 change: Now uses all lowercase name for storage
	return string.lower(Players[pid].accountName)
end

kanaFurniture.getObject = function(uniqueIndex, cellDescription)
	if LoadedCells[cellDescription]:ContainsObject(uniqueIndex)  then
		return LoadedCells[cellDescription].data.objectData[uniqueIndex]
	end

	return nil
end

--Returns the amount of gold in a player's inventory
local function getPlayerGold(pid)
	local goldLoc = inventoryHelper.getItemIndex(Players[pid].data.inventory, "gold_001", -1)

	if goldLoc then
		return Players[pid].data.inventory[goldLoc].count
	end

	return 0
end

local function addGold(pid, amount)
	local gold = {refId = "gold_001", count = amount, charge = -1, enchantmentCharge = -1, soul = ""}

	inventoryHelper.addItem(Players[pid].data.inventory, gold.refId, gold.count, gold.charge, gold.enchantmentCharge, gold.soul)
	Players[pid]:LoadItemChanges({gold}, enumerations.inventory.ADD)

	Players[pid]:QuicksaveToDrive()
end

local function removeGold(pid, amount)
	local gold = {refId = "gold_001", count = amount, charge = -1, enchantmentCharge = -1, soul = ""}

	inventoryHelper.removeClosestItem(Players[pid].data.inventory, gold.refId, gold.count, gold.charge, gold.enchantmentCharge, gold.soul)
	Players[pid]:LoadItemChanges({gold}, enumerations.inventory.REMOVE)

	Players[pid]:QuicksaveToDrive()
end

local function getFurnitureData(refId)
	local location = tableHelper.getIndexByNestedKeyValue(furnitureData, "refId", refId)

	if location then
		return furnitureData[location], location
	end

	return nil
end

local function hasPlacePermission(plName, cellDescription)
	local perms = getPermissionsTable()

	if not config.whitelist then
		return true
	end

	if perms[cellDescription] and (perms[cellDescription]["all"] or perms[cellDescription][plName]) then
		return true
	end

	return false
end

local function getPlayerFurnitureInventory(pid)
	local inventories = getFurnitureInventoryTable()
	local plName = getName(pid)

	if not inventories[plName] then
		inventories[plName] = {}
		WorldInstance:QuicksaveToDrive()
	end

	return inventories[plName]
end

local function getSortedPlayerFurnitureInventory(pid)
	local inventory = getPlayerFurnitureInventory(pid)
	local sorted = {}

	for refId, amount in pairs(inventory) do
		local name = getFurnitureData(refId).name
		table.insert(sorted, {name = name, count = amount, refId = refId})
	end


	table.sort(sorted, function(a, b)
		return a.name < b.name
	end)

	return sorted
end

local function placeFurniture(refId, loc, cellDescription)
	local location = {
		posX = loc.x, posY = loc.y, posZ = loc.z,
		rotX = 0, rotY = 0, rotZ = 0
	}

	if dimensions[refId] then
		location.posZ = location.posZ + ( dimensions[refId].z / 2 - 1 )
	end

	local uniqueIndex = logicHandler.CreateObjectAtLocation(cellDescription, location, refId, "place")

	return uniqueIndex
end

local function deleteFurnitureObject(uniqueIndex, cellDescription)
	--If for some reason the cellDescription isn't loaded, load it. Causes a bit of spam in the server log, but that can't really be helped.
	local useTempLoad = false

	if LoadedCells[cellDescription] == nil then
		logicHandler.LoadCell(cellDescription)
		useTempLoad = true
	end

	if LoadedCells[cellDescription]:ContainsObject(uniqueIndex) and not tableHelper.containsValue(LoadedCells[cellDescription].data.packets.delete, uniqueIndex) then --Shouldn't ever have a delete packet, but it's worth checking anyway
		--Delete the object for all the players currently online
		logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)

		LoadedCells[cellDescription]:DeleteObjectData(uniqueIndex)
		LoadedCells[cellDescription]:QuicksaveToDrive()
		--Removing the object from the placed list will be done elsewhere
	end

	if useTempLoad then
		logicHandler.UnloadCell(cellDescription)
	end
end

local function getAvailableFurnitureStock(pid)
	--In the future this can be used to customise what items are available for a particular player, like making certain items only available for things like their race, class, level, their factions, or the quests they've completed. For now, however, everything in furnitureData is available :P

	local options = {}

	for i = 1, #furnitureData do
		table.insert(options, furnitureData[i])
	end

	return options
end

--If the player has placed items in the cell return a sorted array containing all the refIds of furniture that they have placed.
local function getSortedPlayerPlacedInCell(plName, cellDescription)
	local cellPlaced = getPlaced(cellDescription)
	local list = {}

	--Check whether there has been any furniture placed by player
	if cellPlaced and cellPlaced[plName] then

		--Sort only if there are multiple items
		if #cellPlaced[plName] > 1 then
			table.sort(cellPlaced[plName], function(a, b)
				local aFurnData = getFurnitureData(a.refId)
				local bFurnData = getFurnitureData(b.refId)
				return aFurnData.name < bFurnData.name
			end)
		end

		for _, data in ipairs(cellPlaced[plName]) do
			table.insert(list, data.uniqueIndex)
		end

		if #list > 0 then
			return list
		end
	end

	return nil
end

-- UNUSED FUNCTIONS --
--NOTE: Both AddPermission and RemovePermission use plName, rather than pid
kanaFurniture.AddPermission = function(plName, cellDescription)
	local perms = getPermissionsTable()

	if not perms[cellDescription] then
		perms[cellDescription] = {}
	end

	perms[cellDescription][plName] = true

	WorldInstance:QuicksaveToDrive()
end

kanaFurniture.RemovePermission = function(plName, cellDescription)
	local perms = getPermissionsTable()

	if not perms[cellDescription] then
		return
	end

	perms[cellDescription][plName] = false

	WorldInstance:QuicksaveToDrive()
end

kanaFurniture.RemoveAllPermissions = function(cellDescription)
	local perms = getPermissionsTable()

	perms[cellDescription] = false

	WorldInstance:QuicksaveToDrive()
end

kanaFurniture.RemoveAllPlayerFurnitureInCell = function(plName, cellDescription, returnToOwner)
	local placed = getPlaced(cellDescription)

	if placed and placed[plName] then
		for _, data in pairs(placed[plName]) do
			if returnToOwner then
				addInventoryFurniture(plName, data.refId)
			end
			deleteFurnitureObject(data.uniqueIndex, cellDescription)
			removePlacedEntry(data.uniqueIndex, plName, cellDescription)
		end
	end
end

kanaFurniture.RemoveAllFurnitureInCell = function(cellDescription, returnToOwner)
	local placed = getPlaced(cellDescription)

	if placed then
		for plName, _ in pairs(placed) do
			kanaFurniture.RemoveAllPlayerFurnitureInCell(plName, cellDescription, returnToOwner)
		end
	end

	WorldInstance:QuicksaveToDrive()
end

--Change the ownership of the specified furniture object (via uniqueIndex) to another character's (playerToName). If playerCurrentName is false, the owner will be changed to the new one regardless of who owned it first.
kanaFurniture.TransferOwnership = function(uniqueIndex, cellDescription, playerCurrentName, playerToName, shouldSave)
	local placed = getPlacedTable()

	if placed[cellDescription] and placed[cellDescription][uniqueIndex] and (placed[cellDescription][uniqueIndex].owner == playerCurrentName or not playerCurrentName) then
		placed[cellDescription][uniqueIndex].owner = playerToName
	end

	if shouldSave then
		WorldInstance:QuicksaveToDrive()
	end

	--Unset the current player's selected item, just in case they had that furniture as their selected item
	if playerCurrentName and logicHandler.IsPlayerNameLoggedIn(playerCurrentName) then
		decorateHelp.SetSelectedObject(logicHandler.GetPlayerByName(playerCurrentName).pid, "")
	end
end

--Same as TransferOwnership, but for all items in a given cell
kanaFurniture.TransferAllOwnership = function(cellDescription, playerCurrentName, playerToName, shouldSave)
	local placed = getPlacedTable()

	if not placed[cellDescription] then
		return false
	end

	for uniqueIndex, _ in pairs(placed[cellDescription]) do
		if not playerCurrentName or placed[cellDescription][uniqueIndex].owner == playerCurrentName then
			placed[cellDescription][uniqueIndex].owner = playerToName
		end
	end

	if shouldSave then
		WorldInstance:QuicksaveToDrive()
	end

	--Unset the current player's selected item, just in case they had any of the furniture as their selected item
	if playerCurrentName and logicHandler.IsPlayerNameLoggedIn(playerCurrentName) then
		decorateHelp.SetSelectedObject(logicHandler.GetPlayerByName(playerCurrentName).pid, "")
	end
end

kanaFurniture.GetSellBackPrice = function(value)
	return getSellValue(value)
end

kanaFurniture.GetFurnitureDataByRefId = function(refId)
	return getFurnitureData(refId)
end

kanaFurniture.GetPlacedInCell = function(cellDescription)
	return getPlaced(cellDescription)
end


-- ====
--  GUI
-- ====

-- VIEW (OPTIONS)
kanaFurniture.showViewOptionsGUI = function(pid)
	local message = ""
	local cellDescription = tes3mp.GetCell(pid)
	local uniqueIndex = decorateHelp.GetSelectedRefIndex(pid)
	local selected = kanaFurniture.getObject(uniqueIndex, cellDescription)
	local fdata = getFurnitureData(selected.refId)

	if not fdata then
		return tes3mp.SendMessage(pid, "Furniture data for the selected object could not be retrieved.\n", false)
	end

	message = message .. "Item Name: " .. fdata.name .. " (uniqueIndex: " .. uniqueIndex .. "). Price: " .. fdata.price .. " (Sell price: " .. getSellValue(fdata.price) .. ")"

	tes3mp.CustomMessageBox(pid, config.ViewOptionsGUI, message, "Decorate helper;Put Away;Sell;Back;Close")
end

local function onViewOptionDecorate(pid)
	local uniqueIndex = decorateHelp.GetSelectedRefIndex(pid)
	local cellDescription = tes3mp.GetCell(pid)

	if kanaFurniture.getObject(uniqueIndex, cellDescription) then
		decorateHelp.OnCommand(pid)
	else
		tes3mp.MessageBox(pid, config.InfoMsgGUI, "The object seems to have been removed.")
	end
end

local function onViewOptionPutAway(pid)
	local plName = getName(pid)
	local cellDescription = tes3mp.GetCell(pid)
	local uniqueIndex = decorateHelp.GetSelectedRefIndex(pid)
	local selected = kanaFurniture.getObject(uniqueIndex, cellDescription)

	if kanaFurniture.getObject(uniqueIndex, cellDescription) then
		deleteFurnitureObject(uniqueIndex, cellDescription)
		removePlacedEntry(uniqueIndex, plName, cellDescription)
		addInventoryFurniture(plName, selected.refId)

		tes3mp.MessageBox(pid, config.InfoMsgGUI, getFurnitureData(selected.refId).name .. " has been added to your furniture inventory.")
	else
		tes3mp.MessageBox(pid, config.InfoMsgGUI, "The object seems to have been removed.")
	end
end

local function onViewOptionSell(pid)
	local cellDescription = tes3mp.GetCell(pid)
	local uniqueIndex = decorateHelp.GetSelectedRefIndex(pid)
	local selected = kanaFurniture.getObject(uniqueIndex, cellDescription)

	if kanaFurniture.getObject(uniqueIndex, cellDescription) then
		local saleGold = getSellValue(getFurnitureData(selected.refId).price)
		local plName = getName(pid)

		addGold(pid, saleGold)

		deleteFurnitureObject(uniqueIndex, cellDescription)
		removePlacedEntry(uniqueIndex, plName, cellDescription)

		tes3mp.MessageBox(pid, config.InfoMsgGUI, saleGold .. " Gold has been added to your inventory and the furniture has been removed from the cell.")
	else
		tes3mp.MessageBox(pid, config.InfoMsgGUI, "The object seems to have been removed.")
	end
end

-- VIEW (MAIN)
kanaFurniture.showViewGUI = function(pid)
	local plName = getName(pid)
	local cellDescription = tes3mp.GetCell(pid)
	local options = getSortedPlayerPlacedInCell(plName, cellDescription)
	local list = "* CLOSE *\n"
	local newOptions = {}

	if options then
		for i = 1, #options do
			--Make sure the object still exists, and get its data
			local object = kanaFurniture.getObject(options[i], cellDescription)

			if object then
				local furnData = getFurnitureData(object.refId)

				list = list .. furnData.name .. " (at " .. math.floor(object.location.posX + 0.5) .. ", "  ..  math.floor(object.location.posY + 0.5) .. ", " .. math.floor(object.location.posZ + 0.5) .. ")"
				if i ~= #options then
					list = list .. "\n"
				end

				table.insert(newOptions, {uniqueIndex = options[i], refId = object.refId})
			end
		end
	end

	playerViewOptions[plName] = newOptions
	tes3mp.ListBox(pid, config.ViewGUI, "Select a piece of furniture you've placed in this cell. Note: The contents of containers will be lost if removed.", list)
end

local function onViewChoice(pid, loc)
	--Catch loc being nil when hitting "Close" in empty view gui
	if not loc then
		return
	end

	local cellDescription = tes3mp.GetCell(pid)
	local choice = playerViewOptions[getName(pid)][loc]

	decorateHelp.SetSelectedObject(pid, choice.uniqueIndex)
	decorateHelp.ResetFixedStats(pid)

	kanaFurniture.OnStartHighlight(pid, cellDescription, decorateHelp.GetSelectedRefIndex(pid))
	kanaFurniture.showViewOptionsGUI(pid)
end

local function onViewDoneRedirect(pid)
	local placed = getSortedPlayerPlacedInCell(getName(pid), tes3mp.GetCell(pid)) or {}
	local placedSize = #placed

	if placedSize > 0 then
		return kanaFurniture.showViewGUI(pid)
	end

	return kanaFurniture.showMainGUI(pid)
end

-- INVENTORY (OPTIONS)
kanaFurniture.showInventoryOptionsGUI = function(pid, loc)
	local message = ""
	local choice = playerInventoryOptions[getName(pid)][loc]
	local fdata = getFurnitureData(choice.refId)

	message = message .. "Item Name: " .. choice.name .. ". Price: " .. fdata.price .. " (Sell price: " .. getSellValue(fdata.price) .. ")"

	playerInventoryChoice[getName(pid)] = choice
	tes3mp.CustomMessageBox(pid, config.InventoryOptionsGUI, message, "Place;Sell;Close")
end

local function onInventoryOptionPlace(pid)
	local plName = getName(pid)
	local cellDescription = tes3mp.GetCell(pid)
	local choice = playerInventoryChoice[plName]

	--First check the player is allowed to place items where they are currently
	if config.whitelist and not hasPlacePermission(plName, cellDescription) then
		--Player isn't allowed
		tes3mp.MessageBox(pid, config.InfoMsgGUI, "You don't have permission to place furniture here.")
		return false
	end

	--Remove 1 instance of the item from the player's inventory
	removeInventoryFurniture(plName, choice.refId)

	--Place the furniture in the world - take player's position as reference
	local plPos = {x = tes3mp.GetPosX(pid), y = tes3mp.GetPosY(pid), z = tes3mp.GetPosZ(pid)}
	local furnRefIndex = placeFurniture(choice.refId, plPos, cellDescription)

	--Add entry in database of placed furniture
	addPlacedEntry(furnRefIndex, cellDescription, plName, choice.refId)
	--Set the placed item as the player's active object for decorateHelp to use
	decorateHelp.SetSelectedObject(pid, furnRefIndex)

	WorldInstance:QuicksaveToDrive()
end

local function onInventoryOptionSell(pid)
	local plName = getName(pid)
	local choice = playerInventoryChoice[plName]

	local saleGold = getSellValue(getFurnitureData(choice.refId).price)

	--Add gold to inventory
	addGold(pid, saleGold)

	--Remove 1 instance of the item from the player's inventory
	removeInventoryFurniture(plName, choice.refId)

	--Inform the player
	tes3mp.MessageBox(pid, config.InfoMsgGUI, saleGold .. " Gold has been added to your inventory.")
end

-- INVENTORY (MAIN)
kanaFurniture.showInventoryGUI = function(pid)
	local options = getSortedPlayerFurnitureInventory(pid)
	local list = "* CLOSE *\n"

	for i = 1, #options do
		list = list .. options[i].name .. " (" .. options[i].count .. ")"
		if not(i == #options) then
			list = list .. "\n"
		end
	end

	playerInventoryOptions[getName(pid)] = options
	tes3mp.ListBox(pid, config.InventoryGUI, "Select the piece of furniture from your inventory that you wish to do something with", list)
end

local function onInventoryChoice(pid, loc)
	kanaFurniture.showInventoryOptionsGUI(pid, loc)
end

local function onInventoryDoneRedirect(pid)
	local inventorySize = #getSortedPlayerFurnitureInventory(pid)

	if inventorySize > 0 then
		return kanaFurniture.showInventoryGUI(pid)
	end

	return kanaFurniture.showMainGUI(pid)
end

-- BUY (MAIN)
kanaFurniture.showBuyGUI = function(pid)
	local options = getAvailableFurnitureStock(pid)
	local list = "* CLOSE *\n"

	for i = 1, #options do
		list = list .. options[i].name .. " (" .. options[i].price .. " Gold)"
		if not(i == #options) then
			list = list .. "\n"
		end
	end

	playerBuyOptions[getName(pid)] = options
	tes3mp.ListBox(pid, config.BuyGUI, "Select an item you wish to buy", list)
end

local function onBuyChoice(pid, loc)
	local gold = getPlayerGold(pid)
	local plName = getName(pid)
	local choice = playerBuyOptions[plName][loc]

	if gold < choice.price then
		tes3mp.MessageBox(pid, config.InfoMsgGUI, "You can't afford to buy a " .. choice.name .. ".")
		return false
	end

	removeGold(pid, choice.price)
	addInventoryFurniture(plName, choice.refId)

	tes3mp.MessageBox(pid, config.InfoMsgGUI, "A " .. choice.name .. " has been added to your furniture inventory.")
	return kanaFurniture.showBuyGUI(pid)
end

-- MAIN
kanaFurniture.showMainGUI = function(pid)
	local message = "Welcome to the furniture menu. Use 'Buy' to purchase furniture for your furniture inventory, 'Inventory' to view the furniture items you own, 'View' to display a list of all the furniture that you own in the cell you're currently in and 'Highlight color' to pick the desired color of the highlight effect.\n\nNote: The current version of tes3mp doesn't really like when lots of items are added to a cell, so try to restrain yourself from complete home renovations."
	tes3mp.CustomMessageBox(pid, config.MainGUI, message, "Buy;Inventory;View;Highlight color;Exit")
end

local function onMainBuy(pid)
	kanaFurniture.showBuyGUI(pid)
end

local function onMainInventory(pid)
	kanaFurniture.showInventoryGUI(pid)
end

local function onMainView(pid)
	kanaFurniture.showViewGUI(pid)
end

-- GENERAL
kanaFurniture.OnGUIAction = function(pid, idGui, data)

	if idGui == config.MainGUI then -- Main
		if tonumber(data) == 0 then --Buy
			onMainBuy(pid)
			return true
		elseif tonumber(data) == 1 then -- Inventory
			onMainInventory(pid)
			return true
		elseif tonumber(data) == 2 then -- View
			onMainView(pid)
			return true
		elseif tonumber(data) == 3 then -- Highlight color
			onMainHighlightColor(pid)
			return true
		elseif tonumber(data) == 4 then -- Exit
			--Do nothing
			return true
		end
	elseif idGui == config.BuyGUI then -- Buy
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
			--Do nothing
			kanaFurniture.showMainGUI(pid)
			return true
		else
			onBuyChoice(pid, tonumber(data))
			return true
		end
	elseif idGui == config.InventoryGUI then --Inventory main
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
			--Do nothing
			kanaFurniture.showMainGUI(pid)
			return true
		else
			onInventoryChoice(pid, tonumber(data))
			return true
		end
	elseif idGui == config.InventoryOptionsGUI then --Inventory options
		if tonumber(data) == 0 then --Place
			onInventoryOptionPlace(pid)
			kanaFurniture.showViewOptionsGUI(pid)
			return true
		elseif tonumber(data) == 1 then --Sell
			onInventoryOptionSell(pid)
			onInventoryDoneRedirect(pid)
			return true
		else --Close
			--Do nothing
			kanaFurniture.showMainGUI(pid)
			return true
		end
	elseif idGui == config.ViewGUI then --View
		if tonumber(data) == 0 or tonumber(data) == 18446744073709551615 then --Close/Nothing Selected
			--Do nothing
			kanaFurniture.showMainGUI(pid)
			return true
		else
			kanaFurniture.OnStopHighlight(pid, decorateHelp.GetSelectedRefIndex(pid))
			onViewChoice(pid, tonumber(data))
			return true
		end
	elseif idGui == config.ViewOptionsGUI then -- View Options
		if tonumber(data) == 0 then --Select
			onViewOptionDecorate(pid)
			return true
		elseif tonumber(data) == 1 then --Put away
			kanaFurniture.OnStopHighlight(pid, decorateHelp.GetSelectedRefIndex(pid))
			onViewOptionPutAway(pid)
			onViewDoneRedirect(pid)
			return true
		elseif tonumber(data) == 2 then --Sell
			kanaFurniture.OnStopHighlight(pid, decorateHelp.GetSelectedRefIndex(pid))
			onViewOptionSell(pid)
			onViewDoneRedirect(pid)
			return true
		elseif tonumber(data) == 3 then --Back
			kanaFurniture.OnStopHighlight(pid, decorateHelp.GetSelectedRefIndex(pid))
			onMainView(pid)
			return true
		else --Close
			--Do nothing
			kanaFurniture.OnStopHighlight(pid, decorateHelp.GetSelectedRefIndex(pid))
			kanaFurniture.showMainGUI(pid)
			return true
		end
	elseif idGui == config.HighlightColorGUI then
		if tonumber(data) >= 0 and tonumber(data) < 6 then --0: White; 1: Ice Blue; 2: Yellow; 3: Orange; 4: Purple; 5: Violet
			onHighlightOptionSelect(pid, tonumber(data)+1) --Add 1 to match the table indexes
			kanaFurniture.OnCommand(pid)
			return true
		elseif tonumber(data) == 6 then --Close
			kanaFurniture.OnCommand(pid)
			return true
		end
	end
end

kanaFurniture.OnCommand = function(pid)
	kanaFurniture.showMainGUI(pid)
end

kanaFurniture.OnView = function(pid)
	onMainView(pid)
end

kanaFurniture.PlacedInCell = function(plName, cellDescription)
	return getSortedPlayerPlacedInCell(plName, cellDescription)
end

kanaFurniture.FurnitureData = function(uniqueIndex)
	return getFurnitureData(uniqueIndex)
end

customCommandHooks.registerCommand("furniture", kanaFurniture.OnCommand)
customCommandHooks.registerCommand("furn", kanaFurniture.OnCommand)

customEventHooks.registerHandler("OnGUIAction", function(eventStatus, pid, idGui, data)
	if kanaFurniture.OnGUIAction(pid, idGui, data) then
		return
	end
end)

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
	kanaFurniture.OnServerPostInit()
end)

customEventHooks.registerHandler("OnPlayerAuthentified", function(eventStatus, pid)
	kanaFurniture.OnPlayerAuthentifiedHandler(pid)
end)

customEventHooks.registerValidator("OnPlayerDisconnect", function(eventStatus, pid)
	kanaFurniture.OnPlayerDisconnectValidator(pid)
end)

return kanaFurniture
