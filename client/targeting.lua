local BuilderActive = false
local CachedStations = {}
local CachedDrafts = {}

local function DebugPrint(msg)
    if Config.Debug then
        print(("[Incident Nexus] %s"):format(msg))
    end
end

local function Notify(msg)
    print(("[Incident Nexus] %s"):format(msg))
end

local function DrawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function DrawBuilderMarker(coords)
    DrawMarker(
        1,
        coords.x,
        coords.y,
        coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.45, 0.45, 0.25,
        0, 150, 255, 125,
        false, false, 2, false, nil, nil, false
    )
end

local function ToggleBuilder()
    BuilderActive = not BuilderActive

    if BuilderActive then
        Notify("Builder enabled.")
    else
        Notify("Builder disabled.")
    end
end

local function CreateTestStation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local stationData = {
        name = Config.DefaultStation.name,
        department = Config.DefaultStation.department,
        stationType = Config.DefaultStation.stationType,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    }

    TriggerServerEvent('incident-nexus:server:createStation', stationData)
end

local function SaveTestDraft()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local draftData = {
        name = "Draft Station",
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        props = {},
        doors = {},
        traffic = {}
    }

    TriggerServerEvent('incident-nexus:server:saveDraft', draftData)
end

RegisterCommand(Config.BuilderCommand, function()
    ToggleBuilder()
end, false)

RegisterCommand(Config.TestCommand, function()
    TriggerServerEvent('incident-nexus:server:testAlert', "test_station")
end, false)

CreateThread(function()
    while true do
        local sleep = 1000

        if BuilderActive then
            sleep = 0

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)

            DrawBuilderMarker(coords)
            DrawText3D(coords.x, coords.y, coords.z + 1.0, "[Incident Nexus Builder]")

            if IsControlJustReleased(0, Config.InteractionKey) then
                CreateTestStation()
            end

            if IsControlJustReleased(0, 47) then -- G
                SaveTestDraft()
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('incident-nexus:client:receiveStations', function(stations)
    CachedStations = stations or {}
    DebugPrint(("Received %s stations from server."):format(type(CachedStations) == "table" and tostring(#CachedStations) or "unknown"))
end)

RegisterNetEvent('incident-nexus:client:receiveDrafts', function(drafts)
    CachedDrafts = drafts or {}
    DebugPrint("Received drafts from server.")
end)

RegisterNetEvent('incident-nexus:client:testAlert', function(stationId)
    Notify(("Test alert triggered for station: %s"):format(tostring(stationId)))
    SendNUIMessage({
        action = "showDispatch",
        stationId = stationId,
        title = "Test Alert",
        message = "Station tone-out triggered."
    })
end)

RegisterNetEvent('incident-nexus:client:notify', function(msg)
    Notify(msg)
end)