local BuilderActive = false
local CachedStations = {}
local CachedDrafts = {}

local BuilderState = {
    stationName = Config.DefaultStation.name,
    departmentIndex = 1,
    stationTypeIndex = 1,
    modeIndex = 1,
    DoorEditField = 'name'
}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s] %s'):format(Config.DisplayName, message))
    end
end

local function notify(message)
    print(('[%s] %s'):format(Config.DisplayName, message))
end

local function drawText2D(x, y, text, scale, r, g, b, a)
    SetTextFont(4)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextColour(r or 255, g or 255, b or 255, a or 215)
    SetTextCentre(false)
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

    DisableControlAction(0, 24, true)   -- left click attack
    DisableControlAction(0, 25, true)   -- right click aim
    DisableControlAction(0, 37, true)   -- weapon wheel
    DisableControlAction(0, 44, true)   -- cover
    DisableControlAction(0, 45, true)   -- reload
    DisableControlAction(0, 140, true)  -- melee light
    DisableControlAction(0, 141, true)  -- melee heavy
    DisableControlAction(0, 142, true)  -- melee alternate
    DisableControlAction(0, 143, true)  -- melee block
    DisableControlAction(0, 257, true)  -- attack 2
    DisableControlAction(0, 263, true)  -- melee attack 1
    DisableControlAction(0, 264, true)  -- melee attack 2
end

local function hideBuilderWeapons()
    local ped = PlayerPedId()
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    HideHudComponentThisFrame(19) -- weapon wheel
    HideHudComponentThisFrame(20) -- weapon display
end

local function currentDepartment()
    return Config.Departments[BuilderState.departmentIndex] or 'fire'
end

local function currentStationType()
    return Config.StationTypes[BuilderState.stationTypeIndex] or 'fire_station'
end

local function currentMode()
    return Config.BuilderModes[BuilderState.modeIndex] or 'place_prop'
end

local function setModeActivity()
    local mode = currentMode()
    local allowBuilderInteraction = BuilderActive and isFirstPerson()

    IncidentNexusProps:SetActive(allowBuilderInteraction and (mode == 'place_prop' or mode == 'hide_prop'))
    IncidentNexusDoors:SetActive(allowBuilderInteraction and mode == 'select_door')
end

local function toggleBuilder()
    BuilderActive = not BuilderActive

    if BuilderActive then
        notify('Builder enabled.')
        TriggerServerEvent('incident-nexus:server:requestStations')
        TriggerServerEvent('incident-nexus:server:requestDrafts')
    else
        notify('Builder disabled.')
    end

    setModeActivity()

    if not BuilderActive then
        IncidentNexusProps:SetActive(false)
        IncidentNexusDoors:SetActive(false)
    end
end

local function cycleBuilderMode(forward)
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
        id = nil,
        fileName = BuilderState.stationName,
        name = BuilderState.stationName,
        department = currentDepartment(),
        stationType = currentStationType(),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        heading = heading,
        props = IncidentNexusProps:GetPlacedPropsForExport(),
        hiddenProps = IncidentNexusProps:GetHiddenPropsForExport(),
        doors = IncidentNexusDoors:GetDoorsForExport(),
        traffic = {},
        screens = {},
        computers = {},
        warningLights = {}
    }

    TriggerServerEvent('incident-nexus:server:createStationDraft', stationData)
end

local function handleConfirm()
    local mode = currentMode()

    if mode == 'place_prop' then
        IncidentNexusProps:Confirm()
    elseif mode == 'hide_prop' then
        IncidentNexusProps:Hide()
    elseif mode == 'select_door' then
        IncidentNexusDoors:ConfirmSelect()
    end
end

local function handleCancel()
    local mode = currentMode()

    if mode == 'place_prop' then
        IncidentNexusProps:Cancel()
    elseif mode == 'hide_prop' then
        IncidentNexusProps:Cancel()
    elseif mode == 'select_door' then
        IncidentNexusDoors:RemoveLastSelected()
    end
end

local function handleScroll(forward)
    local mode = currentMode()

    if mode == 'place_prop' then
        IncidentNexusProps:Cycle(forward)
    elseif mode == 'hide_prop' then
        cycleBuilderMode(forward)
    elseif mode == 'select_door' then
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
    drawText2D(0.02, 0.145, ('Department: %s'):format(currentDepartment()), 0.34)
    drawText2D(0.02, 0.175, ('Station Type: %s'):format(currentStationType()), 0.34)
    drawText2D(0.02, 0.205, ('Mode: %s'):format(currentMode()), 0.34)

    if not isFirstPerson() then
        drawText2D(0.02, 0.02, 'You need to be in first person to use builder', 0.42, 255, 80, 80, 255)
    end

    if currentMode() == 'place_prop' then
        drawText2D(0.02, 0.235, ('Selected Prop: %s'):format(IncidentNexusProps:GetCurrentLabel()), 0.34)
        drawText2D(0.02, 0.265, '[Mouse Wheel] Cycle Prop', 0.30)
    elseif currentMode() == 'select_door' then
        drawText2D(0.02, 0.235, ('Selected Doors: %s'):format(IncidentNexusDoors:GetSelectedDoorCount()), 0.34)
        drawText2D(0.02, 0.265, ('Door Name: %s'):format(IncidentNexusDoors:GetCurrentDoorName()), 0.30)
        drawText2D(0.02, 0.290, ('Apparatus: %s'):format(IncidentNexusDoors:GetCurrentApparatus()), 0.30)
        drawText2D(0.02, 0.315, ('Editing: %s'):format(BuilderState.DoorEditField), 0.30)
        drawText2D(0.02, 0.340, '[Mouse Wheel] Cycle Name/Apparatus', 0.30)
        drawText2D(0.02, 0.365, '[/backin] toggles editor field', 0.30)
    else
        drawText2D(0.02, 0.265, '[Mouse Wheel] Cycle Builder Mode', 0.30)
    end

    drawText2D(0.02, 0.405, '[Left Click] Confirm / Place / Select', 0.30)
    drawText2D(0.02, 0.430, '[Right Click] Remove / Undo', 0.30)
    drawText2D(0.02, 0.455, '[E] Export Draft', 0.30)
    drawText2D(0.02, 0.480, '[/incidentbuilder] Exit Builder', 0.30)
end

RegisterCommand('nexusamber', function()
    IncidentNexusWarningLights:SetStationMode(BuilderState.stationName, 'idle')
    notify(('Warning lights set to amber for station %s'):format(BuilderState.stationName))
end, false)

RegisterCommand('nexusred', function()
    IncidentNexusWarningLights:SetStationMode(BuilderState.stationName, 'alert')
    notify(('Warning lights set to red for station %s'):format(BuilderState.stationName))
end, false)

RegisterCommand('nexuslightsoff', function()
    IncidentNexusWarningLights:SetStationMode(BuilderState.stationName, 'off')
    notify(('Warning lights turned off for station %s'):format(BuilderState.stationName))
end, false)
RegisterCommand(Config.Commands.Builder, function()
    toggleBuilder()
end, false)

RegisterCommand(Config.Commands.TestAlert, function()
    TriggerServerEvent('incident-nexus:server:testAlert', 'test_station')
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

                if mode == 'place_prop' or mode == 'hide_prop' then
                    IncidentNexusProps:Update()
                elseif mode == 'select_door' then
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
            end
        end

        Wait(sleep)
    end
end)

RegisterNetEvent('incident-nexus:client:receiveStations', function(stations)
    CachedStations = stations or {}
    debugPrint(('Received %s stations.'):format(#CachedStations))
end)

RegisterNetEvent('incident-nexus:client:receiveDrafts', function(drafts)
    CachedDrafts = drafts or {}
    debugPrint(('Received %s drafts.'):format(#CachedDrafts))
end)

RegisterNetEvent('incident-nexus:client:testAlert', function(stationId)
    notify(('Test alert triggered for station: %s'):format(tostring(stationId)))

    SendNUIMessage({
        action = 'showDispatch',
        title = 'Dispatch Alert',
        message = ('Tone-out triggered for %s'):format(tostring(stationId))
    })
end)

RegisterNetEvent('incident-nexus:client:notify', function(message)
    notify(message)
end)