--[[
    Hyltaria - Configuration centralisee du Guess Who
    ==================================================

    Toutes les valeurs de gameplay propres a Hyltaria sont ici.
    Fichier partage (serveur + client) : il est inclus par shared.lua
    et envoye aux clients par init.lua.

    Apres modification : redemarrer la map (changelevel) pour tout appliquer.

    Ce qui reste ailleurs :
      - Durees de round, nombre de NPC, vitesses, touches requises...
        -> convars de guesswho.txt (server.cfg)
      - Modeles, liste des capacites actives, couleurs
        -> sh_config.lua / menu F1 (attention : data/guesswho/config.txt
           ecrase sh_config.lua s'il existe)
]]

HYLTARIA_GW = HYLTARIA_GW or {}
local CFG = HYLTARIA_GW

----------------------------------------------------------------------
-- CAPACITES DES HIDERS
----------------------------------------------------------------------

-- true  = chaque Hider recoit une capacite aleatoire a son spawn (comportement d'origine)
-- false = aucun Hider ne commence avec une capacite : il doit toucher le Hunter
--         gw_touches_required fois (3 par defaut) pour en obtenir une.
--         Le compteur de touches est remis a zero au debut de chaque round.
--         /!\ Il faut que gw_touches_enabled = 1, sinon personne n'aura de capacite.
CFG.StartWithAbility = false

-- Affiche une notification aux Hiders sans capacite pour leur expliquer
-- comment en obtenir une (uniquement si StartWithAbility = false).
CFG.ShowNoAbilityNotification = true

----------------------------------------------------------------------
-- POINTS DE VIE ET SAUT
----------------------------------------------------------------------

CFG.HiderHealth = 100
CFG.HunterHealth = 100

CFG.HiderJumpPower = 200
CFG.HunterJumpPower = 250

-- PV des NPC (gw_npc_walker)
CFG.WalkerHealth = 100

----------------------------------------------------------------------
-- HUNTER : PIED-DE-BICHE ET ARMES
----------------------------------------------------------------------

CFG.Crowbar = {
    Damage = 20,              -- degats de base
    PlayerMultiplier = 2,     -- degats sur un joueur = Damage x PlayerMultiplier (40)
    NPCMultiplier = 3,        -- degats sur un NPC / prop = Damage x NPCMultiplier (60)
    Delay = 0.7,              -- secondes entre deux coups
    Range = 85,               -- portee en unites
    DashCharges = 3,          -- charges de dash (clic droit)
    DashRestoreDelay = 3,     -- secondes pour recuperer une charge
}

CFG.HunterSMGAmmo = 200       -- balles de SMG au spawn
CFG.HunterGrenades = 1        -- grenades de SMG au spawn ("Nuke ready!")

----------------------------------------------------------------------
-- REGLAGES DES CAPACITES
-- Valeurs actuelles = celles du code d'origine. Supprime une ligne pour
-- garder la valeur du fichier de l'arme.
----------------------------------------------------------------------

CFG.Abilities = {
    weapon_gw_prophunt      = { AbilityDuration = 7 },
    weapon_gw_surge         = { AbilityDuration = 1.5 },     -- delai avant l'explosion
    weapon_gw_shockwave     = { AbilityRange = 300, AbilityDuration = 4, AbilityCastTime = 0.5 },
    weapon_gw_cloak         = { AbilityDuration = 7 },
    weapon_gw_shrink        = { AbilityDuration = 7 },
    weapon_gw_decoy         = { AbilityDecoyCountMin = 2, AbilityDecoyCountMax = 9, AbilityDuration = 14 },
    weapon_gw_sudoku        = { AbilityModelScaleTimes = 10 }, -- la duree est recalculee (ln de cette valeur)
    weapon_gw_disguise      = { AbilityDuration = 20 },
    weapon_gw_vampirism     = { AbilityRange = 500, AbilityDuration = 5 },
    weapon_gw_ragdoll       = { AbilityDuration = 8 },
    weapon_gw_superhot      = { AbilityDuration = 8 },
    weapon_gw_blasting_off  = { AbilityDuration = 3 },
    weapon_gw_teleport      = { AbilityRange = 2000, AbilityDuration = 1.5 },
    weapon_gw_deflect       = { AbilityDuration = 12 },
    weapon_gw_timelapse     = { AbilityDuration = 15 },
    weapon_gw_solarflare    = { AbilityRange = 400, AbilityDuration = 6, AbilityCastTime = 1.25 },
    weapon_gw_mind_transfer = { AbilityRange = 1600 },
    weapon_gw_tumble        = { AbilityRange = 500, AbilityDuration = 3, AbilityCastTime = 0.5 },
}

-- Rayon du puits de gravite de Graviton Surge
CFG.SurgeWallRadius = 350


----------------------------------------------------------------------
-- ======== NE PAS MODIFIER EN DESSOUS (logique d'application) ========
----------------------------------------------------------------------

-- Tire une capacite parmi GWConfig.ActiveAbilities.
-- Si la liste est vide (tout decoche dans F1), donne l'arme sans capacite
-- au lieu de faire planter math.random(1, 0).
function HYLTARIA_GW.GetRandomAbility()
    local list = GAMEMODE and GAMEMODE.GWConfig and GAMEMODE.GWConfig.ActiveAbilities
    if not list or #list == 0 then
        return "weapon_gw_default"
    end
    return list[math.random(1, #list)]
end

-- Applique les reglages ci-dessus aux armes enregistrees.
-- Les armes du dossier entities/ sont chargees apres le gamemode,
-- donc on attend InitPostEntity.
local function applyOverrides()
    for class, fields in pairs(CFG.Abilities or {}) do
        local stored = weapons.GetStored(class)
        if stored then
            for key, value in pairs(fields) do
                stored[key] = value
            end
            if class == "weapon_gw_sudoku" and fields.AbilityModelScaleTimes then
                stored.AbilityDuration = math.log(fields.AbilityModelScaleTimes)
            end
        else
            MsgN("[Hyltaria GW] Capacite inconnue dans sh_hyltaria_config.lua : " .. class)
        end
    end

    local crowbar = weapons.GetStored("weapon_gw_seeker_crowbar")
    if crowbar and CFG.Crowbar then
        local c = CFG.Crowbar
        crowbar.Damage = c.Damage or crowbar.Damage
        crowbar.PlayerDamageMultiplier = c.PlayerMultiplier or crowbar.PlayerDamageMultiplier
        crowbar.NPCDamageMultiplier = c.NPCMultiplier or crowbar.NPCDamageMultiplier
        crowbar.Delay = c.Delay or crowbar.Delay
        crowbar.Range = c.Range or crowbar.Range
        crowbar.DashRestoreDelay = c.DashRestoreDelay or crowbar.DashRestoreDelay
        if c.DashCharges then
            crowbar.Secondary.ClipSize = c.DashCharges
            crowbar.Secondary.DefaultClip = c.DashCharges
        end
    end

    local wall = scripted_ents.GetStored("gw_ability_wall")
    if wall and wall.t and CFG.SurgeWallRadius then
        wall.t.Radius = CFG.SurgeWallRadius
    end
end
hook.Add("InitPostEntity", "HyltariaGW_ApplyOverrides", applyOverrides)
hook.Add("OnReloaded", "HyltariaGW_ApplyOverridesReload", applyOverrides) -- apres un auto-refresh Lua

if SERVER then
    -- Remise a zero du compteur de touches (Hider qui touche le Hunter).
    -- KillSilent (fin de round) ne passe pas par PlayerDeath, donc sans ca
    -- les survivants gardaient leurs touches d'un round a l'autre.
    local function resetAllTouches()
        for _, ply in ipairs(player.GetAll()) do
            ply:GWSetSeekerTouches(0)
            ply:GWSetLastSeekerTouch(0)
        end
    end
    hook.Add("GWPostRound", "HyltariaGW_ResetTouchesPost", resetAllTouches)
    hook.Add("GWHide", "HyltariaGW_ResetTouchesHide", resetAllTouches)

    hook.Add("InitPostEntity", "HyltariaGW_ConfigWarnings", function()
        if not CFG.StartWithAbility and not GetConVar("gw_touches_enabled"):GetBool() then
            MsgN("[Hyltaria GW] ATTENTION : StartWithAbility = false et gw_touches_enabled = 0 -> aucun Hider ne pourra obtenir de capacite.")
        end
    end)
end
