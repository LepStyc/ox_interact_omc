local CFG <const> = require 'config.props';
local Interact = {}
Interact.__index = Interact



function Interact:init()
    self.props = CFG

    if self.props and (#CFG.movable > 0) then
        for _, prop in pairs(CFG.movable) do
            exports.ox_target:addModel(prop.name, {
                {
                    name = 'interact_objects_' .. prop.name .. tostring(_),
                    label = prop.label,
                    onSelect = function(data)
                    end
                }
            })
        end
    end
end






Citizen.CreateThread(function()
    while true do

        if NetworkIsSessionStarted() then
            Interact:init()
            return
        end

        Citizen.Wait(0)
    
    end
end)