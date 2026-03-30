local BuilderActive = false
local BuilderState = {
    stationId = "station_01",
    stationName = "New Station"
}

local function notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(msg)
    DrawNotification(false, false)
end

local function isFirstPerson()
    return GetFollowPedCamViewMode() == 4
end

RegisterCommand('incidentbuilder', function()
    BuilderActive = not BuilderActive

    if BuilderActive then
        notify("Incident Nexus Builder Enabled")
    else
        notify("Incident Nexus Builder Disabled")

        if IncidentNexusProps then
            IncidentNexusProps:HideBuilderPlacedProps()
            IncidentNexusProps:SetActive(false)
        end

        if IncidentNexusDoors then
            IncidentNexusDoors:SetActive(false)
        end
    end
end, false)

RegisterCommand('nexussetname', function(_, args)
    local name = table.concat(args, " ")

    if name == "" then
        notify("Usage: /nexussetname Station Name")
        return
    end

    BuilderState.stationName = name
    BuilderState.stationId = name:gsub(" ", "_"):lower()

    notify(("Station set to %s"):format(BuilderState.stationName))
end, false)

RegisterCommand('nexustest', function()
    TriggerServerEvent('incident-nexus:server:testAlert', BuilderState.stationId)
end, false)

RegisterCommand('nexusclear', function()
    TriggerServerEvent('incident-nexus:server:clearAlert', BuilderState.stationId)
end, false)

RegisterCommand('nexusscreenidle', function()
    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationIdle(BuilderState.stationId)
    end
    notify("Screen set to idle")
end, false)

RegisterCommand('nexusscreenalert', function(_, args)
    local title = args[1] or "STRUCTURE FIRE"
    local message = table.concat(args, " ", 2)

    if message == "" then
        message = "Units respond immediately"
    end

    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationAlert(BuilderState.stationId, title, message)
    end
end, false)

RegisterCommand('nexusamber', function()
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(BuilderState.stationId, 'idle')
    end
end, false)

RegisterCommand('nexusred', function()
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(BuilderState.stationId, 'alert')
    end
end, false)

RegisterCommand('nexuslightsoff', function()
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(BuilderState.stationId, 'off')
    end
end, false)

RegisterNetEvent('incident-nexus:client:testAlert', function(stationId)
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(stationId, 'alert')
    end

    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationAlert(
            stationId,
            "STRUCTURE FIRE",
            "Units respond immediately"
        )
    end
end)

RegisterNetEvent('incident-nexus:client:receiveStations', function(stations)
    print(("[Incident Nexus] Received %s stations from server"):format(#(stations or {})))

    if IncidentNexusProps then
        IncidentNexusProps:LoadStations(stations or {})
    end
end)

RegisterNetEvent('incident-nexus:client:receiveDrafts', function(drafts)
    print("[Incident Nexus] Received drafts:", #(drafts or {}))
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('incident-nexus:server:requestStations')
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if BuilderActive then
            sleep = 0

            DisableControlAction(0, 37, true)
            DisablePlayerFiring(PlayerId(), true)

            if not isFirstPerson() then
                SetTextFont(4)
                SetTextScale(0.35, 0.35)
                SetTextColour(255, 0, 0, 255)
                SetTextCentre(true)

                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName("You must be in First Person to use builder")
                EndTextCommandDisplayText(0.5, 0.90)
            end
        end

        Wait(sleep)
    end
end)