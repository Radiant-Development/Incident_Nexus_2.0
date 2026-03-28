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

    PerformHttpRequest(VERSION_URL, function(statusCode, response)

        if statusCode ~= 200 then
            PrintWarning("Version check failed.")
            return
        end

        local data = json.decode(response)

        if data and data.version then

            if data.version ~= VERSION then

                PrintLine("^3", "================================================================================")
                PrintLine("^3", "                         Incident Nexus Update Available")
                PrintLine("^3", ("                         Current Version: %s"):format(VERSION))
                PrintLine("^3", ("                         Latest Version : %s"):format(data.version))
                PrintLine("^3", "================================================================================")

            else

                PrintSuccess(("Running Latest Version (%s)"):format(VERSION))

            end

        end

    end, "GET")

end

local function generateId(prefix)
    return ("%s_%s_%s"):format(prefix, os.time(), math.random(1000,9999))
end

local function saveDraftLuaFile(data)

    local fileName = ("%s.lua"):format(data.id or generateId("station"))
    local path = ("draftlocations/%s"):format(fileName)

    local content = ("return %s"):format(json.encode(data))

    SaveResourceFile(ResourceName, path, content, -1)

    return fileName, path

end

RegisterNetEvent("incident-nexus:server:createStationDraft", function(data)

    local src = source

    data.id = data.id or generateId("station")

    local fileName, path = saveDraftLuaFile(data)

    PrintSuccess(("Draft Exported: %s"):format(path))

    TriggerClientEvent("incident-nexus:client:notify", src, ("Draft exported as %s"):format(fileName))

end)

CreateThread(function()

    math.randomseed(os.time())

    StartupBanner()

    Wait(1500)

    VersionCheck()

end)