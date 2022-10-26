local MODULE_NAME, MODULE_PART = "SkuCore", "EquipmentManager"
local L = Sku.L
local _G = _G

local function GetEquipmentSetInfo(id)
    local name, iconFileID, setID, isEquipped, numItems, numEquipped, numInInventory, numLost, numIgnored = C_EquipmentSet.GetEquipmentSetInfo(id)
    if name == nil then
        return nil
    end
    return {
name = name,
        iconFileID = iconFileID,
        setID = setID,
        isEquipped = isEquipped,
        numItems = numItems,
        numEquipped = numEquipped,
        numInInventory = numInInventory,
        numLost = numLost,
        numIgnored = numIgnored
    }
end

local function BuildItemsList(aParent, id)
    local items = C_EquipmentSet.GetItemIDs(id)
    for i=1,19 do
        local itemEntry = nil
        if items[i] then
            local name = C_Item.GetItemNameByID(items[i])
            if name == nil then
name = "it broke"
            end
            itemEntry = SkuOptions:InjectMenuItems(aParent, {i .. ": " .. name}, SkuGenericMenuItem)
            itemEntry.dynamic = true
            itemEntry.filterable = true
        else
            itemEntry = SkuOptions:InjectMenuItems(aParent, {i .. ": empty"}, SkuGenericMenuItem)
itemEntry.dynamic = true
itemEntry.filterable = true
    end
    itemEntry.BuildChildren = function(aParent)

    end
end
end

local function BuildSetMenu(aParent, id)
    local itemsEntry = SkuOptions:InjectMenuItems(aParent, {"items"}, SkuGenericMenuItem)
    itemsEntry.dynamic = true
    itemsEntry.filterable = true
itemsEntry.BuildChildren = function(aParent)
BuildItemsList(aParent, id)
end
    local equipEntry = SkuOptions:InjectMenuItems(aParent, {"equip set"}, SkuGenericMenuItem)
    equipEntry.dynamic = true
    equipEntry.filterable = true
    equipEntry.OnAction = function(aParent)
        info = GetEquipmentSetInfo(id)
        wasEquipped = C_EquipmentSet.UseEquipmentSet(id)
        if wasEquipped == true then
            SkuOptions.Voice:OutputStringBTtts("set equipped", false, true, 0.2)
        end
        C_Timer.After(0.1, function()
            SkuOptions.currentMenuPosition.parent:OnUpdate()
        end)
    end

    saveEntry = SkuOptions:InjectMenuItems(aParent, {"Save current equipment to set"}, SkuGenericMenuItem)
    saveEntry.dynamic = true
    saveEntry.filterable = true
    saveEntry.OnAction = function(aParent)
        C_EquipmentSet.SaveEquipmentSet(id)
        SkuOptions.Voice:OutputStringBTtts("set saved", false, true, 0.2)
        C_Timer.After(0.1, function()
        end)
    end
end

local function BuildSetList(aParentEntry)
    local tNumSets = C_EquipmentSet.GetNumEquipmentSets() 

    if tNumSets <= 0 then
        local tNewMenuEntry = SkuOptions:InjectMenuItems(aParentEntry, {L["Empty"]}, SkuGenericMenuItem)
return
    end
        for x = 0, tNumSets - 1 do
            local info = GetEquipmentSetInfo(x)
            setName = info.name
            if info.isEquipped then
                setName = setName .. " (currently equipped)"
            end
            local tNewMenuEntry = SkuOptions:InjectMenuItems(aParentEntry, {setName}, SkuGenericMenuItem)
            tNewMenuEntry.dynamic = true
            tNewMenuEntry.filterable = true
            tNewMenuEntry.BuildChildren = function(aParentEntry)
                BuildSetMenu(aParentEntry, x)
            end
        end
end

function SkuCore.SetEquipmentSetTooltip(id)

end

function SkuCore.EquipmentManagerMenuBuilder(aParentEntry)
    local setsEntry = SkuOptions:InjectMenuItems(aParentEntry, {"sets"}, SkuGenericMenuItem)
setsEntry.dynamic = true
setsEntry.filterable = true
setsEntry.BuildChildren = BuildSetList

local createEntry = SkuOptions:InjectMenuItems(aParentEntry, {"Create"}, SkuGenericMenuItem)
createEntry.dynamic = true
createEntry.filterable = true
end
