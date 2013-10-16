
//-----------------------------------------------------------------------------
// Purpose: SMLib
//-----------------------------------------------------------------------------
stock bool:Entity_IsPlayer(entity)
{
	if (entity < 1 || entity > MaxClients) {
		return false;
	}
	
	return true;
}

stock Entity_GetTargetName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data,  "m_iName", buffer, size);
}

stock Entity_SetTargetName(entity, const String:name[], any:...)
{
	decl String:format[128];
	VFormat(format, sizeof(format), name, 3);

	return DispatchKeyValue(entity, "target", format);
}

stock Entity_GetParentName(entity, String:buffer[], size)
{
	return GetEntPropString(entity, Prop_Data, "m_iParent", buffer, size);
}

stock Entity_SetParentName(entity, const String:name[], any:...)
{
	decl String:format[128];
	VFormat(format, sizeof(format), name, 3);

	return DispatchKeyValue(entity, "parentname", format);
}

stock Entity_GetHammerId(entity)
{	
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

stock bool:isPermBan(client)
{
	new Handle:kv = CreateKeyValues("bans"), String:path[128], String:clientBuffer[32];
	
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));
	
	strcopy(path, sizeof(path), "cfg/sourcemod/entwatch/bans.txt");	
	
	FileToKeyValues(kv, path);
	if (!KvGotoFirstSubKey(kv))
	{
		return false;
	}
 
	decl String:buffer[255];
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		if (StrEqual(buffer, clientBuffer))
		{
			CloseHandle(kv);
			return true;
		}
	} while (KvGotoNextKey(kv))
 
	CloseHandle(kv);
	return false;
}

stock writeBan(client, submitter)
{
	new String:clientBuffer[32], String:submitterBuffer[128], String:path[128];
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));
	GetClientAuthString(client, submitterBuffer, sizeof(submitterBuffer));
	strcopy(path, sizeof(path), "cfg/sourcemod/entwatch/bans.txt");

	new Handle:kv = CreateKeyValues("bans");
	FileToKeyValues(kv, path);
	KvJumpToKey(kv, clientBuffer, true);
	KvSetString(kv, "client", clientBuffer);
	KvRewind(kv);
	KeyValuesToFile(kv, path);
	CloseHandle(kv);	
}

stock removeBan(client)
{
	new Handle:kv = CreateKeyValues("bans"), String:path[128], String:clientBuffer[32];
	
	GetClientAuthString(client, clientBuffer, sizeof(clientBuffer));
	
	strcopy(path, sizeof(path), "cfg/sourcemod/entwatch/bans.txt");	
	
	FileToKeyValues(kv, path);
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
 
	decl String:buffer[255];
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		if (StrEqual(buffer, clientBuffer))
		{
			KvDeleteThis(kv);
			KeyValuesToFile(kv, path); 
			CloseHandle(kv);
			return
		}
	} while (KvGotoNextKey(kv))

	CloseHandle(kv);
}
