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

local vehiclesOverheating = {}

RegisterNetEvent('engine:updateOverheatStatus')
AddEventHandler('engine:updateOverheatStatus', function(vehicleNetId, isOverheating)
    vehiclesOverheating[vehicleNetId] = isOverheating
    TriggerClientEvent('engine:syncOverheatStatus', -1, vehicleNetId, isOverheating) -- Broadcast to all clients
    if isOverheating then
        TriggerClientEvent('engine:triggerSmokeEffect', -1, vehicleNetId) -- Trigger smoke effect for all clients
    end
end)

RegisterNetEvent('engine:requestSync')
AddEventHandler('engine:requestSync', function()
    local src = source
    for vehicleNetId, isOverheating in pairs(vehiclesOverheating) do
        TriggerClientEvent('engine:syncOverheatStatus', src, vehicleNetId, isOverheating) -- Sync with newly joined players or upon request
    end
end)

-- Use Water bottle to cooldown engine
-- RegisterNetEvent('engine:coolDownEngine')
-- AddEventHandler('engine:coolDownEngine', function(vehicleNetId)
--     if vehiclesOverheating[vehicleNetId] then
--         vehiclesOverheating[vehicleNetId] = false
--         -- Reset the overheating status after a delay
--         SetTimeout(Config.CoolDownWithWaterTime * 1000, function()
--             TriggerClientEvent('engine:syncOverheatStatus', -1, vehicleNetId, false)
--         end)
--     end
-- end)