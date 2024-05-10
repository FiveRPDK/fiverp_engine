-- ###################################################
-- # _________ _______    ______   _______           #
-- # \__   __/(  ____ \  (  __  \ (  ____ \|\     /| #
-- #    ) (   | (    \/  | (  \  )| (    \/| )   ( | #
-- #    | |   | |        | |   ) || (__    | |   | | #
-- #    | |   | | ____   | |   | ||  __)   ( (   ) ) #
-- #    | |   | | \_  )  | |   ) || (       \ \_/ /  #
-- #    | |   | (___) |  | (__/  )| (____/\  \   /   #
-- #    )_(   (_______)  (______/ (_______/   \_/    #
-- #                                                 #
-- ###################################################

-- Main script for engine heating in FiveM adapted for ESX, QBCore, and Standalone
local isEngineHeating = false
local heatTimer = 0
local coolDownTimer = 0
local Framework = nil

-- Initialization for ESX, QBCore, or Standalone
Citizen.CreateThread(function()
    if Config.Framework == "ESX" then
        Framework = exports['es_extended']:getSharedObject()
        if Framework then
            print("ESX framework initialized successfully.")
        else
            print("Failed to initialize ESX framework.")
        end
    elseif Config.Framework == "QBCore" then
        Framework = exports["qb-core"]:GetCoreObject()
        if Framework then
            print("QBCore framework initialized successfully.")
        else
            print("Failed to initialize QBCore framework.")
        end
    end
end)

-- Main vehicle check loop with synchronization
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)

        local playerPed = PlayerPedId()
        if IsPedInAnyVehicle(playerPed, false) then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
            local vehicleModel = GetEntityModel(vehicle)
            local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
            local driver = GetPedInVehicleSeat(vehicle, -1)  -- -1 is the driver seat index

            if not isVehicleWhitelisted(vehicleName, vehicleModel) then
                local currentSpeed = GetEntitySpeed(vehicle) * (Config.SpeedUnit == 'mph' and 2.23694 or 3.6) -- convert m/s to km/h or mph

                if currentSpeed >= Config.SpeedThreshold then
                    heatTimer = heatTimer + 1
                    coolDownTimer = 0
                    if heatTimer >= Config.MaxSpeedDuration and not isEngineHeating then
                        isEngineHeating = true
                        TriggerServerEvent('engine:updateOverheatStatus', vehicleNetId, true)
                        if playerPed == driver then  -- Check if the player is the driver
                            local message = Config.Messages.Overheat
                            if Framework and Config.Framework == "ESX" then
                                Framework.showNotification(message)
                            elseif Framework and Config.Framework == "QBCore" then
                                TriggerEvent('QBCore:Notify', message, 'error', 3000)
                            elseif Config.Framework == "Standalone" then
                                TriggerEvent('chat:addMessage', {
                                    color = { 255, 0, 0},
                                    multiline = true,
                                    args = {"Motor", message}
                                })
                            end
                        end
                    end
                else
                    if heatTimer > 0 then
                        coolDownTimer = coolDownTimer + 1
                        if coolDownTimer >= Config.OverheatResetTime then
                            heatTimer = 0
                            coolDownTimer = 0
                            isEngineHeating = false
                            TriggerServerEvent('engine:updateOverheatStatus', vehicleNetId, false)
                            if playerPed == driver then  -- Check if the player is the driver
                                local coolMessage = Config.Messages.CoolDown
                                if Framework and Config.Framework == "ESX" then
                                    Framework.showNotification(coolMessage)
                                elseif Framework and Config.Framework == "QBCore" then
                                    TriggerEvent('QBCore:Notify', coolMessage, 'success', 3000)
                                elseif Config.Framework == "Standalone" then
                                    TriggerEvent('chat:addMessage', {
                                        color = { 0, 255, 0},
                                        multiline = true,
                                        args = {"Motor", coolMessage}
                                    })
                                end
                            end
                        else
                            -- Disable the vehicle engine while cooling down
                            SetVehicleEngineOn(vehicle, false, true, false)
                        end
                    end
                end
            else
                heatTimer = 0
                coolDownTimer = 0
                isEngineHeating = false
            end
        else
            heatTimer = 0
            coolDownTimer = 0
            isEngineHeating = false
        end
    end
end)

-- Whitelist Function
function isVehicleWhitelisted(vehicleName, vehicleModel)
    -- Check if the vehicle name or model is in the whitelisted vehicles list
    for _, whitelistedVehicle in ipairs(Config.WhitelistedVehicles) do
        if vehicleName == whitelistedVehicle or vehicleModel == whitelistedVehicle then
            return true
        end
    end
    -- Disable overheating for planes, boats, and trains
    local vehicleType = GetVehicleClassFromName(vehicleModel)
    if vehicleType == 14 or vehicleType == 15 or vehicleType == 16 or vehicleType == 21 then
        return true
    end
    return false
end

-- ESX and QBCore Water bottle to cooldown
-- if Config.Framework == "ESX" or Config.Framework == "QBCore" then
--     RegisterNetEvent('useWaterBottle')
--     AddEventHandler('useWaterBottle', function()
--         local playerPed = PlayerPedId()
--         if IsPedInAnyVehicle(playerPed, false) then
--             local vehicle = GetVehiclePedIsIn(playerPed, false)
--             local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
--             if isEngineHeating then
--                 TriggerServerEvent('engine:coolDownEngine', vehicleNetId)
--             end
--         end
--     end)
-- end

-- Handling incoming sync data
local vehicleSmokeEffects = {}

RegisterNetEvent('engine:syncOverheatStatus')
AddEventHandler('engine:syncOverheatStatus', function(vehicleNetId, isOverheating)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        if isOverheating then
            SetVehicleEngineOn(vehicle, false, true, false)
            StartVehicleSmokeEffect(vehicle)
        else
            SetVehicleEngineOn(vehicle, true, true, false)
            StopVehicleSmokeEffect(vehicle)
        end
    end
end)

function StartVehicleSmokeEffect(vehicle)
    if not IsEntityDead(vehicle) and not vehicleSmokeEffects[vehicle] then
        UseParticleFxAssetNextCall("core")
        local smokeEffect = StartParticleFxLoopedOnEntity("exp_grd_bzgas_smoke", vehicle, 0.0, -1.5, 0.5, 0.0, 0.0, 0.0, 1.0, false, false, false)
        vehicleSmokeEffects[vehicle] = smokeEffect
    end
end

function StopVehicleSmokeEffect(vehicle)
    local smokeEffect = vehicleSmokeEffects[vehicle]
    if smokeEffect then
        StopParticleFxLooped(smokeEffect, 0)
        vehicleSmokeEffects[vehicle] = nil
    end
end

-- Requesting initial sync upon joining or respawning
Citizen.CreateThread(function()
    TriggerServerEvent('engine:requestSync')
end)


