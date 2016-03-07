#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION   "1.0"

#define HIDE (0x0001 | 0x0010)
#define SHOW (0x0002)
#define FLASH_ALPHA 0.5

new Handle:g_colfEna = INVALID_HANDLE;
new g_iDuration;
new g_iFlashMaxAlpha;

public Plugin:myinfo = {
    name = "Colored Flash",
    author = "Franc1sco franug & iDragon",
    description = "This plugin changes the Flashbangs color.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart() 
{
	CreateConVar("sm_coloredflash_version", PLUGIN_VERSION, "version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_colfEna = CreateConVar("sm_cf_enabled", "1", "Enable colored flash plugin?");
	
	g_iDuration = FindSendPropOffs("CCSPlayer", "m_flFlashDuration");
	if (g_iDuration == -1)
		SetFailState("[Colored_flashbangs] Failed to get offset for CCSPlayer::m_flFlashDuration.");
	
	g_iFlashMaxAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if (g_iFlashMaxAlpha == -1)
		SetFailState("[Colored_flashbangs] Failed to get offset for CCSPlayer::m_flFlashMaxAlpha.");
	
	HookEvent("player_blind", Event_PlayerBlind, EventHookMode_Post);
	
}

public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_colfEna))
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"))
		new color[4];
		
		color[0] = GetRandomInt(0, 255);
		color[1] = GetRandomInt(0, 255);
		color[2] = GetRandomInt(0, 255);
		color[3] = 255;
		float flash_duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");

		SetEntDataFloat(client,g_iFlashMaxAlpha,FLASH_ALPHA);
		
		new Handle:message;
		
	
		message = StartMessageOne("Fade", client);
		
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(message, "duration", 100);
			PbSetInt(message, "hold_time", view_as<int>(flash_duration));
			PbSetInt(message, "flags", SHOW);
			PbSetColor(message, "clr", color);
		}
		else
		{
			BfWriteShort(message, 100);
			BfWriteShort(message, view_as<int>(flash_duration));
			BfWriteShort(message, SHOW);
			BfWriteByte(message, color[0]);
			BfWriteByte(message, color[1]);
			BfWriteByte(message, color[2]);
			BfWriteByte(message, color[3]);
		}
 
		EndMessage();
		CreateTimer(flash_duration , BackToNormal, GetClientUserId(client));
	}
}

public Action:BackToNormal(Handle:timer, any:userid)
{
		new client = GetClientOfUserId(userid);
		if (client < 1 || !IsClientInGame(client))return;
		
		new Handle:message;
		
		new color[4];
		
		color[0] = 0;
		color[1] = 0;
		color[2] = 0;
		color[3] = 0;
		
		message = StartMessageOne("Fade", client);
		
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(message, "duration", 1536);
			PbSetInt(message, "hold_time", 1536);
			PbSetInt(message, "flags", HIDE);
			PbSetColor(message, "clr", color);
		}
		else
		{
			BfWriteShort(message, 1536);
			BfWriteShort(message, 1536);
			BfWriteShort(message, HIDE);
			BfWriteByte(message, color[0]);
			BfWriteByte(message, color[1]);
			BfWriteByte(message, color[2]);
			BfWriteByte(message, color[3]);
		}
		EndMessage();
}