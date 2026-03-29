IncidentNexusProps = IncidentNexusProps or {}

local PropState = {
    Active = false,
    CurrentIndex = 1,
    PreviewEntity = nil,
    PreviewCoords = nil,
    PreviewHeading = 0.0,
    PreviewNormal = nil,
    PlacedProps = {},
    HiddenProps = {}
}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s Props] %s'):format(Config.DisplayName, message))
    end
end

local function getCurrentProp()
    return Config.PropModels[PropState.CurrentIndex]
end

local function loadModel(model)
    local modelHash = joaat(model)

    if not IsModelInCdimage(modelHash) then
        debugPrint(('Invalid model: %s'):format(model))
        return nil
    end

    RequestModel(modelHash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) do
        Wait(0)
        if GetGameTimer() > timeout then
            debugPrint(('Model load timed out: %s'):format(model))
            return nil
        end
    end

    return modelHash
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

    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResultIncludingMaterial(ray)
    return hit == 1, endCoords, surfaceNormal, entityHit
end

local function deletePreview()
    if PropState.PreviewEntity and DoesEntityExist(PropState.PreviewEntity) then
        DeleteEntity(PropState.PreviewEntity)
    end

    PropState.PreviewEntity = nil
    PropState.PreviewCoords = nil
    PropState.PreviewNormal = nil
end

local function applyPreviewTransform(entity, coords, normal)
    if not entity or not DoesEntityExist(entity) or not coords then
        return
    end

    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)

    if normal then
        local absZ = math.abs(normal.z)

        if absZ > 0.85 then
            SetEntityRotation(entity, 0.0, 0.0, PropState.PreviewHeading, 2, true)
        elseif absZ < 0.2 then
            SetEntityRotation(entity, 90.0, 0.0, PropState.PreviewHeading, 2, true)
        else
            SetEntityRotation(entity, 45.0, 0.0, PropState.PreviewHeading, 2, true)
        end
    else
        SetEntityRotation(entity, 0.0, 0.0, PropState.PreviewHeading, 2, true)
    end
end

local function createPreview()
    deletePreview()

    local prop = getCurrentProp()
    if not prop then
        return
    end

    local modelHash = loadModel(prop.model)
    if not modelHash then
        return
    end

    local hit, coords, normal = raycastFromCamera(Config.SelectionDistance)
    if not hit or not coords then
        return
    end

    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)
    SetEntityAlpha(obj, 180, false)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)

    PropState.PreviewEntity = obj
    PropState.PreviewCoords = coords
    PropState.PreviewNormal = normal

    applyPreviewTransform(obj, coords, normal)
    SetModelAsNoLongerNeeded(modelHash)
end

local function updatePreview()
    if not PropState.Active then
        return
    end

    local hit, coords, normal = raycastFromCamera(Config.SelectionDistance)
    if not hit or not coords then
        return
    end

    PropState.PreviewCoords = coords
    PropState.PreviewNormal = normal

    if not PropState.PreviewEntity or not DoesEntityExist(PropState.PreviewEntity) then
        createPreview()
        return
    end

    applyPreviewTransform(PropState.PreviewEntity, coords, normal)
end

local function drawPlacement()
    if not PropState.PreviewCoords then
        return
    end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local target = PropState.PreviewCoords

    DrawLine(
        pedCoords.x, pedCoords.y, pedCoords.z,
        target.x, target.y, target.z,
        0, 150, 255, 255
    )

    DrawMarker(
        1,
        target.x, target.y, target.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.2, 0.2, 0.2,
        0, 150, 255, 125,
        false, false, 2, false, nil, nil, false
    )
end

local function placeProp(stationId)
    local prop = getCurrentProp()
    if not prop then
        return
    end

    local coords = PropState.PreviewCoords
    local normal = PropState.PreviewNormal

    if not coords then
        return
    end

    local modelHash = loadModel(prop.model)
    if not modelHash then
        return
    end

    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    FreezeEntityPosition(obj, true)

    applyPreviewTransform(obj, coords, normal)

    local finalCoords = GetEntityCoords(obj)
    local rot = GetEntityRotation(obj, 2)

    local propData = {
        id = ('prop_%s'):format(#PropState.PlacedProps + 1),
        stationId = stationId or 'unknown_station',
        label = prop.label,
        model = prop.model,
        type = prop.type,
        category = prop.category,
        mode = (prop.type == 'warning_light' or prop.type == 'station_light' or prop.type == 'status_light') and 'idle' or nil,
        coords = {
            x = finalCoords.x,
            y = finalCoords.y,
            z = finalCoords.z
        },
        rotation = {
            x = rot.x,
            y = rot.y,
            z = rot.z
        }
    }

    table.insert(PropState.PlacedProps, {
        entity = obj,
        data = propData
    })

    if propData.type == 'warning_light' or propData.type == 'station_light' or propData.type == 'status_light' then
        IncidentNexusWarningLights:RegisterLight(propData.id, propData.stationId, obj, propData.mode or 'idle')
    end

    debugPrint(('Placed %s for station %s'):format(prop.label, propData.stationId))
end

local function removeLast()
    local last = PropState.PlacedProps[#PropState.PlacedProps]
    if not last then
        return
    end

    if last.entity and DoesEntityExist(last.entity) then
        DeleteEntity(last.entity)
    end

    if last.data and last.data.id then
        IncidentNexusWarningLights:RemoveLight(last.data.id)
    end

    table.remove(PropState.PlacedProps, #PropState.PlacedProps)
    debugPrint('Removed last placed prop.')
end

local function hideProp()
    local hit, _, _, entity = raycastFromCamera(Config.SelectionDistance)
    if not hit or not entity or entity == 0 then
        return
    end

    if not DoesEntityExist(entity) then
        return
    end

    local entityCoords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)

    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)

    table.insert(PropState.HiddenProps, {
        model = model,
        coords = {
            x = entityCoords.x,
            y = entityCoords.y,
            z = entityCoords.z
        }
    })

    debugPrint('Hidden targeted prop.')
end

function IncidentNexusProps:SetActive(state)
    PropState.Active = state

    if state then
        createPreview()
    else
        deletePreview()
    end
end

function IncidentNexusProps:Update()
    updatePreview()
    drawPlacement()
end

function IncidentNexusProps:Cycle(forward)
    if forward then
        PropState.CurrentIndex = PropState.CurrentIndex + 1
        if PropState.CurrentIndex > #Config.PropModels then
            PropState.CurrentIndex = 1
        end
    else
        PropState.CurrentIndex = PropState.CurrentIndex - 1
        if PropState.CurrentIndex < 1 then
            PropState.CurrentIndex = #Config.PropModels
        end
    end

    createPreview()
end

function IncidentNexusProps:Confirm(stationId)
    placeProp(stationId)
end

function IncidentNexusProps:Cancel()
    removeLast()
end

function IncidentNexusProps:Hide()
    hideProp()
end

function IncidentNexusProps:GetPlacedPropsForExport()
    local export = {}

    for i = 1, #PropState.PlacedProps do
        table.insert(export, PropState.PlacedProps[i].data)
    end

    return export
end

function IncidentNexusProps:GetHiddenPropsForExport()
    return PropState.HiddenProps
end

function IncidentNexusProps:GetCurrentLabel()
    local prop = getCurrentProp()
    return prop and prop.label or 'None'
end