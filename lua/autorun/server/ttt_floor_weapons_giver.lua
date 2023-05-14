if engine.ActiveGamemode() ~= "terrortown" then return end
local modActiveCvar = CreateConVar("ttt_floor_weapons_giver", "1", nil, "Whether this mod is active or not", 0, 1)

local defaultGunReplace = CreateConVar("ttt_floor_weapons_replace_default_guns", "1", {FCVAR_NOTIFY}, "Whether default floor weapons are automatically replaced by random weapons of the same ammo type", 0, 1)

local giverCvar = CreateConVar("ttt_floor_weapons_giver_active", "1", {FCVAR_NOTIFY}, "Whether to give weapons to players at the start of a round", 0, 1)

local giveDelayCvar = CreateConVar("ttt_floor_weapons_giver_delay", "0.2", {FCVAR_NOTIFY}, "Seconds after a round starts until floor weapons are given to players that don't have one", 0.2)

local giveAmmoCvar = CreateConVar("ttt_floor_weapons_giver_ammo", "2", {FCVAR_NOTIFY}, "When weapons are directly given to players, how many boxes of ammo are given alongside", 0)

local spawnCvar = CreateConVar("ttt_floor_weapons_spawner_active", "1", {FCVAR_NOTIFY}, "If a map has few or no guns, whether floor weapons are automatically spawned on the ground", 0, 1)

local spawnDelayCvar = CreateConVar("ttt_floor_weapons_spawner_delay", "0.2", {FCVAR_NOTIFY}, "Seconds after everyone respawns for the next round, weapons are spawned on the ground", 0.2)

local ammoSpawnCvar = CreateConVar("ttt_floor_weapons_spawner_ammo", "2", {FCVAR_NOTIFY}, "How many boxes of ammo are spawned with a gun on the ground", 0)

local gunSpawnCvar = CreateConVar("ttt_floor_weapons_spawner_guns", "6", {FCVAR_NOTIFY}, "How many guns are spawned on the ground per player, if the limit is never reached", 0)

local entityLimitCvar = CreateConVar("ttt_floor_weapons_spawner_limit", "300", {FCVAR_NOTIFY}, "How many weapons and ammo boxes can be on the map before guns and ammo stop being spawned, this includes existing guns and ammo already on the map", 0)

local spawnNearCvar = CreateConVar("ttt_floor_weapons_spawner_near", "4", {FCVAR_NOTIFY}, "Number of guns to spawn near players that have no guns near them, this ignores the ttt_floor_weapons_spawner_guns limit", 0, 4)

-- Gives ammo to a player's gun equivalent to ammo boxes, without going over TTT's reserve ammo limits
local function DirectGiveAmmoBoxes(ply, className, boxNumber)
    local SWEP = weapons.Get(className)
    local ammoEnt = SWEP.AmmoEnt
    local ammoType = SWEP.Primary.Ammo

    if ammoEnt then
        if ammoEnt == "item_ammo_pistol_ttt" then
            ply:SetAmmo(math.min(60, ply:GetAmmoCount(ammoType) + 20 * boxNumber), ammoType)
        elseif ammoEnt == "item_ammo_smg1_ttt" then
            ply:SetAmmo(math.min(60, ply:GetAmmoCount(ammoType) + 30 * boxNumber), ammoType)
        elseif ammoEnt == "item_ammo_revolver_ttt" then
            ply:SetAmmo(math.min(36, ply:GetAmmoCount(ammoType) + 12 * boxNumber), ammoType)
        elseif ammoEnt == "item_ammo_357_ttt" then
            ply:SetAmmo(math.min(20, ply:GetAmmoCount(ammoType) + 10 * boxNumber), ammoType)
        elseif ammoEnt == "item_box_buckshot_ttt" then
            ply:SetAmmo(math.min(24, ply:GetAmmoCount(ammoType) + 8 * boxNumber), ammoType)
        end
    end
end

local entityCount = 0

local function PlaceAmmo(ammoEnt, pos, count)
    if not ammoEnt then return end
    if entityCount >= entityLimitCvar:GetInt() then return end

    -- Spawn as much ammo boxes per gun as set in the convar
    for i = 1, count do
        local ammo = ents.Create(ammoEnt)

        if IsValid(ammo) then
            pos.z = pos.z + 2
            ammo:SetPos(pos)
            ammo:SetAngles(VectorRand():Angle())
            ammo:Spawn()
            ammo:PhysWake()
            entityCount = entityCount + 1
        end
    end
end

local function PlaceWeapon(swep, pos)
    if entityCount >= entityLimitCvar:GetInt() then return end
    local cls = swep and WEPS.GetClass(swep)
    if not cls then return end
    -- Create the weapon, somewhat in the air in case the spot hugs the ground.
    local ent = ents.Create(cls)
    pos.z = pos.z + 3
    ent:SetPos(pos)
    ent:SetAngles(VectorRand():Angle())
    ent:Spawn()
    entityCount = entityCount + 1
    -- Create some associated ammo (if any)
    PlaceAmmo(ent.AmmoEnt, pos, ammoSpawnCvar:GetInt())
end

local spawnPoints = {}

local defaultGuns = {"weapon_zm_sledge", "weapon_zm_shotgun", "weapon_zm_rifle", "weapon_zm_mac10", "weapon_ttt_m16", "weapon_zm_revolver", "weapon_zm_pistol", "weapon_ttt_glock"}

local firstRound = true
local autoSpawnPistols = {}
local autoSpawnHeavyWeps = {}
local ammoGuns = {}
ammoGuns.item_ammo_357_ttt = {}
ammoGuns.item_ammo_pistol_ttt = {}
ammoGuns.item_ammo_revolver_ttt = {}
ammoGuns.item_ammo_smg1_ttt = {}
ammoGuns.item_box_buckshot_ttt = {}
ammoGuns.none = {}
local floorWeapons = {}
local mapEntityCount = 0
local ammoCount = 0
local gunCount = 0
local ammoGunRatio = 1
local floorWeaponPositions = {}

hook.Add("TTTPrepareRound", "FWGGetSpawnPoints", function()
    timer.Simple(0.1, function()
        -- Only runs once a map at the start of the first round
        if firstRound then
            -- Getting the list of all spawnable weapons
            for k, v in pairs(weapons.GetList()) do
                if v and v.AutoSpawnable and (not WEPS.IsEquipment(v)) then
                    table.insert(floorWeapons, v)
                end
            end

            -- Getting the lists of specific types of weapons
            for i, swep in ipairs(floorWeapons) do
                if swep.Kind == WEAPON_PISTOL then
                    table.insert(autoSpawnPistols, swep)
                elseif swep.Kind == WEAPON_HEAVY then
                    table.insert(autoSpawnHeavyWeps, swep)
                end

                if not swep.AmmoEnt then
                    table.insert(ammoGuns.none, swep.ClassName)
                elseif swep.AmmoEnt == "item_ammo_357_ttt" then
                    table.insert(ammoGuns.item_ammo_357_ttt, swep.ClassName)
                elseif swep.AmmoEnt == "item_ammo_pistol_ttt" then
                    table.insert(ammoGuns.item_ammo_pistol_ttt, swep.ClassName)
                elseif swep.AmmoEnt == "item_ammo_revolver_ttt" then
                    table.insert(ammoGuns.item_ammo_revolver_ttt, swep.ClassName)
                elseif swep.AmmoEnt == "item_ammo_smg1_ttt" then
                    table.insert(ammoGuns.item_ammo_smg1_ttt, swep.ClassName)
                elseif swep.AmmoEnt == "item_box_buckshot_ttt" then
                    table.insert(ammoGuns.item_box_buckshot_ttt, swep.ClassName)
                end
            end

            -- Getting the number of weapons and ammo the map already has
            for _, ent in ipairs(ents.GetAll()) do
                if ent.AutoSpawnable then
                    mapEntityCount = mapEntityCount + 1
                    floorWeaponPositions[ent:GetPos()] = ent.AmmoEnt

                    -- Count the number of ammo boxes and guns in case a map has guns but not enough ammo
                    if ent.AmmoType then
                        ammoCount = ammoCount + 1
                    else
                        gunCount = gunCount + 1
                    end
                end
            end

            -- Just to avoid dividing by zero
            if gunCount == 0 then
                gunCount = 1
            end

            ammoGunRatio = ammoCount / gunCount
            firstRound = false
        end

        -- Replacing all default guns with random ones if enabled
        if modActiveCvar:GetBool() and defaultGunReplace:GetBool() then
            for _, ent in ipairs(ents.GetAll()) do
                -- Don't replace guns players have already picked up (i.e. guns that have a parent)
                if not ent.AutoSpawnable or IsValid(ent:GetParent()) then continue end
                local class = ent:GetClass()

                for _, defaultGun in ipairs(defaultGuns) do
                    if class == defaultGun then
                        local ammoEnt = ent.AmmoEnt
                        local pos = ent:GetPos()
                        ent:Remove()
                        local cls

                        if not ammoEnt or not ammoGuns[ammoEnt] then
                            cls = table.Random(ammoGuns.none)
                            cls = ammoGuns.none[math.random(#ammoGuns.none)]
                        else
                            cls = table.Random(ammoGuns[ammoEnt])
                        end

                        local rdmGun = ents.Create(cls)
                        pos.z = pos.z + 3
                        rdmGun:SetPos(pos)
                        rdmGun:SetAngles(VectorRand():Angle())
                        rdmGun:Spawn()
                        break
                    end
                end
            end
        end
    end)

    entityCount = mapEntityCount
    local playerSpawnsActive = true

    if firstRound then
        -- Use all "info_player_" ents as spawn points for weapons, to start with on the first round, 
        -- as they include entities that are very likely inside a playable area.
        -- E.g. player spawn points
        for _, ent in pairs(ents.FindByClass("info_player_*")) do
            spawnPoints[ent:GetPos()] = true
        end
    elseif playerSpawnsActive then
        -- After the first round, player positions have been recorded, so the player spawn gun spawns
        -- are no longer needed
        -- (4 guns are forcibly spawned around each player every round regardless)
        for _, ent in pairs(ents.FindByClass("info_player_*")) do
            spawnPoints[ent:GetPos()] = nil
        end

        playerSpawnsActive = false
    end

    -- Get the positions of players from round prep to begin to find potential gun spawn points inside the map
    timer.Create("FWGGetSpawnPoints", 1, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local pos = ply:GetPos()

            if ply:Alive() and not ply:IsSpec() and ply:OnGround() then
                spawnPoints[pos] = true
            end
        end
    end)

    -- Spawning guns and ammo on the ground
    timer.Create("FWGSpawnWeapons", spawnDelayCvar:GetFloat(), 1, function()
        if not modActiveCvar:GetBool() or not spawnCvar:GetBool() then return end
        local entityLimit = entityLimitCvar:GetInt()

        -- If there are more guns than ammo boxes on the map, spawn an ammo box next to every gun
        if ammoGunRatio < 1 then
            for pos, ammoEnt in pairs(floorWeaponPositions) do
                if entityCount >= entityLimit then return end
                PlaceAmmo(ammoEnt, pos, 1)
            end
        end

        local playerCount = 0
        local noNearGunPlys = {}
        local nearPlayerGunsCount = spawnNearCvar:GetInt()

        -- Checking for players that are not nearby a gun
        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() and not ply:IsSpec() then
                playerCount = playerCount + 1
            end

            if nearPlayerGunsCount > 0 then
                local skipPly = false

                for _, ent in ipairs(ents.FindInSphere(ply:GetPos(), 250)) do
                    if ent.AutoSpawnable and not ent.AmmoType then
                        skipPly = true
                        break
                    end
                end

                if not skipPly then
                    table.insert(noNearGunPlys, ply)
                end
            end
        end

        -- Force-spawning guns near players that are not nearby a gun (ignoring the gun-per-player cap below)
        if nearPlayerGunsCount > 0 then
            local gunOffset = 150

            local offsets = {Vector(gunOffset, 0, 0), Vector(-gunOffset, 0, 0), Vector(0, gunOffset, 0), Vector(0, -gunOffset, 0)}

            for _, ply in ipairs(noNearGunPlys) do
                if entityCount >= entityLimit then return end
                local plyPos = ply:GetPos()

                for i = 1, nearPlayerGunsCount do
                    PlaceWeapon(table.Random(floorWeapons), plyPos + offsets[i])
                end
            end
        end

        -- Take into account the number of guns already on the map as well, don't spawn any more if there are enough already
        local spawnCap = gunSpawnCvar:GetInt() * playerCount
        local spawnCount = gunCount

        -- Spawn guns!
        for pos, _ in RandomPairs(spawnPoints) do
            if spawnCount >= spawnCap or entityCount >= entityLimit then return end
            PlaceWeapon(table.Random(floorWeapons), pos)
            spawnCount = spawnCount + 1
        end
    end)
end)

hook.Add("TTTBeginRound", "FWGGiveWeapons", function()
    timer.Remove("FWGGetSpawnPoints")

    -- Giving floor weapons to players
    timer.Create("FWGGiveWeapons", giveDelayCvar:GetFloat(), 1, function()
        if not modActiveCvar:GetBool() or not giverCvar:GetBool() or (Randomat and isfunction(Randomat.IsEventActive) and Randomat:IsEventActive("murder")) then return end

        for i, ply in ipairs(player.GetAll()) do
            local hasPistol = false
            local hasHeavy = false
            local boxNumber = giveAmmoCvar:GetInt()

            for j, wep in ipairs(ply:GetWeapons()) do
                if wep.Kind == WEAPON_PISTOL then
                    hasPistol = true
                elseif wep.Kind == WEAPON_HEAVY then
                    hasHeavy = true
                end
            end

            if not hasPistol then
                local randWepPistol = autoSpawnPistols[math.random(1, #autoSpawnPistols)]
                ply:Give(randWepPistol.ClassName)
                DirectGiveAmmoBoxes(ply, randWepPistol.ClassName, boxNumber)
            end

            if not hasHeavy then
                local randWepHeavy = autoSpawnHeavyWeps[math.random(1, #autoSpawnHeavyWeps)]
                ply:Give(randWepHeavy.ClassName)
                DirectGiveAmmoBoxes(ply, randWepHeavy.ClassName, boxNumber)
            end
        end
    end)
end)

-- Stopping floor weapons from being given if the round ends before they are given
hook.Add("TTTEndRound", "FWGStopWeapons", function()
    timer.Remove("FWGGiveWeapons")
    timer.Remove("FWGSpawnWeapons")
end)