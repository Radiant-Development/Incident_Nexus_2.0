IncidentNexusWarningLights = IncidentNexusWarningLights or {}

local WarningLights = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s WarningLights] %s'):format(Config.DisplayName, message))
    end
end

local function isPoleType(lightType)
    return lightType == 'traffic_light'
end

function IncidentNexusWarningLights:RegisterLight(id, stationId, entity, mode, lightType)
    if not id or not entity or not DoesEntityExist(entity) then
        return
    end

    WarningLights[id] = {
        id = id,
        stationId = stationId or 'unknown_station',
        entity = entity,
        mode = mode or 'idle',
        type = lightType or 'warning_light',
        visible = true,
        lastToggle = GetGameTimer()
    }

    debugPrint(('Registered light %s for station %s (%s)'):format(id, stationId or 'unknown_station', lightType or 'warning_light'))
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

    local entity = WarningLights[id].entity
    if not entity or not DoesEntityExist(entity) then
        return
    end

    if mode == 'off' then
        if not isPoleType(WarningLights[id].type) then
            SetEntityVisible(entity, false, false)
        end
    else
        SetEntityVisible(entity, true, false)

        if not isPoleType(WarningLights[id].type) then
            SetEntityAlpha(entity, 255, false)
        end
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

function IncidentNexusWarningLights:ClearAll()
    for _, data in pairs(WarningLights) do
        if data.entity and DoesEntityExist(data.entity) then
            ResetEntityAlpha(data.entity)
            SetEntityVisible(data.entity, true, false)
        end
    end

    WarningLights = {}
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
                local glowX = coords.x
                local glowY = coords.y
                local glowZ = coords.z + 1.5

                if data.type == 'traffic_light' then
                    glowZ = coords.z + 3.5
                end

                if data.mode == 'idle' then
                    if now - data.lastToggle >= 400 then
                        data.visible = not data.visible
                        data.lastToggle = now

                        if not isPoleType(data.type) then
                            if data.visible then
                                SetEntityAlpha(entity, 255, false)
                            else
                                SetEntityAlpha(entity, 80, false)
                            end
                        end
                    end

                    if data.visible then
                        DrawLightWithRange(
                            glowX, glowY, glowZ,
                            255, 180, 0,
                            3.5,
                            2.5
                        )
                    end

                elseif data.mode == 'alert' then
                    SetEntityVisible(entity, true, false)

                    if not isPoleType(data.type) then
                        SetEntityAlpha(entity, 255, false)
                    end

                    DrawLightWithRange(
                        glowX, glowY, glowZ,
                        255, 0, 0,
                        4.5,
                        3.5
                    )

                elseif data.mode == 'off' then
                    if not isPoleType(data.type) then
                        SetEntityVisible(entity, false, false)
                    end
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