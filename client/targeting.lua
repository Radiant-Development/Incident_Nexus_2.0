print('[Incident Nexus] targeting.lua loaded')

local BuilderActive = false
local CachedStations = {}
local CachedDrafts = {}

local BuilderState = {
    stationName = Config.DefaultStation.name or 'New Station',
    stationId = 'new_station',
    departmentIndex = 1,
    stationTypeIndex = 1,
    modeIndex = 1,
    DoorEditField = 'name'
}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s] %s'):format(Config.DisplayName or 'Incident Nexus', message))
    end
end

local function notify(message)
    print(('[%s] %s'):format(Config.DisplayName or 'Incident Nexus', message))
end

local function sanitizeName(name)
    local safe = tostring(name or 'station')
    safe = safe:lower()
    safe = safe:gsub('[^%w%s_-]', '')
    safe = safe:gsub('%s+', '_')
    safe = safe:gsub('_+', '_')
    safe = safe:gsub('^_+', '')
    safe = safe:gsub('_+$', '')

    if safe == '' then
        safe = 'station'
    end

    return safe
end

local function setStationName(name)
    if not name or name == '' then
        notify('Usage: /' .. (Config.Commands.SetStationName or 'nexussetname') .. ' [station name]')
        return
    end

    BuilderState.stationName = name
    BuilderState.stationId = sanitizeName(name)

    notify(('Builder station set to %s (%s)'):format(BuilderState.stationName, BuilderState.stationId))
end

local function drawText2D(x, y, text, scale, r, g, b, a)
    SetTextFont(4)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextColour(r or 255, g or 255, b or 255, a or 215)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawText3D(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

local function isFirstPerson()
    return GetFollowPedCamViewMode() == 4
end

local function disableBuilderControls()
    DisablePlayerFiring(PlayerId(), true)
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 25, true)
    DisableControlAction(0, 37, true)
    DisableControlAction(0, 44, true)
    DisableControlAction(0, 45, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 143, true)
    DisableControlAction(0, 257, true)
    DisableControlAction(0, 263, true)
    DisableControlAction(0, 264, true)
end

local function hideBuilderWeapons()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    HideHudComponentThisFrame(19)
    HideHudComponentThisFrame(20)
end

local function currentDepartment()
    return (Config.Departments and Config.Departments[BuilderState.departmentIndex]) or 'fire'
end

local function currentStationType()
    return (Config.StationTypes and Config.StationTypes[BuilderState.stationTypeIndex]) or 'fire_station'
end

local function currentMode()
    return (Config.BuilderModes and Config.BuilderModes[BuilderState.modeIndex]) or 'place_prop'
end

local function setModeActivity()
    local mode = currentMode()
    local allowInteraction = BuilderActive and isFirstPerson()

    if IncidentNexusProps then
        IncidentNexusProps:SetActive(allowInteraction and (mode == 'place_prop' or mode == 'hide_prop'))
    end

    if IncidentNexusDoors then
        IncidentNexusDoors:SetActive(allowInteraction and mode == 'select_door')
    end
end

local function toggleBuilder()
    BuilderActive = not BuilderActive

    if BuilderActive then
        notify('Builder enabled.')
        TriggerServerEvent('incident-nexus:server:requestStations')
        TriggerServerEvent('incident-nexus:server:requestDrafts')
    else
        notify('Builder disabled.')
        if IncidentNexusProps then
            IncidentNexusProps:HideBuilderPlacedProps()
            IncidentNexusProps:SetActive(false)
        end
        if IncidentNexusDoors then
            IncidentNexusDoors:SetActive(false)
        end
    end

    setModeActivity()
end

local function cycleBuilderMode(forward)
    if not Config.BuilderModes or #Config.BuilderModes == 0 then
        return
    end

    if forward then
        BuilderState.modeIndex = BuilderState.modeIndex + 1
        if BuilderState.modeIndex > #Config.BuilderModes then
            BuilderState.modeIndex = 1
        end
    else
        BuilderState.modeIndex = BuilderState.modeIndex - 1
        if BuilderState.modeIndex < 1 then
            BuilderState.modeIndex = #Config.BuilderModes
        end
    end

    setModeActivity()
end

local function createDraft()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local stationData = {
        id = BuilderState.stationId,
        fileName = BuilderState.stationId,
        name = BuilderState.stationName,
        department = currentDepartment(),
        stationType = currentStationType(),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        heading = heading,
        props = IncidentNexusProps and IncidentNexusProps:GetPlacedPropsForExport() or {},
        hiddenProps = IncidentNexusProps and IncidentNexusProps:GetHiddenPropsForExport() or {},
        doors = IncidentNexusDoors and IncidentNexusDoors:GetDoorsForExport() or {},
        traffic = {},
        screens = {},
        computers = {},
        warningLights = {}
    }

    TriggerServerEvent('incident-nexus:server:createStationDraft', stationData)
end

local function handleConfirm()
    local mode = currentMode()

    if mode == 'place_prop' and IncidentNexusProps then
        IncidentNexusProps:Confirm(BuilderState.stationId)
    elseif mode == 'hide_prop' and IncidentNexusProps then
        IncidentNexusProps:Hide()
    elseif mode == 'select_door' and IncidentNexusDoors then
        IncidentNexusDoors:ConfirmSelect()
    end
end

local function handleCancel()
    local mode = currentMode()

    if (mode == 'place_prop' or mode == 'hide_prop') and IncidentNexusProps then
        IncidentNexusProps:Cancel()
    elseif mode == 'select_door' and IncidentNexusDoors then
        IncidentNexusDoors:RemoveLastSelected()
    end
end

local function handleScroll(forward)
    local mode = currentMode()

    if mode == 'place_prop' and IncidentNexusProps then
        IncidentNexusProps:Cycle(forward)
    elseif mode == 'hide_prop' then
        cycleBuilderMode(forward)
    elseif mode == 'select_door' and IncidentNexusDoors then
        if BuilderState.DoorEditField == 'name' then
            IncidentNexusDoors:CycleDoorName(forward)
        else
            IncidentNexusDoors:CycleApparatus(forward)
        end
    end
end

local function drawBuilderMenu()
    drawText2D(0.02, 0.08, 'Incident Nexus Builder', 0.45)
    drawText2D(0.02, 0.115, ('Station Name: %s'):format(BuilderState.stationName), 0.34)
    drawText2D(0.02, 0.145, ('Station ID: %s'):format(BuilderState.stationId), 0.34)
    drawText2D(0.02, 0.175, ('Department: %s'):format(currentDepartment()), 0.34)
    drawText2D(0.02, 0.205, ('Station Type: %s'):format(currentStationType()), 0.34)
    drawText2D(0.02, 0.235, ('Mode: %s'):format(currentMode()), 0.34)

    if not isFirstPerson() then
        drawText2D(0.02, 0.02, 'You need to be in first person to use builder', 0.42, 255, 80, 80, 255)
    end

    if currentMode() == 'place_prop' and IncidentNexusProps then
        drawText2D(0.02, 0.265, ('Selected Prop: %s'):format(IncidentNexusProps:GetCurrentLabel()), 0.34)
        drawText2D(0.02, 0.295, '[Mouse Wheel] Cycle Prop', 0.30)
        drawText2D(0.02, 0.320, '[Left/Right Arrow] Rotate Prop', 0.30)
    elseif currentMode() == 'select_door' and IncidentNexusDoors then
        drawText2D(0.02, 0.265, ('Selected Doors: %s'):format(IncidentNexusDoors:GetSelectedDoorCount()), 0.34)
        drawText2D(0.02, 0.295, ('Door Name: %s'):format(IncidentNexusDoors:GetCurrentDoorName()), 0.30)
        drawText2D(0.02, 0.320, ('Apparatus: %s'):format(IncidentNexusDoors:GetCurrentApparatus()), 0.30)
        drawText2D(0.02, 0.345, ('Editing: %s'):format(BuilderState.DoorEditField), 0.30)
        drawText2D(0.02, 0.370, '[Mouse Wheel] Cycle Name/Apparatus', 0.30)
        drawText2D(0.02, 0.395, '[/backin] toggles editor field', 0.30)
    else
        drawText2D(0.02, 0.295, '[Mouse Wheel] Cycle Builder Mode', 0.30)
    end

    drawText2D(0.02, 0.435, '[Left Click] Confirm / Place / Select', 0.30)
    drawText2D(0.02, 0.460, '[Right Click] Remove / Undo', 0.30)
    drawText2D(0.02, 0.485, '[E] Export Draft', 0.30)
    drawText2D(0.02, 0.510, ('[/%s] Set Station Name'):format(Config.Commands.SetStationName or 'nexussetname'), 0.30)
    drawText2D(0.02, 0.535, '[/incidentbuilder] Exit Builder', 0.30)
end

RegisterCommand(Config.Commands.Builder, function()
    toggleBuilder()
end, false)

RegisterCommand(Config.Commands.SetStationName, function(_, args)
    local name = table.concat(args or {}, ' ')
    setStationName(name)
end, false)

RegisterCommand(Config.Commands.TestAlert, function()
    TriggerServerEvent('incident-nexus:server:testAlert', BuilderState.stationId)
end, false)

RegisterCommand(Config.Commands.BayOpen, function()
    notify('Bay open command triggered.')
end, false)

RegisterCommand(Config.Commands.BackIn, function()
    if currentMode() ~= 'select_door' then
        notify('Back-in command triggered.')
        return
    end

    if BuilderState.DoorEditField == 'name' then
        BuilderState.DoorEditField = 'apparatus'
    else
        BuilderState.DoorEditField = 'name'
    end

    notify(('Door edit field: %s'):format(BuilderState.DoorEditField))
end, false)

RegisterCommand('nexusamber', function()
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(BuilderState.stationId, 'idle')
    end
    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationIdle(BuilderState.stationId)
    end
    notify(('Warning lights set to amber for station %s'):format(BuilderState.stationId))
end, false)

RegisterCommand('nexusred', function()
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(BuilderState.stationId, 'alert')
    end
    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationAlert(BuilderState.stationId, 'STRUCTURE FIRE', 'Units respond immediately')
    end
    notify(('Warning lights set to red for station %s'):format(BuilderState.stationId))
end, false)

RegisterCommand('nexuslightsoff', function()
    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(BuilderState.stationId, 'off')
    end
    notify(('Warning lights turned off for station %s'):format(BuilderState.stationId))
end, false)

RegisterCommand('nexusscreenidle', function()
    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationIdle(BuilderState.stationId)
    end
    notify(('Screen set to idle for station %s'):format(BuilderState.stationId))
end, false)

RegisterCommand('nexusscreenalert', function(_, args)
    local title = args[1] or 'STRUCTURE FIRE'
    local message = table.concat(args, ' ', 2)
    if message == '' then
        message = 'Units respond immediately'
    end

    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationAlert(BuilderState.stationId, title, message)
    end

    notify(('Screen alert set for station %s'):format(BuilderState.stationId))
end, false)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('incident-nexus:server:requestStations')
end)

CreateThread(function()
    while true do
        local sleep = 1000

        if BuilderActive then
            sleep = 0

            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local firstPerson = isFirstPerson()

            hideBuilderWeapons()
            disableBuilderControls()
            setModeActivity()

            drawText3D(coords.x, coords.y, coords.z + 1.0, 'Incident Nexus Builder')
            drawBuilderMenu()

            if firstPerson then
                local mode = currentMode()

                if (mode == 'place_prop' or mode == 'hide_prop') and IncidentNexusProps then
                    IncidentNexusProps:Update()
                elseif mode == 'select_door' and IncidentNexusDoors then
                    IncidentNexusDoors:Update()
                end

                if IsDisabledControlJustReleased(0, Config.Keys.ExportDraft) then
                    createDraft()
                end

                if IsDisabledControlJustReleased(0, Config.Keys.Confirm) then
                    handleConfirm()
                end

                if IsDisabledControlJustReleased(0, Config.Keys.Cancel) then
                    handleCancel()
                end

                if IsDisabledControlJustReleased(0, Config.Keys.ScrollUp) then
                    handleScroll(true)
                end

                if IsDisabledControlJustReleased(0, Config.Keys.ScrollDown) then
                    handleScroll(false)
                end

                if IsDisabledControlJustReleased(0, Config.Keys.RotateLeft) and currentMode() == 'place_prop' and IncidentNexusProps then
                    IncidentNexusProps:Rotate(false)
                end

                if IsDisabledControlJustReleased(0, Config.Keys.RotateRight) and currentMode() == 'place_prop' and IncidentNexusProps then
                    IncidentNexusProps:Rotate(true)
                end
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('incident-nexus:client:receiveStations', function(stations)
    CachedStations = stations or {}
    debugPrint(('Received %s stations.'):format(#CachedStations))

    if IncidentNexusProps then
        IncidentNexusProps:LoadStations(CachedStations)
    end
end)

RegisterNetEvent('incident-nexus:client:receiveDrafts', function(drafts)
    CachedDrafts = drafts or {}
    debugPrint(('Received %s drafts.'):format(#CachedDrafts))
end)

RegisterNetEvent('incident-nexus:client:testAlert', function(stationId)
    notify(('Test alert triggered for station: %s'):format(tostring(stationId)))

    if IncidentNexusWarningLights then
        IncidentNexusWarningLights:SetStationMode(stationId, 'alert')
    end

    if IncidentNexusScreens then
        IncidentNexusScreens:SetStationAlert(
            stationId,
            'STRUCTURE FIRE',
            'Units respond immediately'
        )
    end

    SendNUIMessage({
        action = 'showDispatch',
        title = 'Dispatch Alert',
        message = ('Tone-out triggered for %s'):format(tostring(stationId))
    })
end)

RegisterNetEvent('incident-nexus:client:notify', function(message)
    notify(message)
end)