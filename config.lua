Config = {}

Config.Debug = true

Config.ResourceName = 'incident-nexus'
Config.DisplayName = 'Incident Nexus'
Config.Version = '1.0.0'
Config.Locale = 'en-us'

Config.Standalone = true

Config.Commands = {
    Builder = 'incidentbuilder',
    TestAlert = 'nexustest',
    BayOpen = 'bayopen',
    BackIn = 'backin'
}

Config.Keys = {
    Interact = 38, -- E
    SaveDraft = 47 -- G
}

Config.DrawDistance = 25.0
Config.InteractionDistance = 2.0

Config.Paths = {
    Drafts = 'data/drafts/',
    Stations = 'data/stations/'
}

Config.VersionCheck = {
    Enabled = true,
    URL = 'https://raw.githubusercontent.com/YourGithub/incident-nexus/main/version.json'
}

Config.DefaultStation = {
    name = 'New Station',
    department = 'fire',
    stationType = 'fire_station'
}