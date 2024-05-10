-- Configuration for engine heating script #DONT TOUCH THIS#
Config = {}

-- Framework selection: "ESX", "QBCore", or "Standalone"
Config.Framework = "QBCore"

-- Time in seconds after which the engine starts heating at max speed
Config.MaxSpeedDuration = 19

-- Speed in km/h considered as max speed before engine can overheat
Config.SpeedThreshold = 190

-- Time in seconds to reset the overheating
Config.OverheatResetTime = 8

-- Time in seconds to reset overheating after using a water bottle on engine hood # ONLY WORKS FOR ESX AND QB #
-- # It's a WIP and is not working. Soon to be implemented.. (hopefully) #
-- Config.CoolDownWithWaterTime = 3 

-- Speed unit ("kmh" for kilometers per hour, "mph" for miles per hour)
Config.SpeedUnit = 'kmh'

-- Translation for the messages
Config.Messages = {
    Overheat = "Din motor er overophedet...",
    CoolDown = "Din motor er kølet ned...",
    Error = "Der opstod en fejl!"
}

-- vehicle models that will be ignored (add as many as you want)
-- Important: Write models in UPPERCASE
Config.WhitelistedVehicles = {
    "POLICE",
    "POLICE2",
    "POLICE3",
    "AMBULANCE",
    "FIRETRUK"
}