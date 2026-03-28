local ResourceName = GetCurrentResourceName()

local Stations = {}
local Drafts = {}

local CURRENT_VERSION = '1.0.0'
local VERSION_CHECK_URL = 'https://raw.githubusercontent.com/YourGithub/incident-nexus/main/version.json'
local LOCATIONS_RESOURCE = 'nexus_locations'

local function PrintLine(color, text)
    print((color .. text .. '^7'))
end

local function PrintInfo(message)
    print(('^5[Incident Nexus]^7 %s'):format(message))
end

local function PrintSuccess(message)
    print(('^2[Incident Nexus]^7 %s'):format(message))
end

local function PrintWarning(message)
    print(('^3[Incident Nexus]^7 %s'):format(message))
end

local function PrintError(message)
    print(('^1[Incident Nexus]^7 %s'):format(message))
end

local function DebugPrint(message)
    if Config.Debug then
        print(('^3[Incident Nexus Debug]^7 %s'):format(message))
    end
end

local function StartupBanner()
    PrintLine('^5', [[
 ██╗███╗   ██╗ ██████╗██╗██████╗ ███████╗███╗   ██╗████████╗    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
 ██║████╗  ██║██╔════╝██║██╔══██╗██╔════╝████╗  ██║╚══██╔══╝    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
 ██║██╔██╗ ██║██║     ██║██║  ██║█████╗  ██╔██╗ ██║   ██║       ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
 ██║██║╚██╗██║██║     ██║██║  ██║██╔══╝  ██║╚██╗██║   ██║       ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
 ██║██║ ╚████║╚██████╗██║██████╔╝███████╗██║ ╚████║   ██║       ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
 ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝       ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
    ]])

    PrintLine('^5', '====================================================================================================')
    PrintLine('^5', '                                Incident Nexus - Standalone Edition')
    PrintLine('^5', '                                    Created By RebelGamer2k20')
    PrintLine('^5', ('                                         Version: %s'):format(CURRENT_VERSION))
    PrintLine('^5', '====================================================================================================')
end

local function generateId(prefix)
    return ('%s_%s_%s'):format(prefix, os.time(), math.random(1000, 9999))
end

local function stationToLua(data)
    return ([[
return {
    id = %q,
    name = %q,
    department = %q,
    stationType = %q,

    coords = {
        x = %.4f,
        y = %.4f,
        z = %.4f
    },

    props = {},
    doors = {},
    traffic = {}
}
]]):format(
        data.id or 'station_unknown',
        data.name or 'New Station',
        data.department or 'fire',
        data.stationType or 'fire_station',
        data.coords.x or 0.0,
        data.coords.y or 0.0,
        data.coords.z or 0.0
    )
end

local function saveDraftLuaFile(data)
    local fileName = ('%s.lua'):format(data.id or generateId('station'))
    local path = ('draftlocations/%s'):format(fileName)
    local content = stationToLua(data)

    SaveResourceFile(ResourceName, path, content, -1)
    return fileName, path
end

local function loadStationFile(resourceName, fileName)
    local content = LoadResourceFile(resourceName, fileName)

    if not content or content == '' then
        PrintError(('Could not load station file %s from resource %s'):format(fileName, resourceName))
        return nil
    end

    local chunk, err = load(content, ('@@%s/%s'):format(resourceName, fileName), 't', {})
    if not chunk then
        PrintError(('Failed to compile station file %s: %s'):format(fileName, err))
        return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
        PrintError(('Failed to execute station file %s: %s'):format(fileName, result))
        return nil
    end

    if type(result) ~= 'table' then
        PrintError(('Station file %s did not return a table.'):format(fileName))
        return nil
    end

    return result
end

local function loadManifestStations()
    local state = GetResourceState(LOCATIONS_RESOURCE)
    if state ~= 'started' and state ~= 'starting' then
        PrintWarning(('Locations resource "%s" is not started. No manifest stations loaded.'):format(LOCATIONS_RESOURCE))
        return
    end

    local count = GetNumResourceMetadata(LOCATIONS_RESOURCE, 'locations')
    if not count or count < 1 then
        PrintWarning(('No locations metadata found in %s fxmanifest.lua'):format(LOCATIONS_RESOURCE))
        return
    end

    for i = 0, count - 1 do
        local fileName = GetResourceMetadata(LOCATIONS_RESOURCE, 'locations', i)

        if fileName and fileName ~= '' then
            local stationData = loadStationFile(LOCATIONS_RESOURCE, fileName)

            if stationData then
                Stations[#Stations + 1] = stationData
                PrintSuccess(('Loaded station from manifest: %s'):format(fileName))
            end
        end
    end
end

local function RunVersionCheck()
    PerformHttpRequest(VERSION_CHECK_URL, function(statusCode, body)
        if statusCode ~= 200 then
            PrintError(('Version check failed. HTTP Status: %s'):format(statusCode))
            PrintWarning('Could not reach GitHub raw version file.')
            return
        end

        local ok, decoded = pcall(json.decode, body)
        if not ok or type(decoded) ~= 'table' then
            PrintError('Version check failed. Invalid JSON response from GitHub.')
            return
        end

        local latestVersion = decoded.version
        local changelog = decoded.changelog or 'No changelog provided.'

        if not latestVersion then
            PrintError('Version check failed. Missing version field in version.json.')
            return
        end

        if latestVersion ~= CURRENT_VERSION then
            PrintLine('^3', '====================================================================================================')
            PrintLine('^3', '                                      UPDATE AVAILABLE')
            PrintLine('^3', ('                                Current Version: %s'):format(CURRENT_VERSION))
            PrintLine('^3', ('                                Latest Version : %s'):format(latestVersion))
            PrintLine('^3', ('                                Changelog      : %s'):format(changelog))
            PrintLine('^3', '====================================================================================================')
        else
            PrintSuccess(('Incident Nexus is up to date. Running version %s'):format(CURRENT_VERSION))
        end
    end, 'GET')
end

RegisterNetEvent('incident-nexus:server:createStation', function(data)
    local src = source

    if type(data) ~= 'table' then
        PrintError(('Invalid station data from source %s'):format(src))
        return
    end

    data.id = data.id or generateId('station')
    data.createdBy = src
    data.createdAt = os.time()

    Drafts[#Drafts + 1] = data

    local fileName, savedPath = saveDraftLuaFile(data)

    PrintSuccess(('Draft exported: %s'):format(savedPath))
    TriggerClientEvent('incident-nexus:client:notify', src, ('Draft exported as %s'):format(fileName))
end)

RegisterNetEvent('incident-nexus:server:saveDraft', function(data)
    local src = source

    if type(data) ~= 'table' then
        PrintError(('Invalid draft data from source %s'):format(src))
        return
    end

    data.id = data.id or generateId('station')
    data.savedBy = src
    data.savedAt = os.time()

    Drafts[#Drafts + 1] = data

    local fileName, savedPath = saveDraftLuaFile(data)

    PrintSuccess(('Draft saved: %s'):format(savedPath))
    TriggerClientEvent('incident-nexus:client:notify', src, ('Draft saved as %s'):format(fileName))
end)

RegisterNetEvent('incident-nexus:server:requestStations', function()
    local src = source
    TriggerClientEvent('incident-nexus:client:receiveStations', src, Stations)
end)

RegisterNetEvent('incident-nexus:server:requestDrafts', function()
    local src = source
    TriggerClientEvent('incident-nexus:client:receiveDrafts', src, Drafts)
end)

RegisterNetEvent('incident-nexus:server:testAlert', function(stationId)
    TriggerClientEvent('incident-nexus:client:testAlert', -1, stationId or 'test_station')
end)

CreateThread(function()
    math.randomseed(os.time())
    StartupBanner()

    local existingDraftFolder = LoadResourceFile(ResourceName, 'draftlocations/.keep')
    if not existingDraftFolder then
        SaveResourceFile(ResourceName, 'draftlocations/.keep', '', -1)
    end

    loadManifestStations()

    Wait(1500)
    RunVersionCheck()
end)