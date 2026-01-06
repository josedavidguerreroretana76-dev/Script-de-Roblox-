-- src/valjoe.lua
-- Módulo server-side para gestionar leaderstats y registrar kills de forma segura.
-- Diseñado para ejecutarse desde ServerScriptService o llamado por scripts del servidor.

local ValJoe = {}

local MAX_RANGE = 20 -- distancia máxima (studs) para validar un kill

-- Inicializa leaderstats para cada jugador (llamar solo una vez desde un Script en el servidor)
function ValJoe.Init()
    game.Players.PlayerAdded:Connect(function(player)
        local ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = player

        local kills = Instance.new("IntValue")
        kills.Name = "Kills"
        kills.Value = 0
        kills.Parent = ls
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
    if not attackerPlayer or not victimModel then return false end
    local victimHum = victimModel:FindFirstChildWhichIsA("Humanoid")
    if not victimHum or victimHum.Health <= 0 then return false end

    local victimPlayer = game.Players:GetPlayerFromCharacter(victimModel)
    if not victimPlayer or victimPlayer == attackerPlayer then return false end

    local atkChar = attackerPlayer.Character
    if not atkChar then return false end

    local atkRoot = atkChar:FindFirstChild("HumanoidRootPart")
    local vicRoot = victimModel:FindFirstChild("HumanoidRootPart")
    if not atkRoot or not vicRoot then return false end

    if (atkRoot.Position - vicRoot.Position).Magnitude > MAX_RANGE then return false end

    -- Aplicar la "muerte" en el servidor
    victimHum.Health = 0

    -- Registrar kill
    ValJoe.RegisterKill(attackerPlayer)
    return true
end

return ValJoe
