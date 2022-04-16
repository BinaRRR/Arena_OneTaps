//GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
//SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
//GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
//SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
//SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
//SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);

#include <sourcemod>
#include <multi1v1>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <smlib>

#pragma semicolon 1
#pragma newdecls required

ConVar cv_shotFrequency;
float shotFrequency;

bool inOneTap[MAXPLAYERS + 1] = { false, ... };
Handle ammoTimer[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "1s2k >> OneTaps [Arena]", 
	author = "BinaR", 
	description = "Wprowadza na serwer arena rundy OneTap", 
	version = "1.1",
	url = "https://1shot2kill.pl/profile/13383-binar/"
};

public void OnPluginStart() {
    HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
    cv_shotFrequency = CreateConVar("1s2k_shotFrequency", "1.0", "Częstotliwość strzału", _, true, 0.1, false);
    LoadTranslations("1s2k_customrounds");
}

public void OnMapStart() {
    shotFrequency = cv_shotFrequency.FloatValue;
}

public void OnClientDisconnect(int client) {
    inOneTap[client] = false;
    if (ammoTimer[client] != INVALID_HANDLE) 
            delete ammoTimer[client];
}

public void Multi1v1_OnRoundTypesAdded() {
    Multi1v1_AddRoundType("OneTaps", "1s2k_onetaps", OneTapsHandler, true, true);
}

public void OneTapsHandler(int client) {
    inOneTap[client] = true;
    CreateTimer(3.0, ShowHud, GetClientUserId(client));
    StripWeapons(client);
    GivePlayerItem(client, "weapon_knife");
    Client_GiveWeaponAndAmmo(client, "weapon_ak47", true, 0, 0, 1, 0);
}

void SetAmmo(int client) {
    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon == -1) return;
    //int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
    SetEntProp(weapon, Prop_Send, "m_iClip2", 0);
}

void StripWeapons(int client) {
    int weapon;
    for (int i = 0; i < 4; i++) {
        while ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
			if (IsValidEntity(weapon)) {
				RemovePlayerItem(client, weapon);
			}
		}
    }
}

public Action Event_WeaponFire(Event e, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(e.GetInt("userid"));
    if (inOneTap[client]) {
        ammoTimer[client] = CreateTimer(1.0, Timer_Shot, GetClientUserId(client));
        ShowWaitHud(GetClientUserId(client));
    }
}

public Action ShowHud(Handle timer, any userid) {
    int client = GetClientOfUserId(userid);
    if (client == 0)
		return Plugin_Continue;
    ShowShootHud(client);
    return Plugin_Continue;
}

void ShowShootHud(int client) {
    SetHudTextParams(-1.0, 0.1, 99.0, 0, 255, 0, 0);
    //ShowHudText(client, 7, "Shoot!");
    ShowHudText(client, 7, "%t", "Shoot");
}

void ShowWaitHud(int client) {
    SetHudTextParams(-1.0, 0.1, shotFrequency, 255, 0, 0, 0);
    //ShowHudText(client, 7, "Wait...");
    ShowHudText(client, 7, "%t", "Wait");
}

public Action Timer_Shot(Handle timer, any userid) {
    int client;
    if ((client = GetClientOfUserId(userid)) == 0) {
        return;
    }
    SetAmmo(client);
    ShowShootHud(client);
    ammoTimer[client] = INVALID_HANDLE;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) {
    for (int i = 1; i <= MaxClients; i++) {
        inOneTap[i] = false;
        if (!IsClientInGame(i)) {
            continue;
        }
        SetHudTextParams(-1.0, -1.0, 0.1, 0, 255, 0, 255);
        ShowHudText(i, 7, "");
        if (ammoTimer[i] != INVALID_HANDLE) {
            delete ammoTimer[i];
            ammoTimer[i] = INVALID_HANDLE;
        }
    }
}