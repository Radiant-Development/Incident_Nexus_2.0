IncidentNexusProps = IncidentNexusProps or {}
print('[Incident Nexus] props.lua loaded')
local PropState = {
    Active = false,
    CurrentIndex = 1,
    PreviewEntity = nil,
    PreviewCoords = nil,
    PreviewHeading = 0.0,
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

    local _, hit, endCoords, _, entityHit = GetShapeTestResult(ray)
    return hit == 1, endCoords, entityHit
end

local function deletePreview()
    if PropState.PreviewEntity and DoesEntityExist(PropState.PreviewEntity) then
        DeleteEntity(PropState.PreviewEntity)
    end

    PropState.PreviewEntity = nil
end

local function createPreview()
    deletePreview()

    local prop = getCurrentProp()
    if not prop then return end

    local modelHash = loadModel(prop.model)
    if not modelHash then return end

    local hit, coords = raycastFromCamera(Config.SelectionDistance)
    if not hit then return end

    local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, false, false, false)

    SetEntityAlpha(obj, 180, false)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)

    PropState.PreviewEntity = obj
    PropState.PreviewCoords = coords
end

local function updatePreview()
    if not PropState.Active then return end

    local hit, coords = raycastFromCamera(Config.SelectionDistance)
    if not hit then return end

    PropState.PreviewCoords = coords

    if not PropState.PreviewEntity then
        createPreview()
        return
    end

    SetEntityCoordsNoOffset(
        PropState.PreviewEntity,
        coords.x,
        coords.y,
        coords.z,
        false,
        false,
        false
    )

    PlaceObjectOnGroundProperly(PropState.PreviewEntity)
end

local function drawPlacement()
    if not PropState.PreviewCoords then return end

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
        target.x, target.y, target.z - 1.0,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.45, 0.45, 0.15,
        0, 150, 255, 125,
        false, false, 2
    )
end

local function placeProp()

    local prop = getCurrentProp()
    if not prop then return end

    local coords = PropState.PreviewCoords
    if not coords then return end

    local modelHash = loadModel(prop.model)
    if not modelHash then return end

    local obj = CreateObject(
        modelHash,
        coords.x,
        coords.y,
        coords.z,
        true,
        true,
        false
    )

    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)

    local finalCoords = GetEntityCoords(obj)

    local propData = {
        label = prop.label,
        model = prop.model,
        type = prop.type,
        category = prop.category,
        coords = {
            x = finalCoords.x,
            y = finalCoords.y,
            z = finalCoords.z
        }
    }

    table.insert(PropState.PlacedProps, {
        entity = obj,
        data = propData
    })

    debugPrint(('Placed %s'):format(prop.label))
end

local function removeLast()
    local last = PropState.PlacedProps[#PropState.PlacedProps]
    if not last then return end

    if last.entity and DoesEntityExist(last.entity) then
        DeleteEntity(last.entity)
    end

    table.remove(PropState.PlacedProps, #PropState.PlacedProps)
end

local function hideProp()

    local hit, coords, entity = raycastFromCamera(Config.SelectionDistance)
    if not hit or not entity then return end

    local entityCoords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)

    SetEntityAsMissionEntity(entity, true, true)
    DeleteEntity(entity)

    table.insert(PropState.HiddenProps, {
        model = model,
        coords = entityCoords
    })
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

function IncidentNexusProps:Confirm()
    placeProp()
end

function IncidentNexusProps:Cancel()
    removeLast()
end

function IncidentNexusProps:Hide()
    hideProp()
end

function IncidentNexusProps:GetPlacedPropsForExport()
    local export = {}

    for i=1, #PropState.PlacedProps do
        table.insert(export, PropState.PlacedProps[i].data)
    end

    return export
end

function IncidentNexusProps:GetHiddenPropsForExport()
    return PropState.HiddenProps
end

function IncidentNexusProps:GetCurrentLabel()
    local prop = getCurrentProp()
    return prop and prop.label or "None"
end