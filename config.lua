Config = {}

Config.Debug = true

Config.ResourceName = 'incident-nexus'
Config.DisplayName = 'Incident Nexus'

Config.Commands = {
    Builder = 'incidentbuilder',
    TestAlert = 'nexustest',
    BayOpen = 'bayopen',
    BackIn = 'backin'
}

Config.Keys = {
    Interact = 38,
    SaveDraft = 47,
    CycleOption = 174,
    CycleOptionBack = 175,
    Confirm = 191,
    Cancel = 194
}

Config.DrawDistance = 25.0
Config.InteractionDistance = 2.0

Config.DraftFolder = 'draftlocations'
Config.LocationsResource = 'nexus_locations'

Config.DefaultStation = {
    name = 'New Station',
    department = 'fire',
    stationType = 'fire_station'
}

Config.Departments = {
    'fire',
    'police',
    'ems',
    'dispatch',
    'custom'
}

Config.StationTypes = {
    'fire_station',
    'police_station',
    'ems_station',
    'dispatch_center',
    'custom'
}