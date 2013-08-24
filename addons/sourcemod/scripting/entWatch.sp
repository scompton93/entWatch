//==========================================================
//
// Name: entWatch
// Author: Prometheum
// Description: Monitors entities.
//
//==========================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <clientprefs>
#include <morecolors>


#include <entWatchFuncs>

new Handle:dropWeapon;
new Handle:hudCookie;
new Handle:globalCooldowns;


enum entities
{
	String:ent_desc[32],
	String:ent_shortdesc[32],
	String:ent_color[32],
	String:ent_name[32],
	String:ent_originalname[32],
	bool:ent_exactname[32],
	bool:ent_singleactivator[32],
	String:ent_type[32],
	String:ent_buttontype[32],
	bool:ent_chat[32],
	bool:ent_hud[32],
	String:ent_ownername[32],
	String:ent_ownersteamid[32],
	ent_buttonid,
	ent_owner,
	ent_id,
	ent_hammerid,
	ent_maxuses,
	ent_uses,
	Float:ent_cooldown,
	bool:ent_hudcooldown,
	ent_cooldowncount,
	ent_canuse
}

new entArray[32][ entities];
new arrayMax = 0;

new bool:configLoaded = false;

public Plugin:myinfo =
{
	name = "entWatch",
	author = "Prometheum",
	description = "#ZOMG #YOLO | Finds entities and hooks events relating to them.",
	version = "2.0",
	url = "https://github.com/Prometheum/entWatch"
};

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public OnPluginStart()
{
	globalCooldowns = CreateConVar("entW_cooldowns", "1", "Turns cooldowns/off");

	CreateConVar("sm_entW_version", "2.0", "Current version of entWatch", FCVAR_NOTIFY);
	
	RegConsoleCmd("hud", Command_dontannoyme);


	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	hudCookie = RegClientCookie("entWatch_displayhud", "EntWatch DisplayHud", CookieAccess_Protected);
	
	CreateTimer(1.0, Timer_DisplayHud, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Cooldowns, _, TIMER_REPEAT);
	
	LoadTranslations("entwatch.phrases");
	
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public OnMapStart()
{
	decl String:buff_mapname[64];
	decl String:buff_temp[64];
	
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
		strcopy( entArray[ i ][ ent_ownername ], 32, "" );
		strcopy( entArray[ i ][ ent_ownersteamid ], 32, "" );
		entArray[ i ][ ent_buttonid ] = -1;
		entArray[ i ][ ent_id ] = -1;
		entArray[ i ][ ent_hammerid ] = -1;
		entArray[ i ][ ent_owner ] = -1;
		entArray[ i ][ ent_maxuses ] = 0;
		entArray[ i ][ ent_uses ] = 0;
		entArray[ i ][ ent_cooldown ] = 2.0;
		entArray[ i ][ ent_hudcooldown ] = false;
		entArray[ i ][ ent_cooldowncount ] = 0;
		entArray[ i ][ ent_canuse ] = 1;
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
			strcopy(entArray[i][ ent_desc], 32, buff_temp);
			
			KvGetString(kv, "short_desc", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_shortdesc], 32, buff_temp);
			
			KvGetString(kv, "color", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_color], 32, buff_temp);
			
			KvGetString(kv, "name", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_name], 32, buff_temp);
			
			KvGetString(kv, "name", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_originalname], 32, buff_temp);
			
			KvGetString(kv, "type", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_type], 32, buff_temp);
			
			KvGetString(kv, "button_type", buff_temp, sizeof(buff_temp));
			strcopy(entArray[i][ ent_buttontype], 32, buff_temp);
			
			KvGetString(kv, "hud", buff_temp, sizeof(buff_temp));
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_hudcooldown] = true;	
			
			KvGetString(kv, "chat", buff_temp, sizeof(buff_temp));
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_chat] = true;	
				
			KvGetString(kv, "hud", buff_temp, sizeof(buff_temp));	
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_hud] = true;	
			
			KvGetString(kv, "exactname", buff_temp, sizeof(buff_temp));				
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_exactname] = true;	

			KvGetString(kv, "singleactivator", buff_temp, sizeof(buff_temp));	
			if(StrEqual(buff_temp, "true"))
				entArray[i][ ent_singleactivator] = true;			
			
			KvGetString(kv, "maxuses", buff_temp, sizeof(buff_temp));
			entArray[i][ ent_maxuses] = StringToInt(buff_temp);
			
			KvGetString(kv, "cooldown", buff_temp, sizeof(buff_temp));
			entArray[i][ ent_cooldown] = StringToFloat(buff_temp);
			
			if(!KvGotoNextKey(kv))
			{
				arrayMax = i + 1;
				i = 32;
			}
		}
	}
	CloseHandle(kv);
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:OnEntityUse(entity, activator, caller, UseType:type, Float:value)
{
	for(new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ent_singleactivator] == true)
		{
			if(entArray[i][ent_buttonid] == entity && entArray[i][ent_canuse] == 1 && entArray[i][ent_owner] == activator && entArray[i][ent_uses] < entArray[i][ent_maxuses] && entArray[i][ent_cooldowncount] == 0)
			{
				PrintToChatAll("\x072570A5[entWatch] \x0700DA00%N \x072570A5%t \x07%s%s", caller, "use", entArray[i][ent_color], entArray[i][ent_desc]);
				entArray[i][ent_uses]++;
				entArray[i][ent_cooldowncount] = RoundToNearest(entArray[i][ent_cooldown]);		
			}			
		}
		else if(entArray[i][ent_singleactivator] == false)
		{
			if(entArray[i][ent_buttonid] == entity && entArray[i][ent_canuse] == 1 && entArray[i][ent_uses] < entArray[i][ent_maxuses] && entArray[i][ent_cooldowncount] == 0)
			{
				PrintToChatAll("\x072570A5[entWatch] \x0700DA00%N \x072570A5%t \x07%s%s", caller, "use", entArray[i][ent_color], entArray[i][ent_desc]);
				entArray[i][ent_uses]++;
				entArray[i][ent_cooldowncount] = RoundToNearest(entArray[i][ent_cooldown]);				
			}			
		}		
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < arrayMax; i++)
	{
		strcopy( entArray[ i ][ ent_name ], 32, entArray[ i ][ ent_originalname] );
		strcopy( entArray[ i ][ ent_ownername ], 32, "" );
		entArray[i][ ent_buttonid] = -1;
		entArray[i][ ent_id] = -1;
		entArray[i][ ent_owner] = -1;
		entArray[i][ ent_uses] = 0;
		entArray[i][ ent_canuse] = 1;
		entArray[ i ][ ent_hammerid ] = -1;
	}
	
	if(configLoaded)
	{
		CPrintToChatAll("\x073600FF[entWatch]\x0701A8FF %t \x073600FFPrometheum", "welcome");
	}	
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:OnWeaponEquip(client, weapon) 
{
	decl String:playername[32];	
	GetClientName(client, playername, sizeof(playername))
	
	decl String:targetname[32];
	Entity_GetTargetName(weapon, targetname, sizeof(targetname));	

	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_hammerid] != -1)
		{
			if(Entity_GetHammerId(weapon) == entArray[i][ ent_hammerid])
			{
				entArray[i][ ent_id] = weapon;
				if(entArray[i][ ent_chat])
					CPrintToChatAll("\x07FFFF00[entWatch] \x0700C900%s \x07FFFF00%t \x07%s%s", playername, "pickup", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
				strcopy(entArray[i][ent_name], 32, targetname);
				entArray[ i ][ ent_owner ] = client;
				strcopy(entArray[i][ ent_ownername], 32, playername);
				HookButton(i);				
				break;
			}
		}
		else if(entArray[i][ ent_exactname])
		{
			if(strcmp(targetname, entArray[i][ ent_name], false) == 0)
			{
				entArray[i][ ent_id] = weapon;
				if(entArray[i][ ent_chat])
					CPrintToChatAll("\x07FFFF00[entWatch] \x0700C900%s \x07FFFF00%t \x07%s%s", playername, "pickup", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
				entArray[ i ][ ent_owner ] = client;
				strcopy(entArray[i][ ent_ownername], 32, playername);
				HookButton(i);				
				break;
			}
		}
		else if(!entArray[i][ ent_exactname])
		{
			if(StrContains(targetname, entArray[i][ ent_name], false) != -1)
			{
				entArray[i][ ent_id] = weapon;
				if(entArray[i][ ent_chat])
					CPrintToChatAll("\x07FFFF00[entWatch] \x0700C900%s \x07FFFF00%t \x07%s%s", playername, "pickup", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
				entArray[ i ][ ent_owner ] = client;
				strcopy(entArray[i][ent_name], 32, targetname);
				strcopy(entArray[i][ ent_ownername], 32, playername);
				HookButton(i);
				break;					
			}
		}	

	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_owner] == client)
		{
			if(entArray[i][ ent_chat])
				CPrintToChatAll("\x0784289E[entWatch] \x0700C900%N \x0784289E%t \x07%s%s", client, "death", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			entArray[ i ][ ent_owner ] = -1;
			strcopy(entArray[i][ ent_ownername], 32, "");
			SDKCall(dropWeapon, client, entArray[ i ][ ent_id ], false, false);
			entArray[ i ][ ent_hammerid ] = Entity_GetHammerId(entArray[ i ][ ent_id ]);
			entArray[ i ][ ent_id ] = -1;
			break;
		}	
	}
}

public OnClientDisconnect(client)
{
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_owner] == client)
		{
			if(entArray[i][ ent_chat])
				CPrintToChatAll("\x07A67CB2[entWatch] \x0700C900%N \x07A67CB2%t \x07%s%s!", client, "disconnect", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			strcopy(entArray[i][ ent_ownername], 32, "");
			entArray[ i ][ ent_owner ] = -1;
			entArray[ i ][ ent_hammerid ] = Entity_GetHammerId(entArray[ i ][ ent_id ]);
			entArray[ i ][ ent_id ] = -1;
			break;
		}	
	}
	if (IsClientInGame(client))
	{
		SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponEquip)
	}
}  

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_owner] == client && entArray[i][ ent_id] == weaponIndex)
		{
			if(entArray[i][ ent_chat])
				CPrintToChatAll("\x079E0000[entWatch] \x0700C900%s \x079E0000%t \x07%s%s", entArray[i][ ent_ownername], "drop", entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			strcopy(entArray[i][ ent_ownername], 32, "");
			entArray[ i ][ ent_owner ] = -1;
			entArray[ i ][ ent_hammerid ] = Entity_GetHammerId(entArray[ i ][ ent_id ]);
			entArray[ i ][ ent_id ] = -1;
			break;
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
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
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Command_ents(client, args)
{
	new i = 1;

	PrintToConsole(client, "%d", entArray[i][ ent_cooldowncount]);

}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Timer_DisplayHud(Handle:timer)
{
	if(configLoaded)
	{
		decl String:szText[254];
		decl String:buffer[32];
		
		for (new i = 1; i < MaxClients; i++)
		{
			if (AreClientCookiesCached(i))
			{
				szText[0] = '\0';
				GetClientCookie(i, hudCookie, buffer, sizeof(buffer));
				if(StrEqual(buffer, "0") && IsClientConnected(i))
				{
					for (new x = 0; x < 32; x++)
					{
						if(entArray[x][ ent_hud] && !StrEqual(entArray[x][ ent_ownername], "") && GetConVarInt(globalCooldowns) == 1)
						{
							if(entArray[x][ ent_hudcooldown] && entArray[x][ ent_uses] < entArray[x][ ent_maxuses])
							{
								if(entArray[x][ ent_cooldowncount] == 0)
									Format(szText, sizeof(szText), "%s[%s]: %s", entArray[x][ ent_shortdesc], "R", entArray[x][ ent_ownername]);		
								else
								{
									Format(szText, sizeof(szText), "%s[%d]: %s", entArray[x][ ent_shortdesc], entArray[x][ ent_cooldowncount], entArray[x][ ent_ownername]);		
								}
							}
							else
							{
								Format(szText, sizeof(szText), "%s[%s]: %s", entArray[x][ ent_shortdesc], "N/A", entArray[x][ ent_ownername]);		
								
							}							
						}
					}
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

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Timer_Cooldowns(Handle:timer)
{
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ ent_cooldowncount] == 0)
		{
		
		}
		else
		{
			entArray[i][ ent_cooldowncount] = entArray[i][ ent_cooldowncount] - 1;
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public HookButton(rootEntity)
{
	if(rootEntity == -1)
		return;

	decl String:EntityClassname[32];
	decl String:EntityParent[32];
	for(new i=0; i < GetEntityCount(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEntityClassname(i, EntityClassname, sizeof(EntityClassname));
			if(StrEqual(EntityClassname, entArray[rootEntity][ ent_buttontype]))
			{
				Entity_GetParentName(i, EntityParent, sizeof(EntityParent));
				if(StrEqual(EntityParent, entArray[rootEntity][ ent_name]))
				{
					entArray[rootEntity][ ent_buttonid] = i;
					SDKHook(i, SDKHook_Use, OnEntityUse);	
					
				}
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip)
} 