IncidentNexusProps = IncidentNexusProps or {}

local PropState = {
    Active = false,
    CurrentIndex = 1,
    PreviewEntity = nil,
    PreviewCoords = nil,
    PreviewHeading = 0.0,
    PreviewNormal = nil,
    PlacedProps = {},
    HiddenProps = {},
    LoadedProps = {}
}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s Props] %s'):format(Config.DisplayName, message))
    end
end

local function getCurrentProp()
    return Config.PropModels[PropState.CurrentIndex]
end

local function isLightType(propType)
    return propType == 'warning_light'
        or propType == 'station_light'
        or propType == 'status_light'
        or propType == 'traffic_light'
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

local function normalToRotation(normal, heading)
    if not normal then
        return 0.0, 0.0, heading or 0.0
    end

    local pitch = math.deg(math.atan2(normal.y, normal.z))
    local roll = -math.deg(math.atan2(normal.x, normal.z))
    local yaw = heading or 0.0

    if math.abs(normal.z) < 0.5 then
        pitch = 0.0
        roll = 0.0
        yaw = (heading or 0.0)
    end

    return pitch, roll, yaw
end

local function applyEntitySurfaceTransform(entity, coords, normal)
    if not entity or not DoesEntityExist(entity) or not coords then
        return
    end

    normal = normal or vector3(0.0, 0.0, 1.0)

    local offset = 0.01

    local placeX = coords.x + (normal.x * offset)
    local placeY = coords.y + (normal.y * offset)
    local placeZ = coords.z + (normal.z * offset)

    SetEntityCoordsNoOffset(entity, placeX, placeY, placeZ, false, false, false)

    local pitch, roll, yaw = normalToRotation(normal, PropState.PreviewHeading)
    SetEntityRotation(entity, pitch, roll, yaw, 2, true)

    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, true, true)
    SetEntityDynamic(entity, false)
    SetEntityHasGravity(entity, false)
end

local function setupPreviewEntity(entity)
    SetEntityAlpha(entity, 180, false)
    SetEntityCollision(entity, false, false)
    SetEntityDynamic(entity, false)
    SetEntityHasGravity(entity, false)
    FreezeEntityPosition(entity, true)
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
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    local obj = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, false, false, false)
    setupPreviewEntity(obj)

    PropState.PreviewEntity = obj
    PropState.PreviewCoords = coords
    PropState.PreviewNormal = normal

    applyEntitySurfaceTransform(obj, coords, normal)
    SetEntityCollision(obj, false, false)

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

    applyEntitySurfaceTransform(PropState.PreviewEntity, coords, normal)
    SetEntityCollision(PropState.PreviewEntity, false, false)
    SetEntityAlpha(PropState.PreviewEntity, 180, false)
end

local function drawFacingLine()
    if not PropState.PreviewEntity or not DoesEntityExist(PropState.PreviewEntity) then
        return
    end

    local coords = GetEntityCoords(PropState.PreviewEntity)
    local forward = GetEntityForwardVector(PropState.PreviewEntity)

    local endX = coords.x + (forward.x * 1.0)
    local endY = coords.y + (forward.y * 1.0)
    local endZ = coords.z + (forward.z * 1.0)

    DrawLine(
        coords.x, coords.y, coords.z,
        endX, endY, endZ,
        0, 255, 100, 255
    )
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
        0.20, 0.20, 0.20,
        0, 150, 255, 125,
        false, false, 2, false, nil, nil, false
    )

    drawFacingLine()
end

local function spawnSavedProp(propData, storeLoaded)
    if not propData or not propData.model or not propData.coords then
        return nil
    end

    local modelHash = loadModel(propData.model)
    if not modelHash then
        return nil
    end

    local obj = CreateObjectNoOffset(
        modelHash,
        propData.coords.x,
        propData.coords.y,
        propData.coords.z,
        true,
        true,
        false
    )

    SetEntityDynamic(obj, false)
    SetEntityHasGravity(obj, false)
    FreezeEntityPosition(obj, true)

    if propData.rotation then
        SetEntityRotation(
            obj,
            propData.rotation.x or 0.0,
            propData.rotation.y or 0.0,
            propData.rotation.z or 0.0,
            2,
            true
        )
    end

    SetEntityCoordsNoOffset(
        obj,
        propData.coords.x,
        propData.coords.y,
        propData.coords.z,
        false,
        false,
        false
    )

    if storeLoaded then
        table.insert(PropState.LoadedProps, {
            entity = obj,
            data = propData
        })
    end

    if isLightType(propData.type) then
        IncidentNexusWarningLights:RegisterLight(
            propData.id or ('loaded_%s'):format(#PropState.LoadedProps + 1),
            propData.stationId or 'unknown_station',
            obj,
            propData.mode or 'idle',
            propData.type
        )
    end

    return obj
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

    local obj = CreateObjectNoOffset(modelHash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityDynamic(obj, false)
    SetEntityHasGravity(obj, false)
    FreezeEntityPosition(obj, true)

    applyEntitySurfaceTransform(obj, coords, normal)

    local finalCoords = GetEntityCoords(obj)
    local rot = GetEntityRotation(obj, 2)

    local propData = {
        id = ('prop_%s'):format(#PropState.PlacedProps + 1),
        stationId = stationId or 'unknown_station',
        label = prop.label,
        model = prop.model,
        type = prop.type,
        category = prop.category,
        mode = isLightType(prop.type) and 'idle' or nil,
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

    if isLightType(propData.type) then
        IncidentNexusWarningLights:RegisterLight(
            propData.id,
            propData.stationId,
            obj,
            propData.mode or 'idle',
            propData.type
        )
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

function IncidentNexusProps:Rotate(forward)
    if forward then
        PropState.PreviewHeading = PropState.PreviewHeading + 5.0
    else
        PropState.PreviewHeading = PropState.PreviewHeading - 5.0
    end

    if PropState.PreviewHeading >= 360.0 then
        PropState.PreviewHeading = 0.0
    elseif PropState.PreviewHeading < 0.0 then
        PropState.PreviewHeading = 355.0
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

function IncidentNexusProps:HideBuilderPlacedProps()
    for i = 1, #PropState.PlacedProps do
        local entry = PropState.PlacedProps[i]
        if entry.entity and DoesEntityExist(entry.entity) then
            DeleteEntity(entry.entity)
            entry.entity = nil
        end
    end

    IncidentNexusWarningLights:ClearAll()
end

function IncidentNexusProps:LoadStations(stations)
    for i = 1, #PropState.LoadedProps do
        local entry = PropState.LoadedProps[i]
        if entry.entity and DoesEntityExist(entry.entity) then
            DeleteEntity(entry.entity)
        end
    end

    PropState.LoadedProps = {}
    IncidentNexusWarningLights:ClearAll()

    if type(stations) ~= 'table' then
        return
    end

    for i = 1, #stations do
        local station = stations[i]
        if station and type(station.props) == 'table' then
            for p = 1, #station.props do
                spawnSavedProp(station.props[p], true)
            end
        end
    end

    debugPrint(('Loaded %s stations into world.'):format(#stations))
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