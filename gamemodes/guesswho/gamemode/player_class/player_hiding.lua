AddCSLuaFile()

DEFINE_BASECLASS( "player_guess_who" )

local PLAYER = {}

PLAYER.WalkSpeed = GetConVar("gw_hiding_walk_speed"):GetFloat()
PLAYER.RunSpeed = GetConVar("gw_hiding_run_speed"):GetFloat()
PLAYER.JumpPower = 200
PLAYER.CanUseFlashlight = false

function PLAYER:SetModel()

    local models = GAMEMODE.GWConfig.HidingModels

    local rand = math.random(1, #models)

    util.PrecacheModel( models[rand] )
    self.Player:SetModel( models[rand] )

end

function PLAYER:Loadout()
    local ply = self.Player

    -- Hyltaria : capacites desactivees, ou pas de capacite au depart (sh_hyltaria_config.lua)
    if not GetConVar( "gw_abilities_enabled" ):GetBool() or not HYLTARIA_GW.StartWithAbility then
        ply:Give( "weapon_gw_default" )

        if SERVER and HYLTARIA_GW.ShowNoAbilityNotification and GetConVar( "gw_abilities_enabled" ):GetBool()
            and GetConVar( "gw_touches_enabled" ):GetBool() and GAMEMODE.GWRound:IsCurrentState( GW_ROUND_HIDE ) then
            local touches = GetConVar( "gw_touches_required" ):GetInt()
            GWNotifications:Add( "gwNoAbility", "<font=gw_font_normal>Pas de capacite</font>",
                "<font=gw_font_small>Touche le Hunter " .. touches .. " fois pour obtenir une capacite aleatoire.</font>", 10, ply )
        end
        return
    end

    -- Mort pendant la cache : il recupere la capacite qu'il avait
    local prepAbility = ply:GetGWPrepAbility()
    if ply:GetGWDiedInPrep() and prepAbility and prepAbility ~= "" and prepAbility ~= "weapon_gw_default" then
        ply:Give( prepAbility )
    else
        ply:Give( HYLTARIA_GW.GetRandomAbility() )
    end
end

function PLAYER:ShouldDrawLocal() return true end

function PLAYER:Spawn()
    local clr = GAMEMODE.GWConfig.WalkerColors[math.random(1, #GAMEMODE.GWConfig.WalkerColors)]
    self.Player:SetPlayerColor(Vector(clr.r / 255, clr.g / 255, clr.b / 255))
    self.Player:SetCustomCollisionCheck(true)

    -- Hyltaria : PV et saut (sh_hyltaria_config.lua)
    self.Player:SetMaxHealth( HYLTARIA_GW.HiderHealth )
    self.Player:SetHealth( HYLTARIA_GW.HiderHealth )
    self.Player:SetJumpPower( HYLTARIA_GW.HiderJumpPower )
end


player_manager.RegisterClass( "player_hiding", PLAYER, "player_guess_who" )
