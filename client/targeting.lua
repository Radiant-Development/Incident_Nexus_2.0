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

-- =============================
-- Builder Toggle
-- =============================

RegisterCommand('incidentbuilder', function()
    BuilderActive = not BuilderActive

    if BuilderActive then
        notify("Incident Nexus Builder Enabled")
    else
        notify("Incident Nexus Builder Disabled")

        if HideBuilderPlacedProps then
            HideBuilderPlacedProps()
        end
    end
end, false)

-- =============================
-- Set Station Name
-- =============================

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

-- =============================
-- Alert Commands
-- =============================

RegisterCommand('nexustest', function()

    TriggerServerEvent(
        'incident-nexus:server:testAlert',
        BuilderState.stationId
    )

end, false)

RegisterCommand('nexusclear', function()

    TriggerServerEvent(
        'incident-nexus:server:clearAlert',
        BuilderState.stationId
    )

end, false)

-- =============================
-- Screen Commands
-- =============================

RegisterCommand('nexusscreenidle', function()

    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationIdle(
            BuilderState.stationId
        )
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
        IncidentNexusScreens:SetStationAlert(
            BuilderState.stationId,
            title,
            message
        )
    end

end, false)

-- =============================
-- Warning Light Commands
-- =============================

RegisterCommand('nexusamber', function()

    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(
            BuilderState.stationId,
            'idle'
        )
    end

end, false)

RegisterCommand('nexusred', function()

    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(
            BuilderState.stationId,
            'alert'
        )
    end

end, false)

RegisterCommand('nexuslightsoff', function()

    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(
            BuilderState.stationId,
            'off'
        )
    end

end, false)

-- =============================
-- Receive Server Events
-- =============================

RegisterNetEvent('incident-nexus:client:testAlert', function(stationId)

    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(
            stationId,
            'alert'
        )
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

    if LoadStations then
        LoadStations(stations)
    end

end)

RegisterNetEvent('incident-nexus:client:receiveDrafts', function(drafts)

    -- optional debug
    print("[Incident Nexus] Received drafts:", #drafts)

end)

-- =============================
-- Request Data
-- =============================

CreateThread(function()

    Wait(1500)

    TriggerServerEvent(
        'incident-nexus:server:requestStations'
    )

end)

-- =============================
-- First Person Requirement
-- =============================

local function isFirstPerson()
    return GetFollowPedCamViewMode() == 4
end

-- =============================
-- Builder Loop
-- =============================

CreateThread(function()

    while true do

        local sleep = 1000

        if BuilderActive then

            sleep = 0

            DisableControlAction(0, 37, true)
            DisablePlayerFiring(PlayerPedId(), true)

            if not isFirstPerson() then

                SetTextFont(4)
                SetTextScale(0.35, 0.35)
                SetTextColour(255, 0, 0, 255)
                SetTextCentre(true)

                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(
                    "You must be in First Person to use builder"
                )

                EndTextCommandDisplayText(0.5, 0.90)

            end

        end

        Wait(sleep)

    end

end)