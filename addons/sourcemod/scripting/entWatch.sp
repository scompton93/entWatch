//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <smlib>
#include <clientprefs>
#include <morecolors>

enum entities
{
	String:ent_desc[32],
	String:ent_shortdesc[32],
	String:ent_color[32],
	String:ent_name[32],
	String:ent_type[32],
	String:ent_buttontype[32],
	String:ent_chat[32],
	String:ent_hud[32],
	String:ent_ownername[32],
	ent_buttonid,
	ent_owner,
	ent_id,
	ent_maxuses,
	ent_uses,
	Float:ent_cooldown,
	ent_canuse
} 

// Now we need a variable that holds the player info
new entArray[ 32 ][ entities ];
new arrayMax = 0;

new bool:configLoaded;
new Handle:hudCookie;

public Plugin:myinfo =
{
	name = "entWatch",
	author = "Prometheum",
	description = "#ZOMG #YOLO | Finds entities and hooks events relating to them.",
	version = "1.0",
	url = "https://github.com/Prometheum/entWatch"
};

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public OnPluginStart()
{
	RegConsoleCmd("entW_find", Command_FindEnts, "Finds Entitys matching an argument", ADMFLAG_KICK);
	RegConsoleCmd("entW_dumpmap", Command_dumpmap, "Finds Entitys matching an argument", ADMFLAG_KICK);
	RegConsoleCmd("hud", Command_dontannoyme);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);	
	HookEvent("item_pickup", OnItemPickup);
	
	hudCookie = RegClientCookie("entWatch_displayhud", "EntWatch DisplayHud", CookieAccess_Protected);
	
	CreateTimer(6.0, Timer_DisplayHud, _, TIMER_REPEAT);	
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public OnEntityCreated(entity, const String:classname[])
{
	if(StrContains(classname, "weapon", false) != -1)
	{
		SDKHook(entity, SDKHook_StartTouch, OnEntityTouch);
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:OnEntityTouch(entity, Client)
{
	if(configLoaded)
	{
		if(IsPlayerAlive(Client))
		{
			decl String:targetname[32];
			decl String:temp[32];
			new bool:recordExists=false;
			
			GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
			
			new i;

			for(i = 0; i < arrayMax; i++)
			{
				if(entArray[i][ent_id] == entity)
				{
					recordExists=true;
				}
			}
			
			if(!recordExists)
			{
				for(i = 0; i < arrayMax; i++)
				{ 
					if(entArray[i][ent_id] == -1)
					{
						strcopy( temp, 32, entArray[i][ent_name] );
						if(StrContains(targetname, temp, false) != -1)
						{
							entArray[i][ent_id] = entity;
							strcopy(entArray[i][ent_name], 32, targetname);
							HookButton(i);
							i = arrayMax;
						}
					}
				}
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public HookButton(i)
{
	decl String:tempA[32];
	decl String:tempB[32];
	for(new x=0; x < GetEntityCount(); x++)
	{
		if(IsValidEdict(x))
		{
			GetEntityClassname(x, tempA, sizeof(tempA));
			if(StrEqual(tempA, entArray[i][ent_buttontype]))
			{
				Entity_GetParentName(x, tempB, sizeof(tempB));
				if(StrEqual(tempB, entArray[i][ent_name]))
				{
					entArray[i][ent_buttonid] = x;
					SDKHook(x, SDKHook_Use, OnEntityUse);								
				}
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:OnEntityUse(entity, activator, caller, UseType:type, Float:value)
{
	for(new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ent_buttonid] == entity && entArray[i][ent_canuse] == 1 && entArray[i][ent_uses] < entArray[i][ent_maxuses])
		{
			CPrintToChatAll("\x072570A5[entWatch] \x07%s%s \x072570A5was used by \x0700DA00%N", entArray[i][ent_color], entArray[i][ent_desc], caller);
			entArray[i][ent_uses]++;
			entArray[i][ent_canuse]=0;
			CreateTimer(entArray[i][ent_cooldown], Timer_Cooldown, i);
		}
	}
}  

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:buff_mapname[64];
	decl String:buff_temp[64];
	
	decl String:buff_desc[32];
	decl String:buff_shortdesc[32];
	decl String:buff_color[32];
	decl String:buff_name[32];
	decl String:buff_type[32];
	decl String:buff_buttontype[32];
	decl String:buff_chat[32];
	decl String:buff_hud[32];
	decl String:buff_cooldown[32];
	decl String:buff_maxuses[32];
	
	configLoaded = false;
	
	GetCurrentMap(buff_mapname, sizeof(buff_mapname));
	
	arrayMax = 0;
	
	for (new i = 0; i < 32; i++)
	{
		strcopy( entArray[ i ][ ent_desc ], 32, "null" );
		strcopy( entArray[ i ][ ent_shortdesc ], 32, "" );
		strcopy( entArray[ i ][ ent_color ], 32, "null" );
		strcopy( entArray[ i ][ ent_name ], 32, "null" );
		strcopy( entArray[ i ][ ent_type ], 32, "null" );
		strcopy( entArray[ i ][ ent_buttontype ], 32, "null" );
		strcopy( entArray[ i ][ ent_chat ], 32, "null" );
		strcopy( entArray[ i ][ ent_hud ], 32, "null" );
		strcopy( entArray[ i ][ ent_ownername ], 32, "" );
		entArray[i][ent_buttonid] = -1;
		entArray[i][ent_id] = -1;
		entArray[i][ent_owner] = 0;
		entArray[i][ent_maxuses] = 0;
		entArray[i][ent_uses] = 0;
		entArray[i][ent_cooldown] = 2.0;
		entArray[i][ent_canuse] = 1;
	}	
	
	strcopy(buff_temp, sizeof(buff_temp), "cfg/sourcemod/entWatch/");
	StrCat(buff_temp, sizeof(buff_temp), buff_mapname);
	StrCat(buff_temp, sizeof(buff_temp), ".txt");
	
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
		KvJumpToKey(kv, "0")
		configLoaded = true;
		for(new i = 0; i < 32; i++)
		{

			KvGetString(kv, "desc", buff_desc, sizeof(buff_desc));
			KvGetString(kv, "short_desc", buff_shortdesc, sizeof(buff_shortdesc));
			KvGetString(kv, "color", buff_color, sizeof(buff_color));
			KvGetString(kv, "name", buff_name, sizeof(buff_name));
			KvGetString(kv, "type", buff_type, sizeof(buff_type));
			KvGetString(kv, "button_type", buff_buttontype, sizeof(buff_buttontype));
			KvGetString(kv, "chat", buff_chat, sizeof(buff_chat));
			KvGetString(kv, "hud", buff_hud, sizeof(buff_hud));
			KvGetString(kv, "maxuses", buff_maxuses, sizeof(buff_maxuses));
			KvGetString(kv, "cooldown", buff_cooldown, sizeof(buff_cooldown));
			
			strcopy(entArray[i][ent_desc], 32, buff_desc);
			strcopy(entArray[i][ent_shortdesc], 32, buff_shortdesc);
			strcopy(entArray[i][ent_color], 32, buff_color);
			strcopy(entArray[i][ent_name], 32, buff_name);
			strcopy(entArray[i][ent_type], 32, buff_type);
			strcopy(entArray[i][ent_buttontype], 32, buff_buttontype);
			strcopy(entArray[i][ent_chat], 32, buff_chat);
			strcopy(entArray[i][ent_hud], 32, buff_hud);
			
			entArray[i][ent_maxuses] = StringToInt(buff_maxuses);
			entArray[i][ent_cooldown] = StringToFloat(buff_cooldown);
				
			if(!KvGotoNextKey(kv))
			{
				arrayMax = i + 1;
				i = 32;
			}
		}
	}
	CloseHandle(kv);
	
	if(configLoaded)
	{
		CPrintToChatAll("\x073600FF[entWatch]\x072570A5 Plugin by \x073600FFPrometheum\x072570A5 - Download @ \x073600FFhttps://github.com/Prometheum/entWatch");
		CPrintToChatAll("\x073600FF[entWatch]\x0701A8FF Type !hud to toggle HUD");
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:playername[32];	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	GetClientName(client, playername, sizeof(playername))
	
	new iWeaponEnt = -1;
	for(new iSlot=0; iSlot<10; iSlot++) // someone said that hl2 have 10 slots
	{
		iWeaponEnt = GetPlayerWeaponSlot(client, iSlot); 
		for (new i = 0; i < arrayMax; i++)
		{
			if(entArray[i][ent_id] == iWeaponEnt && entArray[i][ent_id] != -1 && IsPlayerAlive(client))
			{
				CPrintToChatAll("\x07FFFF00[entWatch] \x0700DA00%s \x07FFFF00has picked up \x07%s%s", playername, entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
				entArray[ i ][ ent_owner ] = client;
				strcopy(entArray[i][ent_ownername], 32, playername);
				i=arrayMax;
				iSlot=10;				
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
		if(entArray[i][ent_owner] == client)
		{
			CPrintToChatAll("\x0784289E[entWatch] \x0700DA00%N \x0784289E has lost \x07%s%s \x0784289E through their demise!", client, entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			entArray[ i ][ ent_owner ] = -1;
			strcopy(entArray[i][ent_ownername], 32, "");
			i=arrayMax;		
		}	
	}
}

public OnClientDisconnect(client)
{
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ent_owner] == client)
		{
			CPrintToChatAll("\x07A67CB2[entWatch] \x0700DA00%N \x07A67CB2 disconnected while holding \x07%s%s!", client, entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			entArray[ i ][ ent_owner ] = -1;
			strcopy(entArray[i][ent_ownername], 32, "");
			i=arrayMax;		
		}	
	}
}  

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	decl String:playername[32];
	GetClientName(client, playername, sizeof(playername))	
	for (new i = 0; i < arrayMax; i++)
	{
		if(entArray[i][ent_owner] == client && entArray[i][ent_id] == weaponIndex && IsPlayerAlive(client))
		{
			CPrintToChatAll("\x079E0000[entWatch] \x0700DA00%N \x079E0000has dropped \x07%s%s", client, entArray[ i ][ ent_color ], entArray[ i ][ ent_desc ]);
			playername="";
			strcopy(entArray[i][ent_ownername], 32, playername);
			entArray[ i ][ ent_owner ] = -1;
			i=arrayMax;
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Command_FindEnts(client, args)
{
	new String:namea[32];
	new String:namebuf[32];
	
	new String: arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1) );
	for (new i=0; i<=GetEntityCount(); i++)
	{
		if(IsValidEdict(i))
		{
			GetEdictClassname(i, namea, sizeof(namea))
			GetEntPropString(i, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
			
			if(StrEqual(namea, arg1))
			{
				PrintToConsole(client, "%d |  Name: %s, Type: %s", i, namebuf, namea);
			}
		}
	}
}

//-----------------------------------------------------------------------------
// Purpose:
//-----------------------------------------------------------------------------
public Action:Command_dumpmap(client, args)
{
	PrintToConsole(client, "\n[entWatch]\nIf the ID is -1 it can't find the ent\n");
	for (new i = 0; i < arrayMax; i++)
	{
		CPrintToChatAll("\n");
		CPrintToChatAll("%d | %s", i, entArray[i][ent_desc]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_shortdesc]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_color]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_name]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_type]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_chat]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_hud]);
		CPrintToChatAll("%d | %s", i, entArray[i][ent_ownername]);
		CPrintToChatAll("%d | %d", i, entArray[i][ent_id]);
		CPrintToChatAll("%d | %d", i, entArray[i][ent_owner]);
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
public Action:Timer_Cooldown(Handle:timer, any:index)
{
	entArray[index][ent_canuse] = 1;
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
				if(StrEqual(buffer, "0"))
				{
					if(IsClientConnected(i))
					{
						for (new x = 0; x < 16; x++)
						{
							if(StrEqual(entArray[x][ent_hud], "true") && !StrEqual(entArray[x][ent_ownername], "") )
							{
								StrCat(szText, sizeof(szText), entArray[x][ent_shortdesc]);
								StrCat(szText, sizeof(szText), ": ");
								StrCat(szText, sizeof(szText), entArray[x][ent_ownername]);	
								
								StrCat(szText, sizeof(szText), "\n");						
							}
						}
			
						new Handle:hBuffer = StartMessageOne("KeyHintText", i);
						BfWriteByte(hBuffer, 1);
						BfWriteString(hBuffer, szText);
						EndMessage();  
					}
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