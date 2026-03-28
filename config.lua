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
    Confirm = 24,      -- Left Click
    Cancel = 25,       -- Right Click
    ScrollUp = 15,     -- Mouse Wheel Up
    ScrollDown = 14,   -- Mouse Wheel Down
    ExportDraft = 38   -- E
}

Config.DrawDistance = 25.0
Config.InteractionDistance = 2.0
Config.SelectionDistance = 20.0

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
    { label = 'Door Control Panel', model = 'prop_ic_door_controls', type = 'door_control', category = 'door_controls' },

    { label = 'Warning Light', model = 'prop_ic_warning_lights', type = 'warning_light', category = 'warning_lights' },
    { label = 'Bollard Light Off', model = 'prop_ic_bollard_light_off', type = 'warning_light', category = 'warning_lights' },
    { label = 'Bollard Light On', model = 'prop_ic_bollard_light_on', type = 'warning_light', category = 'warning_lights' },
    { label = 'Wall Light', model = 'prop_ic_wall_light', type = 'warning_light', category = 'warning_lights' },

    { label = 'Status Light Green', model = 'prop_ic_status_lights_green', type = 'status_light', category = 'status_lights' },
    { label = 'Status Light Off', model = 'prop_ic_status_lights_off', type = 'status_light', category = 'status_lights' },
    { label = 'Status Light Red', model = 'prop_ic_status_lights_red', type = 'status_light', category = 'status_lights' },

    { label = 'Traffic Light Green', model = 'prop_ic_traffic_light_g', type = 'traffic_light', category = 'traffic_lights' },
    { label = 'Traffic Light Red', model = 'prop_ic_traffic_light_r', type = 'traffic_light', category = 'traffic_lights' },
    { label = 'Traffic Light Yellow', model = 'prop_ic_traffic_light_y', type = 'traffic_light', category = 'traffic_lights' },
    { label = 'Addon Traffic Light Neutral', model = 'prop_ic_addon_traffic_light_n', type = 'traffic_light', category = 'traffic_lights' },
    { label = 'Addon Traffic Light Red', model = 'prop_ic_addon_traffic_light_r', type = 'traffic_light', category = 'traffic_lights' },
    { label = 'Addon Traffic Light Yellow Flash', model = 'prop_ic_addon_traffic_light_y_f', type = 'traffic_light', category = 'traffic_lights' },
    { label = 'Addon Traffic Light Yellow Solid', model = 'prop_ic_addon_traffic_light_y_s', type = 'traffic_light', category = 'traffic_lights' },

    { label = 'Unit Beacon Default', model = 'prop_ic_unit_beacon', type = 'unit_beacon', category = 'unit_beacons' },
    { label = 'Unit Beacon Blue', model = 'prop_ic_unit_beacon_b', type = 'unit_beacon', category = 'unit_beacons' },
    { label = 'Unit Beacon Green', model = 'prop_ic_unit_beacon_g', type = 'unit_beacon', category = 'unit_beacons' },
    { label = 'Unit Beacon Magenta', model = 'prop_ic_unit_beacon_m', type = 'unit_beacon', category = 'unit_beacons' },
    { label = 'Unit Beacon Red', model = 'prop_ic_unit_beacon_r', type = 'unit_beacon', category = 'unit_beacons' },
    { label = 'Unit Beacon Yellow', model = 'prop_ic_unit_beacon_y', type = 'unit_beacon', category = 'unit_beacons' },

    { label = 'Unit Indicator Default', model = 'prop_ic_unit_indicator', type = 'unit_indicator', category = 'unit_indicators' },
    { label = 'Unit Indicator Blue', model = 'prop_ic_unit_indicator_b', type = 'unit_indicator', category = 'unit_indicators' },
    { label = 'Unit Indicator Green', model = 'prop_ic_unit_indicator_g', type = 'unit_indicator', category = 'unit_indicators' },
    { label = 'Unit Indicator Magenta', model = 'prop_ic_unit_indicator_m', type = 'unit_indicator', category = 'unit_indicators' },
    { label = 'Unit Indicator Red', model = 'prop_ic_unit_indicator_r', type = 'unit_indicator', category = 'unit_indicators' },
    { label = 'Unit Indicator Yellow', model = 'prop_ic_unit_indicator_y', type = 'unit_indicator', category = 'unit_indicators' },

    { label = 'Dispatch Screen', model = 'xm_prop_x17_tv_ceiling_scn_02', type = 'dispatch_screen', category = 'screens' }
}