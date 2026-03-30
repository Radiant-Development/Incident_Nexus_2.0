IncidentNexusScreens = IncidentNexusScreens or {}

local Screens = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s Screens] %s'):format(Config.DisplayName, message))
    end
end

local function drawScreenText(x, y, z, text, scale)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(scale or 0.18, scale or 0.18)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function drawScreenBackground(x, y, z, heading, mode)
    local r, g, b, a = 10, 20, 35, 220

    if mode == 'alert' then
        r, g, b, a = 120, 0, 0, 235
    end

    DrawMarker(
        43,
        x, y, z,
        0.0, 0.0, 0.0,
        90.0, 0.0, heading,
        0.42, 0.24, 0.001,
        r, g, b, a,
        false, false, 2, false, nil, nil, false
    )
end

function IncidentNexusScreens:RegisterScreen(id, stationId, entity)
    if not id or not entity or not DoesEntityExist(entity) then
        return
    end

    Screens[id] = {
        id = id,
        stationId = stationId or 'unknown_station',
        entity = entity,
        mode = 'idle',
        title = 'STATION STANDBY',
        message = 'No active alerts'
    }

    debugPrint(('Registered screen %s for station %s'):format(id, stationId or 'unknown_station'))
end

function IncidentNexusScreens:RemoveScreen(id)
    Screens[id] = nil
end

function IncidentNexusScreens:ClearAll()
    Screens = {}
end

function IncidentNexusScreens:SetStationIdle(stationId)
    for _, screen in pairs(Screens) do
        if screen.stationId == stationId then
            screen.mode = 'idle'
            screen.title = 'STATION STANDBY'
            screen.message = 'No active alerts'
        end
    end
end

function IncidentNexusScreens:SetStationAlert(stationId, title, message)
    for _, screen in pairs(Screens) do
        if screen.stationId == stationId then
            screen.mode = 'alert'
            screen.title = title or 'ACTIVE ALERT'
            screen.message = message or 'Units respond immediately'
        end
    end
end

function IncidentNexusScreens:SetAllIdle()
    for _, screen in pairs(Screens) do
        screen.mode = 'idle'
        screen.title = 'STATION STANDBY'
        screen.message = 'No active alerts'
    end
end

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)

        for _, screen in pairs(Screens) do
            if screen.entity and DoesEntityExist(screen.entity) then
                local coords = GetEntityCoords(screen.entity)
                local dist = #(pedCoords - coords)

                if dist <= 35.0 then
                    sleep = 0

                    local forward = GetEntityForwardVector(screen.entity)
                    local heading = GetEntityHeading(screen.entity)

                    local screenX = coords.x + (forward.x * 0.06)
                    local screenY = coords.y + (forward.y * 0.06)
                    local screenZ = coords.z + 0.28

                    drawScreenBackground(screenX, screenY, screenZ, heading, screen.mode)

                    if screen.mode == 'idle' then
                        drawScreenText(screenX, screenY, screenZ + 0.045, 'INCIDENT NEXUS', 0.20)
                        drawScreenText(screenX, screenY, screenZ + 0.010, 'STATION STANDBY', 0.16)
                        drawScreenText(screenX, screenY, screenZ - 0.025, 'No active alerts', 0.14)
                    elseif screen.mode == 'alert' then
                        drawScreenText(screenX, screenY, screenZ + 0.045, 'ACTIVE ALERT', 0.20)
                        drawScreenText(screenX, screenY, screenZ + 0.010, screen.title or 'Dispatch Alert', 0.16)
                        drawScreenText(screenX, screenY, screenZ - 0.025, screen.message or 'Units respond immediately', 0.14)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('incident-nexus:client:setStationScreenIdle', function(stationId)
    IncidentNexusScreens:SetStationIdle(stationId)
end)

RegisterNetEvent('incident-nexus:client:setStationScreenAlert', function(stationId, title, message)
    IncidentNexusScreens:SetStationAlert(stationId, title, message)
end)