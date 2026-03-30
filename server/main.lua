local ResourceName = GetCurrentResourceName()

-- Locked under escrow
local VERSION = "1.4.0"
local VERSION_URL = "https://github.com/Radiant-Development/Incident_Nexus_2.0/blob/main/version.json"
local LOCATIONS_RESOURCE = "nexus_locations"

local Stations = {}
local Drafts = {}

local function PrintLine(color, text)
    print((color .. text .. "^7"))
end

local function PrintSuccess(text)
    print(("^2[Incident Nexus]^7 %s"):format(text))
end

local function PrintWarning(text)
    print(("^3[Incident Nexus]^7 %s"):format(text))
end

local function PrintError(text)
    print(("^1[Incident Nexus]^7 %s"):format(text))
end

local function StartupBanner()
    PrintLine("^5", [[
██╗███╗   ██╗ ██████╗██╗██████╗ ███████╗███╗   ██╗████████╗    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗
██║████╗  ██║██╔════╝██║██╔══██╗██╔════╝████╗  ██║╚══██╔══╝    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝
██║██╔██╗ ██║██║     ██║██║  ██║█████╗  ██╔██╗ ██║   ██║       ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗
██║██║╚██╗██║██║     ██║██║  ██║██╔══╝  ██║╚██╗██║   ██║       ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║
██║██║ ╚████║╚██████╗██║██████╔╝███████╗██║ ╚████║   ██║       ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║
╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝       ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
]])

    PrintLine("^5", "================================================================================")
    PrintLine("^5", "                        Incident Nexus - Standalone Edition")
    PrintLine("^5", "                          Created By RebelGamer2k20")
    PrintLine("^5", ("                                Version: %s"):format(VERSION))
    PrintLine("^5", "================================================================================")
end

local function VersionCheck()
    if not VERSION_URL or VERSION_URL == "" or VERSION_URL:find("YOUR_PUBLIC_VERSION_REPO", 1, true) then
        PrintWarning("Version check skipped. Set a public version.json URL in server/main.lua")
        return
    end

    PerformHttpRequest(VERSION_URL, function(statusCode, response)
        if statusCode ~= 200 then
            PrintWarning(("Version check failed. HTTP %s"):format(tostring(statusCode)))
            return
        end

        local ok, data = pcall(json.decode, response)
        if not ok or type(data) ~= "table" then
            PrintError("Version check failed. Invalid JSON response.")
            return
        end

        if not data.version then
            PrintError("Version check failed. Missing version field.")
            return
        end

        if data.version ~= VERSION then
            PrintLine("^3", "================================================================================")
            PrintLine("^3", "                         Incident Nexus Update Available")
            PrintLine("^3", ("                         Current Version: %s"):format(VERSION))
            PrintLine("^3", ("                         Latest Version : %s"):format(data.version))
            PrintLine("^3", "================================================================================")
        else
            PrintSuccess(("Running Latest Version (%s)"):format(VERSION))
        end
    end, "GET")
end

local function generateId(prefix)
    return ("%s_%s_%s"):format(prefix, os.time(), math.random(1000, 9999))
end

local function sanitizeFileName(name)
    local safe = tostring(name or "station")
    safe = safe:lower()
    safe = safe:gsub("[^%w_%-]+", "_")
    safe = safe:gsub("_+", "_")
    safe = safe:gsub("^_+", "")
    safe = safe:gsub("_+$", "")

    if safe == "" then
        safe = generateId("station")
    end

    return safe
end

local function serializeValue(value, indent)
    indent = indent or 0
    local spacing = string.rep("    ", indent)

    if type(value) == "table" then
        local isArray = true
        local expectedIndex = 1

        for k, _ in pairs(value) do
            if k ~= expectedIndex then
                isArray = false
                break
            end
            expectedIndex = expectedIndex + 1
        end

        local lines = {"{"}

        if isArray then
            for _, v in ipairs(value) do
                lines[#lines + 1] = string.rep("    ", indent + 1) .. serializeValue(v, indent + 1) .. ","
            end
        else
            for k, v in pairs(value) do
                local key
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    key = k
                else
                    key = ("[%s]"):format(serializeValue(k, indent + 1))
                end

                lines[#lines + 1] = string.rep("    ", indent + 1) .. key .. " = " .. serializeValue(v, indent + 1) .. ","
            end
        end

        lines[#lines + 1] = spacing .. "}"
        return table.concat(lines, "\n")
    elseif type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    else
        return "nil"
    end
end

local function stationToLua(data)
    local exportData = {
        id = data.id or "station_unknown",
        name = data.name or "New Station",
        department = data.department or "fire",
        stationType = data.stationType or "fire_station",
        coords = data.coords or { x = 0.0, y = 0.0, z = 0.0 },
        heading = data.heading or 0.0,
        props = data.props or {},
        hiddenProps = data.hiddenProps or {},
        doors = data.doors or {},
        traffic = data.traffic or {},
        screens = data.screens or {},
        computers = data.computers or {},
        warningLights = data.warningLights or {}
    }

    return "return " .. serializeValue(exportData, 0) .. "\n"
end

local function ensureDraftFolder()
    local keepPath = "draftlocations/.keep"
    local existing = LoadResourceFile(ResourceName, keepPath)

    if existing == nil then
        SaveResourceFile(ResourceName, keepPath, "", -1)
    end
end

local function saveDraftLuaFile(data)
    local fileBase = sanitizeFileName(data.fileName or data.id or data.name or "station")
    local fileName = ("%s.lua"):format(fileBase)
    local path = ("draftlocations/%s"):format(fileName)
    local content = stationToLua(data)

    local ok = SaveResourceFile(ResourceName, path, content, -1)
    return ok, fileName, path
end

local function loadStationFile(resourceName, fileName)
    local content = LoadResourceFile(resourceName, fileName)

    if not content or content == "" then
        PrintError(("Could not load station file %s from resource %s"):format(fileName, resourceName))
        return nil
    end

    local chunk, err = load(content, ("@@%s/%s"):format(resourceName, fileName), "t", {})
    if not chunk then
        PrintError(("Failed to compile station file %s: %s"):format(fileName, err))
        return nil
    end

    local ok, result = pcall(chunk)
    if not ok then
        PrintError(("Failed to execute station file %s: %s"):format(fileName, result))
        return nil
    end

    if type(result) ~= "table" then
        PrintError(("Station file %s did not return a table."):format(fileName))
        return nil
    end

    return result
end

local function loadManifestStations()
    Stations = {}

    local state = GetResourceState(LOCATIONS_RESOURCE)
    if state ~= "started" and state ~= "starting" then
        PrintWarning(('Locations resource "%s" is not started. No manifest stations loaded.'):format(LOCATIONS_RESOURCE))
        return
    end

    local count = GetNumResourceMetadata(LOCATIONS_RESOURCE, "locations")
    if not count or count < 1 then
        PrintWarning(('No locations metadata found in %s fxmanifest.lua'):format(LOCATIONS_RESOURCE))
        return
    end

    for i = 0, count - 1 do
        local fileName = GetResourceMetadata(LOCATIONS_RESOURCE, "locations", i)

        if fileName and fileName ~= "" then
            local stationData = loadStationFile(LOCATIONS_RESOURCE, fileName)

            if stationData then
                Stations[#Stations + 1] = stationData
                PrintSuccess(("Loaded station from manifest: %s"):format(fileName))
            end
        end
    end
end

RegisterNetEvent("incident-nexus:server:createStationDraft", function(data)
    local src = source

    if type(data) ~= "table" then
        PrintError(("Invalid station draft data from source %s"):format(src))
        return
    end

    data.id = data.id or generateId("station")
    ensureDraftFolder()

    local ok, fileName, path = saveDraftLuaFile(data)

    if not ok then
        PrintError(("Failed to save draft file: %s"):format(path))
        TriggerClientEvent("incident-nexus:client:notify", src, ("Failed to export draft: %s"):format(fileName))
        return
    end

    Drafts[#Drafts + 1] = {
        id = data.id,
        name = data.name or fileName,
        fileName = fileName,
        path = path,
        createdAt = os.time()
    }

    PrintSuccess(("Draft exported: %s"):format(path))
    TriggerClientEvent("incident-nexus:client:notify", src, ("Draft exported as %s"):format(fileName))
end)

RegisterNetEvent("incident-nexus:server:requestStations", function()
    local src = source
    loadManifestStations()
    TriggerClientEvent("incident-nexus:client:receiveStations", src, Stations)
end)

RegisterNetEvent("incident-nexus:server:requestDrafts", function()
    local src = source
    TriggerClientEvent("incident-nexus:client:receiveDrafts", src, Drafts)
end)

RegisterNetEvent("incident-nexus:server:testAlert", function(stationId)
    TriggerClientEvent("incident-nexus:client:testAlert", -1, stationId or "test_station")
end)

RegisterCommand("nexustestwrite", function(source)
    ensureDraftFolder()
    local ok = SaveResourceFile(ResourceName, "draftlocations/test_write.lua", "return {\n    test = true\n}\n", -1)
    print(("[Incident Nexus] test write result: %s"):format(tostring(ok)))
end, true)

CreateThread(function()
    math.randomseed(os.time())
    StartupBanner()
    ensureDraftFolder()
    loadManifestStations()
    Wait(1500)
    VersionCheck()
end)