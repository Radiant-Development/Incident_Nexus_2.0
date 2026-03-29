IncidentNexusWarningLights = IncidentNexusWarningLights or {}

local WarningLights = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s WarningLights] %s'):format(Config.DisplayName, message))
    end
end

function IncidentNexusWarningLights:RegisterLight(id, stationId, entity, mode)
    if not id or not entity or not DoesEntityExist(entity) then
        return
    end

    WarningLights[id] = {
        id = id,
        stationId = stationId or 'unknown_station',
        entity = entity,
        mode = mode or 'idle',
        visible = true,
        lastToggle = GetGameTimer()
    }

    debugPrint(('Registered light %s for station %s'):format(id, stationId or 'unknown_station'))
end

function IncidentNexusWarningLights:RemoveLight(id)
    if WarningLights[id] then
        WarningLights[id] = nil
    end
end

function IncidentNexusWarningLights:SetMode(id, mode)
    if not WarningLights[id] then
        return
    end

    WarningLights[id].mode = mode
    WarningLights[id].lastToggle = GetGameTimer()

    if mode == 'off' then
        SetEntityVisible(WarningLights[id].entity, false, false)
    else
        SetEntityVisible(WarningLights[id].entity, true, false)
        SetEntityAlpha(WarningLights[id].entity, 255, false)
    end
end

function IncidentNexusWarningLights:SetStationMode(stationId, mode)
    for id, data in pairs(WarningLights) do
        if data.stationId == stationId then
            self:SetMode(id, mode)
        end
    end
end

function IncidentNexusWarningLights:SetAllModes(mode)
    for id, _ in pairs(WarningLights) do
        self:SetMode(id, mode)
    end
end

CreateThread(function()
    while true do
        local sleep = 500
        local now = GetGameTimer()

        for _, data in pairs(WarningLights) do
            local entity = data.entity

            if entity and DoesEntityExist(entity) then
                sleep = 0

                local coords = GetEntityCoords(entity)

                if data.mode == 'idle' then
                    if now - data.lastToggle >= 400 then
                        data.visible = not data.visible
                        data.lastToggle = now

                        if data.visible then
                            SetEntityAlpha(entity, 255, false)
                        else
                            SetEntityAlpha(entity, 80, false)
                        end
                    end

                    if data.visible then
                        DrawLightWithRange(
                            coords.x, coords.y, coords.z + 0.15,
                            255, 180, 0,
                            3.0,
                            2.0
                        )
                    end

                elseif data.mode == 'alert' then
                    SetEntityVisible(entity, true, false)
                    SetEntityAlpha(entity, 255, false)

                    DrawLightWithRange(
                        coords.x, coords.y, coords.z + 0.15,
                        255, 0, 0,
                        4.0,
                        3.0
                    )

                elseif data.mode == 'off' then
                    SetEntityVisible(entity, false, false)
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('incident-nexus:client:setWarningLightMode', function(id, mode)
    IncidentNexusWarningLights:SetMode(id, mode)
end)

RegisterNetEvent('incident-nexus:client:setStationWarningLightMode', function(stationId, mode)
    IncidentNexusWarningLights:SetStationMode(stationId, mode)
end)

RegisterNetEvent('incident-nexus:client:setAllWarningLightModes', function(mode)
    IncidentNexusWarningLights:SetAllModes(mode)
end)