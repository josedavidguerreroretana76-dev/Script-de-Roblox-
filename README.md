loadstring(gamemusclelegends:-- valjoe.module.lua
-- Módulo server-side adaptado a Muscle Legends:
-- leaderstats: Kills, Strength, Level, XP
-- Al matar a un jugador: Kills +=1, Strength += 5 + floor(victim.Strength * 0.1), XP += 10
-- Al alcanzar XP >= 100: Level +=1, XP -=100, Strength += 10

local ValJoe = {}

local MAX_RANGE = 20 -- studs
local XP_PER_KILL = 10
local BASE_STRENGTH_PER_KILL = 5
local LEVEL_XP_THRESHOLD = 100
local LEVEL_BONUS_STRENGTH = 10

-- asegura leaderstats con las stats necesarias
local function ensureLeaderstats(player)
    if not player:FindFirstChild("leaderstats") then
        local ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player

        local kills = Instance.new("IntValue")
        kills.Name = "Kills"
        kills.Value = 0
        kills.Parent = ls

        local strength = Instance.new("IntValue")
        strength.Name = "Strength"
        strength.Value = 0
        strength.Parent = ls

        local level = Instance.new("IntValue")
        level.Name = "Level"
        level.Value = 1
        level.Parent = ls

        local xp = Instance.new("IntValue")
        xp.Name = "XP"
        xp.Value = 0
        xp.Parent = ls
    else
        local ls = player.leaderstats
        if not ls:FindFirstChild("Kills") then
            local v = Instance.new("IntValue"); v.Name = "Kills"; v.Value = 0; v.Parent = ls
        end
        if not ls:FindFirstChild("Strength") then
            local v = Instance.new("IntValue"); v.Name = "Strength"; v.Value = 0; v.Parent = ls
        end
        if not ls:FindFirstChild("Level") then
            local v = Instance.new("IntValue"); v.Name = "Level"; v.Value = 1; v.Parent = ls
        end
        if not ls:FindFirstChild("XP") then
            local v = Instance.new("IntValue"); v.Name = "XP"; v.Value = 0; v.Parent = ls
        end
    end
end

function ValJoe.Init()
    -- Asegurar leaderstats para jugadores ya conectados
    for _, player in pairs(game.Players:GetPlayers()) do
        ensureLeaderstats(player)
    end
    game.Players.PlayerAdded:Connect(function(player)
        ensureLeaderstats(player)
    end)
end

local function awardRewards(attackerPlayer, victimPlayer)
    if not attackerPlayer or not attackerPlayer:IsA("Player") then return end
    if not victimPlayer or not victimPlayer:IsA("Player") then return end

    local atkLS = attackerPlayer:FindFirstChild("leaderstats")
    local vicLS = victimPlayer:FindFirstChild("leaderstats")
    if not atkLS or not vicLS then return end

    local atkKills = atkLS:FindFirstChild("Kills")
    local atkStrength = atkLS:FindFirstChild("Strength")
    local atkXP = atkLS:FindFirstChild("XP")
    local atkLevel = atkLS:FindFirstChild("Level")

    local vicStrength = vicLS:FindFirstChild("Strength")

    local vicStrVal = 0
    if vicStrength and vicStrength:IsA("IntValue") then
        vicStrVal = vicStrength.Value
    end

    -- Kills
    if atkKills and atkKills:IsA("IntValue") then
        atkKills.Value = atkKills.Value + 1
    end

    -- Strength gain: base + 10% of victim strength (floored)
    if atkStrength and atkStrength:IsA("IntValue") then
        local gain = BASE_STRENGTH_PER_KILL + math.floor(vicStrVal * 0.1)
        atkStrength.Value = atkStrength.Value + gain
    end

    -- XP and level up
    if atkXP and atkXP:IsA("IntValue") and atkLevel and atkLevel:IsA("IntValue") then
        atkXP.Value = atkXP.Value + XP_PER_KILL
        while atkXP.Value >= LEVEL_XP_THRESHOLD do
            atkXP.Value = atkXP.Value - LEVEL_XP_THRESHOLD
            atkLevel.Value = atkLevel.Value + 1
            if atkStrength and atkStrength:IsA("IntValue") then
                atkStrength.Value = atkStrength.Value + LEVEL_BONUS_STRENGTH
            end
        end
    end
end

-- Intenta matar a victimModel por attackerPlayer con comprobaciones de servidor
-- Devuelve true si se aplicó la muerte y se registró la kill/recompensas
function ValJoe.TryKill(attackerPlayer, victimModel)
    -- Validaciones
    if typeof(attackerPlayer) ~= "Instance" or not attackerPlayer:IsA("Player") then
        return false
    end
    if typeof(victimModel) ~= "Instance" or not victimModel:IsA("Model") then
        return false
    end

    local victimHum = victimModel:FindFirstChildWhichIsA("Humanoid")
    if not victimHum or victimHum.Health <= 0 then
        return false
    end

    local victimPlayer = game.Players:GetPlayerFromCharacter(victimModel)
    if not victimPlayer or victimPlayer == attackerPlayer then
        return false
    end

    local atkChar = attackerPlayer.Character
    if not atkChar or not atkChar:IsA("Model") then
        return false
    end

    local atkRoot = atkChar:FindFirstChild("HumanoidRootPart")
    local vicRoot = victimModel:FindFirstChild("HumanoidRootPart")
    if not atkRoot or not vicRoot then
        return false
    end

    if (atkRoot.Position - vicRoot.Position).Magnitude > MAX_RANGE then
        return false
    end

    -- Aplicar la muerte (servidor)
    victimHum.Health = 0

    -- Asegurar leaderstats antes de otorgar recompensas
    ensureLeaderstats(attackerPlayer)
    ensureLeaderstats(victimPlayer)

    -- Otorgar recompensas (Kills, Strength, XP/Level)
    awardRewards(attackerPlayer, victimPlayer)

    return true
end

return ValJoe))()