-- src/valjoe.lua
-- Módulo server-side para gestionar leaderstats y registrar kills de forma segura.
-- Diseñado para ejecutarse desde ServerScriptService o llamado por scripts del servidor.

local ValJoe = {}

local MAX_RANGE = 20 -- distancia máxima (studs) para validar un kill

-- Inicializa leaderstats para cada jugador (llamar solo una vez desde un Script en el servidor)
local function ensureLeaderstats(player)
    if not player:FindFirstChild("leaderstats") then
        local ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player

        local kills = Instance.new("IntValue")
        kills.Name = "Kills"
        kills.Value = 0
        kills.Parent = ls
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

-- Incrementa el contador de kills de un jugador (seguro)
function ValJoe.RegisterKill(player)
    if not player or not player:IsA("Player") then return end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return end
    local kv = ls:FindFirstChild("Kills")
    if kv and kv:IsA("IntValue") then
        kv.Value = kv.Value + 1
    end
end

-- Intenta "matar" a victimModel por attackerPlayer con comprobaciones de servidor
-- Devuelve true si se aplicó la muerte y se registró la kill
function ValJoe.TryKill(attackerPlayer, victimModel)
    -- Validaciones de tipo y existencia
    if typeof(attackerPlayer) ~= "Instance" or not attackerPlayer:IsA("Player") then
        return false
    end
    if typeof(victimModel) ~= "Instance" or not victimModel:IsA("Model") then
        return false
    end

    -- comprobar Humanoid válido
    local victimHum = victimModel:FindFirstChildWhichIsA("Humanoid")
    if not victimHum or victimHum.Health <= 0 then
        return false
    end

    -- comprobar que la víctima corresponde a un Player distinto
    local victimPlayer = game.Players:GetPlayerFromCharacter(victimModel)
    if not victimPlayer or victimPlayer == attackerPlayer then
        return false
    end

    -- comprobar Character del atacante
    local atkChar = attackerPlayer.Character
    if not atkChar or not atkChar:IsA("Model") then
        return false
    end

    -- comprobar partes raíz
    local atkRoot = atkChar:FindFirstChild("HumanoidRootPart")
    local vicRoot = victimModel:FindFirstChild("HumanoidRootPart")
    if not atkRoot or not vicRoot then
        return false
    end

    -- distancia máxima
    if (atkRoot.Position - vicRoot.Position).Magnitude > MAX_RANGE then
        return false
    end

    -- aplicar muerte y registrar kill
    victimHum.Health = 0
    ValJoe.RegisterKill(attackerPlayer)
    return true
end

return ValJoe
