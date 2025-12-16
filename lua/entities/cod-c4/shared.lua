ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.PrintName		= "C4"
ENT.Author			= "Hoff"

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

hook.Add("Initialize","CreateC4Convars",function()
    if !ConVarExists("C4_DoorSearchRadius") then
        CreateConVar("C4_Infinite", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Should C4 be infinite? 1 = infinite")
        CreateConVar("C4_ThrowSpeed", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How long is the delay between C4 throws?")
        CreateConVar("C4_Magnitude", 175, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How strong is the C4 explosion?")
        CreateConVar("C4_KnockDoors", 0, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Should C4 knock down doors?")
        CreateConVar("C4_DoorKnockStrength", 500, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How hard should the door be blasted?")
        CreateConVar("C4_DoorSearchRadius", 75, { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "How far away should doors be effected?")
    end
    if CLIENT then
        if !ConVarExists("C4_RedLight") then
            CreateClientConVar("C4_RedLight", 1, true)
        end
        local function funcCallback(CVar, PreviousValue, NewValue)
            net.Start("C4_Convars_Change", true)
            net.WriteString(CVar)
            net.WriteFloat(tonumber(NewValue))
            net.SendToServer()
        end
        cvars.AddChangeCallback("C4_Infinite", funcCallback)
        cvars.AddChangeCallback("C4_ThrowSpeed", funcCallback)
        cvars.AddChangeCallback("C4_Magnitude", funcCallback)
        cvars.AddChangeCallback("C4_KnockDoors", funcCallback)
        cvars.AddChangeCallback("C4_DoorKnockStrength", funcCallback)
        cvars.AddChangeCallback("C4_DoorSearchRadius", funcCallback)
    end
end)

if SERVER then
    util.AddNetworkString("C4_Convars_Change")

    net.Receive("C4_Convars_Change", function(len, ply)
        if !ply:IsAdmin() then
            return
        end
        local cvar_name = net.ReadString()
        local cvar_val = net.ReadFloat()
        RunConsoleCommand(cvar_name, cvar_val)
    end)

elseif CLIENT then
    hook.Add("PopulateToolMenu", "AddC4SettingsPanel", function()
        spawnmenu.AddToolMenuOption("Utilities", "Hoff's Addons", "C4SettingsPanel", "C4 Setup", "", "", function(cpanel)

            if !game.SinglePlayer() and !LocalPlayer():IsAdmin() then
                cpanel:CheckBox("C4 Red Light", "C4_RedLight")
                return
            end

            cpanel:CheckBox("Infinite C4", "C4_Infinite")
            cpanel:NumSlider("C4 Magnitude", "C4_Magnitude", 1, 500, 0)
            cpanel:NumSlider("C4 Throw Speed", "C4_ThrowSpeed", 0.1, 10, 2)
            cpanel:CheckBox("Knock Down Doors", "C4_KnockDoors")
            cpanel:NumSlider("Door Knock Strength", "C4_DoorKnockStrength", 100, 2500, 0)
            cpanel:NumSlider("Door Search Radius", "C4_DoorSearchRadius", 1, 500, 0)
            cpanel:CheckBox("C4 Red Light", "C4_RedLight")
        end)
    end)
end
