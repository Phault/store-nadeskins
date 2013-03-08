#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <store>
#include <smjansson>

enum Skin
{
	String:SkinName[STORE_MAX_NAME_LENGTH],
	String:SkinModelPath[PLATFORM_MAX_PATH],
}

new OFFSET_THROWER;

new g_skins[1024][Skin];
new g_skinCount = 0;

new String:g_game[32];

new Handle:g_skinNameIndex = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "[Store] NadeSkins",
	author      = "Phault",
	description = "NadeSkins component for [Store]",
	version     = "1.1-alpha",
	url         = "https://github.com/Phault/store-nadeskins"
};

/**
 * Plugin is loading.
 */
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("store.phrases");

	OFFSET_THROWER  = FindSendPropOffs("CBaseGrenade", "m_hThrower");

	GetGameFolderName(g_game, sizeof(g_game));

	Store_RegisterItemType("nadeskins", OnEquip, LoadItem);
}

/** 
 * Called when a new API library is loaded.
 */
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "store-inventory"))
	{
		Store_RegisterItemType("nadeskins", OnEquip, LoadItem);
	}	
}

/**
 * Map is starting
 */
public OnMapStart()
{
	for (new skin = 0; skin < g_skinCount; skin++)
	{
		if (strcmp(g_skins[skin][SkinModelPath], "") != 0 && (FileExists(g_skins[skin][SkinModelPath]) || FileExists(g_skins[skin][SkinModelPath], true)))
		{
			PrecacheModel(g_skins[skin][SkinModelPath]);
			AddFileToDownloadsTable(g_skins[skin][SkinModelPath]);
		}
	}
}

public Store_OnReloadItems() 
{
	if (g_skinNameIndex != INVALID_HANDLE)
		CloseHandle(g_skinNameIndex);
		
	g_skinNameIndex = CreateTrie();
	g_skinCount = 0;
}

public LoadItem(const String:itemName[], const String:attrs[])
{
	strcopy(g_skins[g_skinCount][SkinName], STORE_MAX_NAME_LENGTH, itemName);
		
	SetTrieValue(g_skinNameIndex, g_skins[g_skinCount][SkinName], g_skinCount);
	
	new Handle:json = json_load(attrs);

	if (json == INVALID_HANDLE)
	{
		LogError("%s Error loading item attributes : '%s'.", STORE_PREFIX, itemName);
		return;
	}

	json_object_get_string(json, "model", g_skins[g_skinCount][SkinModelPath], PLATFORM_MAX_PATH);

	CloseHandle(json);

	if (strcmp(g_skins[g_skinCount][SkinModelPath], "") != 0 && (FileExists(g_skins[g_skinCount][SkinModelPath]) || FileExists(g_skins[g_skinCount][SkinModelPath], true)))
	{
		PrecacheModel(g_skins[g_skinCount][SkinModelPath]);
		AddFileToDownloadsTable(g_skins[g_skinCount][SkinModelPath]);
	}
	
	g_skinCount++;
}

public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}
	
	decl String:name[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, name, sizeof(name));
	
	decl String:loadoutSlot[STORE_MAX_LOADOUTSLOT_LENGTH];
	Store_GetItemLoadoutSlot(itemId, loadoutSlot, sizeof(loadoutSlot));
	
	if (equipped)
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}
	else
	{
		new skin = -1;
		if (!GetTrieValue(g_skinNameIndex, name, skin))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return Store_DoNothing;
		}
			
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));
		
		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "_projectile", false) != -1)
	{
		SDKHook(entity, SDKHook_Spawn, Event_OnNadeSpawn);
	}
}

public Event_OnNadeSpawn(entity)
{
	CreateTimer(0.0, nadetimer, entity, TIMER_FLAG_NO_MAPCHANGE); // create a timer that checks the m_hThrower next frame
}

public Action:nadetimer(Handle:timer, any:entity)
{
	new owner = GetEntDataEnt2(entity, OFFSET_THROWER);
     
	if(0 < owner <= MaxClients && IsClientInGame(owner)) // Valid client index 
    {
    	new Handle:pack = CreateDataPack();
    	WritePackCell(pack, owner);
    	WritePackCell(pack, entity);
        Store_GetEquippedItemsByType(Store_GetClientAccountID(owner), "nadeskins", Store_GetClientLoadout(owner), OnGetPlayerNadeSkin, pack);
    } 
	return Plugin_Stop;
}

public OnGetPlayerNadeSkin(ids[], count, any:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new entity = ReadPackCell(pack);
	CloseHandle(pack);
	
	if (client == 0)
		return;

	for (new index = 0; index < count; index++)
	{
		decl String:itemName[32];
		Store_GetItemName(ids[index], itemName, sizeof(itemName));

		new skin = -1;

		if (!GetTrieValue(g_skinNameIndex, itemName, skin))
		{
			PrintToChat(client, "%s%t", STORE_PREFIX, "No item attributes");
			return;
		}

		SetEntityModel(entity, g_skins[skin][SkinModelPath]);
	}
}