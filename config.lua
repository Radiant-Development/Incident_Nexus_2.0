Config = {}

Config.Debug = true

Config.ResourceName = 'incident-nexus'
Config.DisplayName = 'Incident Nexus'

Config.Commands = {
    Builder = 'incidentbuilder',
    TestAlert = 'nexustest',
    BayOpen = 'bayopen',
    BackIn = 'backin',
    SetStationName = 'nexussetname'
}

Config.Keys = {
    Confirm = 24,      -- Left Click
    Cancel = 25,       -- Right Click
    ScrollUp = 15,     -- Mouse Wheel Up
    ScrollDown = 14,   -- Mouse Wheel Down
    ExportDraft = 38   -- E
}

Config.DrawDistance = 25.0
Config.InteractionDistance = 2.0
Config.SelectionDistance = 6.0

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

Config.BuilderModes = {
    'place_prop',
    'hide_prop',
    'select_door'
}

Config.DoorNamePresets = {
    'Bay 1',
    'Bay 2',
    'Bay 3',
    'Bay 4',
    'Engine Bay',
    'Ladder Bay',
    'Rescue Bay',
    'Medic Bay',
    'Command Bay'
}

Config.ApparatusPresets = {
    'Engine 1',
    'Engine 2',
    'Ladder 1',
    'Rescue 1',
    'Medic 1',
    'Medic 2',
    'Battalion 1',
    'Chief 1',
    'Squad 1',
    'Truck 1',
    'Tender 1',
    'Brush 1'
}

Config.PropModels = {

-- Dispatch Screens
{ label = 'Dispatch Monitor', model = 'prop_monitor_01a', type = 'dispatch_screen' },
{ label = 'Wall TV', model = 'prop_tv_flat_02', type = 'dispatch_screen' },
{ label = 'Laptop', model = 'prop_laptop_lester2', type = 'dispatch_screen' },

-- Door Controls
{ label = 'Keypad', model = 'prop_cs_keypad_01', type = 'door_control' },
{ label = 'Security Panel', model = 'prop_ld_keypad_01', type = 'door_control' },

-- Warning Lights
{ label = 'Work Light', model = 'prop_worklight_03b', type = 'warning_light' },
{ label = 'Wall Light', model = 'prop_wall_light_05a', type = 'warning_light' },

-- Traffic Lights
{ label = 'Traffic Light 1', model = 'prop_traffic_01a', type = 'traffic_light' },
{ label = 'Traffic Light 2', model = 'prop_traffic_01b', type = 'traffic_light' },

-- Station Lights
{ label = 'Industrial Light', model = 'prop_ind_light_02a', type = 'station_light' },
{ label = 'Bay Light', model = 'prop_ind_light_03a', type = 'station_light' },

-- Fire Station Props
{ label = 'Fire Extinguisher', model = 'prop_fire_exting_1a', type = 'equipment' },
{ label = 'Fire Hose Box', model = 'prop_fire_hosebox_01', type = 'equipment' },
{ label = 'Tool Chest', model = 'prop_toolchest_01', type = 'equipment' }

}