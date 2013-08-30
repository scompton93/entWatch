//=====================================================================================================================
// 
// Name: entWatch
// Author: Prometheum
// Description: Monitors entities.
// 
//=====================================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <clientprefs>
#include <morecolors>
#include <cstrike>


#include <entWatchFuncs>

new Handle:hudCookie = INVALID_HANDLE;
new Handle:globalCooldowns = INVALID_HANDLE;

new bans[MAXPLAYERS+1];


enum entities
{
	String:ent_desc[32],
	String:ent_shortdesc[32],
	String:ent_color[32],
	String:ent_name[32],
	String:ent_realname[32],
	bool:ent_exactname[32],
	bool:ent_singleactivator[32],
	String:ent_type[32],
	String:ent_buttontype[32],
	bool:ent_chat[32],
	bool:ent_hud[32],
	ent_buttonid,
	ent_owner,
	ent_id,
	ent_mode,// 0 = Disabled, 1 = Cooldowns, 2 = Toggle, 3 = Limited uses, 4 = Limited uses with cooldowns, 5 = N/A
	ent_maxuses,
	ent_uses,
	ent_hammerid,
	Float:ent_cooldown,
	ent_cooldowncount,
	String:ent_using[32]
}

new entArray[32][ entities];
new arrayMax = 0;

new bool:configLoaded = false;

public Plugin:myinfo =
{
	name = "entWatch",
	author = "Prometheum",
	description = "#ZOMG #YOLO | Finds entities and hooks events relating to them.",
	version = "1.9",
	url = "https://github.com/Prometheum/entWatch"
};

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public OnPluginStart()
{
	globalCooldowns = CreateConVar("entW_cooldowns", "1", "Turns cooldowns/off");

	CreateConVar("sm_entW_version", "1.9", "Current version of entWatch", FCVAR_NOTIFY);
	
	RegConsoleCmd("hud", Command_dontannoyme);
	RegAdminCmd("etransfer", Command_Transfer, ADMFLAG_KICK, "Transfers an entity");
	RegAdminCmd("etrans", Command_Transfer, ADMFLAG_KICK, "Transfers an entity");

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	hudCookie = RegClientCookie("entWatch_displayhud", "EntWatch DisplayHud", CookieAccess_Protected);
	
	CreateTimer(1.0, Timer_DisplayHud, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Cooldowns, _, TIMER_REPEAT);
	
	LoadTranslations("entwatch.phrases");
	
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public OnMapStart()
{
	new String:buff_mapname[64];
	new String:buff_temp[64];
	
	for(new i = 0; i < 32; i++)
	{
		strcopy( entArray[ i ][ ent_desc ], 32, "null" );
		strcopy( entArray[ i ][ ent_shortdesc ], 32, "" );
		strcopy( entArray[ i ][ ent_color ], 32, "null" );
		strcopy( entArray[ i ][ ent_name ], 32, "null" );
		strcopy( entArray[ i ][ ent_type ], 32, "null" );
		strcopy( entArray[ i ][ ent_buttontype ], 32, "null" );
		entArray[ i ][ ent_chat ] = false;
		entArray[ i ][ ent_hud ] = false;
		entArray[ i ][ ent_buttonid ] = -1;
		entArray[ i ][ ent_id ] = -1;
		entArray[ i ][ ent_mode ] = -1;
		entArray[ i ][ ent_hammerid ] = -1;
		entArray[ i ][ ent_owner ] = -1;
		entArray[ i ][ ent_uses ] = 0;
		entArray[ i ][ ent_maxuses ] = 1;
		entArray[ i ][ ent_cooldown ] = 2.0;
		entArray[ i ][ ent_cooldowncount ] = 0;
		entArray[ i ][ ent_exactname ] = false;
		entArray[ i ][ ent_singleactivator ] = false;
	}	
	
	GetCurrentMap(buff_mapname, sizeof(buff_mapname));
	
	Format(buff_temp, sizeof(buff_temp), "cfg/sourcemod/entwatch/%s.txt", buff_mapname);
	
	LogMessage("Loading %s", buff_temp);
	
	new Handle:kv = CreateKeyValues("entities");
	FileToKeyValues(kv, buff_temp);

	KvRewind(kv);
	if (!KvGotoFirstSubKey(kv))
	{
		LogMessage("Could not load %s", buff_temp);
	} 
	else
	{
		configLoaded = true;
		KvJumpToKey(kv, "0")
		for(new i = 0; i < 32; i++)
		{
			KvGetString(kv, "desc", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_desc ], 32, buff_temp);
			
			KvGetString(kv, "short_desc", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_shortdesc ], 32, buff_temp);
			
			KvGetString(kv, "color", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_color ], 32, buff_temp);
			
			KvGetString(kv, "name", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_name ], 32, buff_temp);
			
			KvGetString(kv, "type", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_type ], 32, buff_temp);
			
			KvGetString(kv, "button_type", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_buttontype ], 32, buff_temp);
			
			KvGetString(kv, "chat", buff_temp, sizeof(buff_temp));
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_chat ] = true;
				
			KvGetString(kv, "hud", buff_temp, sizeof(buff_temp));
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_hud ] = true;
			
			KvGetString(kv, "exactname", buff_temp, sizeof(buff_temp));
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_exactname ] = true;

			KvGetString(kv, "singleactivator", buff_temp, sizeof(buff_temp));
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_singleactivator ] = true;
			
			KvGetString(kv, "cooldown", buff_temp, sizeof(buff_temp));
			entArray[i][ ent_cooldown ] = StringToFloat(buff_temp);
			
			KvGetString(kv, "mode", buff_temp, sizeof(buff_temp));
			entArray[i][ ent_mode ] = StringToInt(buff_temp);
			
			KvGetString(kv, "maxuses", buff_temp, sizeof(buff_temp));
			entArray[i][ ent_maxuses ] = StringToInt(buff_temp);
			
			
			if(!KvGotoNextKey(kv))
			{
				arrayMax = i + 1;
				i = 32;
			}
		}
	}
	CloseHandle(kv);
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:OnEntityUse(entity, activator, caller, UseType:type, Float:value)
{
	new String:clientBuffer[32];
	
	GetClientAuthString(caller, clientBuffer, sizeof(clientBuffer));

	new i ;
	for(i= 0; i < arrayMax; i++)
	{
		if(entArray[ i ][ ent_buttonid ] == entity)
		{
			break;
		}
	}
	if(entArray[ i ][ ent_owner ] != caller && entArray[ i ][ ent_owner ] != activator )
		return Plugin_Handled;	
	
	strcopy(entArray[ i ][ ent_using ], 32, "U");
	if(entArray[ i ][ ent_singleactivator ] == true)
	{
		if( entArray[ i ][ ent_mode ] == 1 && entArray [ i ][ ent_cooldowncount ] == 0)
		{
			CPrintToChatAll("\x072570A5[entWatch] \x0700DA00%N\x0776CF76[%s] \x072570A5%t \x07%s%s", caller, clientBuffer, "use", entArray[i][ent_color], entArray[i][ent_desc]);
			entArray[ i ][ ent_cooldowncount ] = RoundToNearest(entArray[i][ent_cooldown]);
			return Plugin_Continue;
		}
		else if(entArray[ i ][ ent_mode ] == 3  && entArray[ i ][ ent_uses ] != entArray[ i ][ ent_maxuses ] )
		{
			entArray[ i ][ ent_uses ]++;
			return Plugin_Continue;
		}
		else if(entArray[ i ][ ent_mode ] == 2 )
		{
			return Plugin_Continue;
		}		
		else if(entArray[ i ][ ent_mode ] == 4 && entArray[ i ][ ent_uses ] != entArray[ i ][ ent_maxuses ] && entArray [ i ][ ent_cooldowncount ] == 0)
		{
			entArray[ i ][ ent_uses ]++;
			entArray[ i ][ ent_cooldowncount ] = RoundToNearest(entArray[i][ent_cooldown]);
			CPrintToChatAll("\x072570A5[entWatch] \x0700DA00%N\x0776CF76[%s] \x072570A5%t \x07%s%s", caller, clientBuffer, "use", entArray[i][ent_color], entArray[i][ent_desc]);
			return Plugin_Continue;
		}
	}
	else
	{
		if( entArray[ i ][ ent_mode ] == 1 && entArray [ i ][ ent_cooldowncount ] == 0)
		{
			CPrintToChatAll("\x072570A5[entWatch] \x0700DA00%N\x0776CF76[%s] \x072570A5%t \x07%s%s", caller, clientBuffer, "use", entArray[i][ent_color], entArray[i][ent_desc]);
			entArray[ i ][ ent_cooldowncount ] = RoundToNearest(entArray[i][ent_cooldown]);
			return Plugin_Continue;
		}
		else if(entArray[ i ][ ent_mode ] == 2 )
		{
			return Plugin_Continue;
		}				
		else if(entArray[ i ][ ent_mode ] == 3  && entArray[ i ][ ent_uses ] != entArray[ i ][ ent_maxuses ] )
		{
			entArray[ i ][ ent_uses ]++;
			return Plugin_Continue;
		}
		else if(entArray[ i ][ ent_mode ] == 4 && entArray[ i ][ ent_uses ] != entArray[ i ][ ent_maxuses ] && entArray [ i ][ ent_cooldowncount ] == 0)
		{
			entArray[ i ][ ent_uses ]++;
			entArray[ i ][ ent_cooldowncount ] = RoundToNearest(entArray[i][ent_cooldown]);
			CPrintToChatAll("\x072570A5[entWatch] \x0700DA00%N\x0776CF76[%s] \x072570A5%t \x07%s%s", caller, clientBuffer, "use", entArray[i][ent_color], entArray[i][ent_desc]);
			return Plugin_Continue;
		}			
	}
	return Plugin_Handled;	
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < arrayMax; i++)
	{
		SDKUnhook(entArray[i][ ent_id], SDKHook_Use, OnEntityUse);
		entArray[i][ ent_buttonid] = -1;
		entArray[i][ ent_id] = -1;
		entArray[i][ ent_owner] = -1;
		entArray[ i ][ ent_hammerid ] = -1;
		entArray[ i ][ ent_uses ] = 0;
		entArray [ i ][ ent_cooldowncount ] = 0;
		
	}
	
	if(configLoaded)
	{
		CPrintToChatAll("\x073600FF[entWatch]\x0701A8FF %t \x073600FFPrometheum", "welcome");
	}	
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:OnWeaponCanUse(client, weapon)
{
	decl String:targetname[32];
	Entity_GetTargetName(weapon, targetname, sizeof(targetname));
	
	for (new i = 0; i < arrayMax; i++)
	{		
		if(entArray[i][ent_hammerid] != -1)
		{
			if(entArray[ i ][ ent_hammerid ] == Entity_GetHammerId(weapon))
			{
				entArray[i][ ent_id] = weapon;
				break;
			}
		}
		else if (entArray[i][ent_id] == -1)
		{
			if(entArray[i][ent_exactname])
			{
				if(strcmp(targetname, entArray[i][ ent_name], false) == 0)
				{
					entArray[i][ ent_id] = weapon;
					HookButton(i);	
					break;
				}
			}
			else if(!entArray[i][ent_exactname])
			{
				if(StrContains(targetname, entArray[i][ ent_name], false) != -1)
				{
					entArray[i][ ent_id] = weapon;
					HookButton(i);	
					break;
				}
				
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:OnWeaponEquip(client, weapon) 
{	
	new String:clientBuffer[32];
	
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ent_id] == weapon)
		{
			entArray[ i ][ ent_owner] = client;
			if(entArray[i][ ent_chat])
				CPrintToChatAll("\x07FFFF00[entWatch] \x0700DA00%N\x0776CF76[%s] \x07FFFF00%t \x07%s%s", client, clientBuffer, "pickup", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			break;
		}	
	}
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:clientBuffer[32];
	
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));
	
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_owner] == client)
		{
			if(entArray[i][ ent_chat])
				CPrintToChatAll("\x0784289E[entWatch] \x0700DA00%N\x0776CF76[%s] \x0784289E%t \x07%s%s", client, clientBuffer, "death", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			entArray[ i ][ ent_hammerid ] = Entity_GetHammerId(entArray[ i ][ ent_id ]);
			entArray[ i ][ ent_owner] = -1;
			entArray[i][ ent_id] = -1;
			
			break;
		}	
	}
}

public OnClientDisconnect(client)
{
	new String:clientBuffer[32];
	
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_owner] == client)
		{
			if(entArray[i][ ent_chat])
				CPrintToChatAll("\x07A67CB2[entWatch] \x0700DA00%N\x0776CF76[%s] \x07A67CB2%t \x07%s%s!", client, clientBuffer, "disconnect", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			entArray[ i ][ ent_hammerid ] = Entity_GetHammerId(entArray[ i ][ ent_id ]);
			entArray[ i ][ ent_owner ] = -1;
			entArray[i][ ent_id] = -1;
			break;
		}	
	}
	if (IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip);
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}  

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	new i = FindEntityInLocalArray(weaponIndex);
	new String:clientBuffer[32];
	
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));	
	if(i != -1)
	{
		if(entArray[i][ ent_chat])
			CPrintToChatAll("\x079E0000[entWatch] \x0700DA00%N\x0776CF76[%s] \x079E0000%t \x07%s%s", client, clientBuffer, "drop", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
		entArray[ i ][ ent_hammerid ] = Entity_GetHammerId(entArray[ i ][ ent_id ]);
		entArray[ i ][ ent_owner ] = -1;
		entArray[i][ ent_id] = -1;
	}
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:Command_dontannoyme(client, args)
{
	decl String:buffer[32];
	GetClientCookie(client, hudCookie, buffer, sizeof(buffer));
	if(StrEqual(buffer, "0"))
	{
		SetClientCookie(client, hudCookie, "1");
	}
	else
	{
		SetClientCookie(client, hudCookie, "0");
	}
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:Command_Transfer(client, args)
{
	if (args < 2)
	{
		CPrintToChat(client, "\x07E01B5D[entWatch] \x07EDEDEDUsage: etransfer <entity owner> <recepient>");
		return Plugin_Handled;
	}
 
	new String:name[32], target = -1;
	GetCmdArg(1, name, sizeof(name));
	new String:recepient[32], recep = -1;
	GetCmdArg(2, recepient, sizeof(recepient));	
 
	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			decl String:other[32];
			GetClientName(i, other, sizeof(other));
			if (StrContains(other, name, false) != -1)
			{
				target = i;
			}
		}
	}

	for (new i=1; i<=MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			decl String:other[32];
			GetClientName(i, other, sizeof(other));
			if (StrContains(other, recepient, false) != -1)
			{
				recep = i;
			}
		}
	}
	
	new index;
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[ i ][ ent_owner ] == target)
		{
			new entid = entArray[ i ][ ent_id ];
			index = i;
			new Float:vec[3];
			GetEntPropVector(recep, Prop_Send, "m_vecOrigin", vec);
			CS_DropWeapon(target, entArray[ i ][ ent_id ], false, false);
			TeleportEntity(entid, vec, NULL_VECTOR, NULL_VECTOR);
		}
	}
	CPrintToChatAll("\x07E01B5D[entWatch] \x075BC75B%N \x07EDEDEDis transferring \x07%s%s \x07EDEDEDfrom \x0700DA00%N \x07EDEDEDto \x0700DA00%N", client, entArray[ index ][ ent_color ], entArray[ index ][ ent_shortdesc ], target, recep);
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:Timer_DisplayHud(Handle:timer)
{
	if(configLoaded)
	{
		new String:szText[254];
		new String:buffer[32];
		

		for (new x = 0; x < 32; x++)
		{
			new String:textBuffer[128];
			if(entArray[x][ ent_hud ]  && GetConVarInt(globalCooldowns) == 1 && entArray[x][ ent_owner ] != -1)
			{
				if(entArray[ x ][ ent_mode ] == 1)
				{
					if(entArray[x][ ent_cooldowncount] == 0)
						Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[x][ ent_shortdesc], "R", entArray[x][ ent_owner]);
					else
					{
						Format(textBuffer, sizeof(textBuffer), "%s[%d]: %N\n", entArray[x][ ent_shortdesc], entArray[x][ ent_cooldowncount], entArray[x][ ent_owner]);
					}
				}
				if(entArray[ x ][ ent_mode ] == 2)
				{
					Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[x][ ent_shortdesc], entArray[x][ ent_using], entArray[x][ ent_owner]);
				}
				if(entArray[ x ][ ent_mode ] == 3)
				{
					Format(textBuffer, sizeof(textBuffer), "%s[%d/%d]: %N\n", entArray[ x ][ ent_shortdesc ], entArray[ x ][ ent_uses ], entArray[ x ][ ent_maxuses ], entArray[x][ ent_owner] );
					if(entArray[ x ][ ent_maxuses ] == 1 && entArray[ x ][ ent_uses ] == 0)
						Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[ x ][ ent_shortdesc ], "R", entArray[x][ ent_owner]);
					if(entArray[ x ][ ent_maxuses ] == entArray[ x ][ ent_uses ])
						Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[ x ][ ent_shortdesc ], "D", entArray[x][ ent_owner] );
				}
				if(entArray[ x ][ ent_mode ] == 5)
				{
					Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[ x ][ ent_shortdesc ], "N/A", entArray[ x ][ ent_owner] );
				}				
				if(entArray[ x ][ ent_mode ] == 4)
				{
					Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[ x ][ ent_shortdesc ], "N/A", entArray[ x ][ ent_owner] );
					if(entArray[x][ ent_cooldowncount ] == 0)
					{
						if (entArray[ x ][ ent_maxuses ] == entArray[ x ][ ent_uses ])
						{
							Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[ x ][ ent_shortdesc ], "D", entArray[x][ ent_owner] );
						}
						else if (entArray[ x ][ ent_maxuses ] == 1)
						{
							Format(textBuffer, sizeof(textBuffer), "%s[%s]: %N\n", entArray[ x ][ ent_shortdesc ], "R", entArray[x][ ent_owner] );
						}
						if (entArray[ x ][ ent_uses ] > 1)
						{
							Format(textBuffer, sizeof(textBuffer), "%s[%d/%d]: %N\n", entArray[ x ][ ent_shortdesc ], entArray[ x ][ ent_uses ], entArray[ x ][ ent_maxuses ], entArray[ x ][ ent_owner] );
						}
					}
					else if(entArray[x][ ent_cooldowncount ] != 0)
					{
						if (entArray[ x ][ ent_maxuses ] == entArray[ x ][ ent_uses ])
						{
							Format(textBuffer, sizeof(textBuffer), "%s[%d/%d]: %N\n", entArray[ x ][ ent_shortdesc ], entArray[ x ][ ent_uses ], entArray[ x ][ ent_maxuses ], entArray[ x ][ ent_owner] );
						}
						else
						{
							Format(textBuffer, sizeof(textBuffer), "%s[%d]: %N\n", entArray[x][ ent_shortdesc], entArray[x][ ent_cooldowncount], entArray[x][ ent_owner]);
						}
					}
				}
			}
			StrCat(szText, sizeof(szText), textBuffer);
		}
		
		for (new i = 1; i < MaxClients; i++)
		{
			if (AreClientCookiesCached(i))
			{
				GetClientCookie(i, hudCookie, buffer, sizeof(buffer));
				if(StrEqual(buffer, "0") && IsClientConnected(i))
				{
					new Handle:hBuffer = StartMessageOne("KeyHintText", i);
					BfWriteByte(hBuffer, 1);
					BfWriteString(hBuffer, szText);
					EndMessage();
				}
				else if(StrEqual(buffer, "1"))
				{
				
				}
				else if(!StrEqual(buffer, "0") && !StrEqual(buffer, "1"))
				{
					SetClientCookie(i, hudCookie, "0");
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public Action:Timer_Cooldowns(Handle:timer)
{
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[ i] [ ent_cooldowncount ] == 0)
		{
			strcopy(entArray[ i ][ ent_using ], 32, "R");
		}
		else
		{
			entArray[ i ][ ent_cooldowncount ] = entArray[i][ ent_cooldowncount] - 1;
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public HookButton(rootEntity)
{
	if(rootEntity == -1)
		return;

	if(entArray[rootEntity][ ent_buttonid ] != -1)
		return
	decl String:EntityClassname[32];
	decl String:EntityParent[32];
	decl String:EntityRealName[32];
	Entity_GetTargetName(entArray[rootEntity][ ent_id ], EntityRealName, sizeof(EntityRealName));
	for(new i=0; i < GetEntityCount(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEntityClassname(i, EntityClassname, sizeof(EntityClassname));
			if(StrEqual(EntityClassname, entArray[rootEntity][ ent_buttontype]))
			{
				Entity_GetParentName(i, EntityParent, sizeof(EntityParent));
				if(StrEqual(EntityParent, EntityRealName))
				{
					entArray[rootEntity][ ent_buttonid] = i;
					SDKHook(i, SDKHook_Use, OnEntityUse);
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	bans[client] = 0;
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public FindEntityInLocalArray(entity)
{
	for(new i = 0; i < arrayMax; i++)
	{
		if(entity == entArray[i][ ent_id])
		{
			return i;
		}
	}
	return -1;
}

//----------------------------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------------------------
public assignEntity(client, index)
{
	decl String:playername[32];
	GetClientName(client, playername, sizeof(playername))

	if(entArray[index][ ent_chat])
		CPrintToChatAll("\x07FFFF00[entWatch] \x0700C900%s \x07FFFF00%t \x07%s%s", playername, "pickup", entArray[ index ][ ent_color ], entArray[ index ][ ent_desc ]);
	entArray[ index ][ ent_owner ] = client;
	PrintToChatAll("client %d", client);
}