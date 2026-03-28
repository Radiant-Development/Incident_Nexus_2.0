IncidentNexusDoors = IncidentNexusDoors or {}
print('[Incident Nexus] doors.lua loaded')
local DoorState = {
    Active = false,
    SelectedDoors = {},
    CurrentTarget = nil,
    CurrentEditIndex = nil,
    NamePresetIndex = 1,
    ApparatusPresetIndex = 1
}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s Doors] %s'):format(Config.DisplayName, message))
    end
end

local function rotationToDirection(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosX = math.abs(math.cos(rotX))

    return vector3(
        -math.sin(rotZ) * cosX,
        math.cos(rotZ) * cosX,
        math.sin(rotX)
    )
end

local function raycastFromCamera(distance)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = rotationToDirection(camRot)
    local destination = camCoords + (direction * distance)

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        -1,
        PlayerPedId(),
        0
    )

    local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)
    return hit == 1, endCoords, entityHit
end

local function getCurrentDoor()
    if not DoorState.CurrentEditIndex then
        return nil
    end

    return DoorState.SelectedDoors[DoorState.CurrentEditIndex]
end

local function drawTarget()
    local hit, coords, entityHit = raycastFromCamera(Config.SelectionDistance)
    if not hit or not coords then
        DoorState.CurrentTarget = nil
        return
    end

    DoorState.CurrentTarget = {
        entity = entityHit,
        coords = coords
    }

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    DrawLine(
        pedCoords.x, pedCoords.y, pedCoords.z,
        coords.x, coords.y, coords.z,
        255, 100, 0, 255
    )

    DrawMarker(
        1,
        coords.x, coords.y, coords.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.45, 0.45, 0.15,
        255, 100, 0, 125,
        false, false, 2, false, nil, nil, false
    )
end

local function applyCurrentPresetsToDoor(door)
    if not door then
        return
    end

    door.name = Config.DoorNamePresets[DoorState.NamePresetIndex] or door.name
    door.apparatus = Config.ApparatusPresets[DoorState.ApparatusPresetIndex] or door.apparatus
end

local function buildDoorEntry()
    if not DoorState.CurrentTarget then
        return nil
    end

    local target = DoorState.CurrentTarget
    local entity = target.entity
    local coords = target.coords
    local doorIndex = #DoorState.SelectedDoors + 1

    local entry = {
        id = ('door_%s'):format(doorIndex),
        name = Config.DoorNamePresets[DoorState.NamePresetIndex] or ('Bay %s'):format(doorIndex),
        apparatus = Config.ApparatusPresets[DoorState.ApparatusPresetIndex] or ('Apparatus %s'):format(doorIndex),
        type = 'bay_door',
        lockedClosed = true,
        selectedInDraft = true,
        disableAutoOpen = true,
        entityModel = entity and entity ~= 0 and GetEntityModel(entity) or 0,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    }

    return entry
end

local function confirmDoor()
    local entry = buildDoorEntry()
    if not entry then
        return false
    end

    DoorState.SelectedDoors[#DoorState.SelectedDoors + 1] = entry
    DoorState.CurrentEditIndex = #DoorState.SelectedDoors

    debugPrint(('Selected door: %s / %s'):format(entry.name, entry.apparatus))
    return true
end

local function removeLastDoor()
    if #DoorState.SelectedDoors < 1 then
        return false
    end

    table.remove(DoorState.SelectedDoors, #DoorState.SelectedDoors)

    if #DoorState.SelectedDoors > 0 then
        DoorState.CurrentEditIndex = #DoorState.SelectedDoors
    else
        DoorState.CurrentEditIndex = nil
    end

    debugPrint('Removed last selected door.')
    return true
end

function IncidentNexusDoors:SetActive(state)
    DoorState.Active = state
    DoorState.CurrentTarget = nil
end

function IncidentNexusDoors:Update()
    if not DoorState.Active then return end
    drawTarget()
end

function IncidentNexusDoors:ConfirmSelect()
    return confirmDoor()
end

function IncidentNexusDoors:RemoveLastSelected()
    return removeLastDoor()
end

function IncidentNexusDoors:CycleDoorName(forward)
    if forward then
        DoorState.NamePresetIndex = DoorState.NamePresetIndex + 1
        if DoorState.NamePresetIndex > #Config.DoorNamePresets then
            DoorState.NamePresetIndex = 1
        end
    else
        DoorState.NamePresetIndex = DoorState.NamePresetIndex - 1
        if DoorState.NamePresetIndex < 1 then
            DoorState.NamePresetIndex = #Config.DoorNamePresets
        end
    end

    applyCurrentPresetsToDoor(getCurrentDoor())
end

function IncidentNexusDoors:CycleApparatus(forward)
    if forward then
        DoorState.ApparatusPresetIndex = DoorState.ApparatusPresetIndex + 1
        if DoorState.ApparatusPresetIndex > #Config.ApparatusPresets then
            DoorState.ApparatusPresetIndex = 1
        end
    else
        DoorState.ApparatusPresetIndex = DoorState.ApparatusPresetIndex - 1
        if DoorState.ApparatusPresetIndex < 1 then
            DoorState.ApparatusPresetIndex = #Config.ApparatusPresets
        end
    end

    applyCurrentPresetsToDoor(getCurrentDoor())
end

function IncidentNexusDoors:GetDoorsForExport()
    return DoorState.SelectedDoors
end

function IncidentNexusDoors:GetSelectedDoorCount()
    return #DoorState.SelectedDoors
end

function IncidentNexusDoors:GetCurrentDoorName()
    local door = getCurrentDoor()
    return door and door.name or 'None'
end

function IncidentNexusDoors:GetCurrentApparatus()
    local door = getCurrentDoor()
    return door and door.apparatus or 'None'
end