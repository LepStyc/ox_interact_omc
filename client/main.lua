local CFG <const> = require 'config.props';
local CFGSpawn <const> = require 'config.spawn';
local Interact = {}
Interact.__index = Interact



function Interact:init()
    self.props = CFG

    if self.props and (#CFG.movable > 0) then
        for _, prop in pairs(CFG.movable) do
            exports.ox_target:addModel(prop.name, {
                {
                    name = 'interact_objects_' .. prop.name .. tostring(_),
                    label = 'Se placer sur: ' .. prop.label,
                    icon = prop.type,
                    onSelect = function(data)
                        Interact:interactObject(data, prop.name)
                    end
                },
                {
                    name = 'interact_objects_' .. prop.name .. tostring(_),
                    label = 'Prendre: ' .. prop.label,
                    icon = prop.type,
                    onSelect = function(data)
                        Interact:moveObject(data, prop.name)
                    end
                }
            })
        end
    end
end


---@param data table
---@param propName string
function Interact:moveObject(data, propName)
    lib.print.info("Move object")
    local pPed <const> = PlayerPedId()
    local model <const> = data.entity
    print(model)

    if ((model ~= nil) and (DoesEntityExist(model))) then
        self.isCarrying = not IsEntityAttached(model)

        if (self.isCarrying) then
            lib.print.info("Attach entity")
            AttachEntityToEntity(model, pPed, pPed, -0.05, 1.5, -0.55, 180.0, 180.0, 180.0, false, false, false, false, 2, true)
            lib.requestAnimDict('anim@heists@box_carry@')
            lib.waitFor(function()
                return HasAnimDictLoaded('anim@heists@box_carry@')
            end)

            if (not IsEntityPlayingAnim(pPed, 'anim@heists@box_carry@', 'idle', 3)) then
                TaskPlayAnim(pPed, 'anim@heists@box_carry@', 'idle', 1.0, 1.0, -1, 50, 0, false, false, false)
            end

            FreezeEntityPosition(model, false)
        else
            lib.print.info("Detach entity")
            DetachEntity(model, true, true)
            Wait(100)
            PlaceObjectOnGroundProperly(model)
        end

        while (self.isCarrying) do
            Citizen.Wait(0)

            self:notification("Press ~INPUT_CONTEXT~ to drop the object")
            if IsControlJustPressed(0, 51) then
                DetachEntity(model, true, false)
                ClearPedTasks(pPed)
                FreezeEntityPosition(model, true)
                self.isCarrying = false
            end
        end
    end
end

---@param data table 
---@param propName string
function Interact:interactObject(data, propName)
    local pPed <const> = PlayerPedId()
    local pCoords <const> = GetEntityCoords(pPed)

    if ((#(pCoords - data.coords) > 2.0) and (data?.entity == nil)) then
        return
    end

    self.ped = pPed;
    self.pCoords = pCoords;
    self.entity = data?.entity;
    self.propName = propName;
    self:setPlayerAnimation()
end


function Interact:setPlayerAnimation()

    if DoesEntityExist(self.entity) then
        local animData <const> = self.props.animations[self.propName];
        
        if animData then
            self.options = {}

            for _, anim in pairs(animData) do
                table.insert(self.options, {
                    label = anim.label,
                    description = "Play animation '" .. anim.animName .. "'",
                    onSelect = function(data)
                        self:playSpecificAnimation(anim)
                    end,
                    icon = 'fas fa-play',
                })
            end

            self:registerContext()
        else
            lib.print.error("No animations found for this object")
        end
    else
        lib.print.error("No entity found")
    end
end


---@param data table
function Interact:playSpecificAnimation(data)
    local animName <const> = data.animName;
    local animDict <const> = data.animDict;

    lib.requestAnimDict(animName)
    lib.waitFor(function()
        return HasAnimDictLoaded(animName)
    end)

    TaskPlayAnim(self.ped, animName, animDict, 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(300)
    AttachEntityToEntity(self.ped, self.entity, 0, data.x, data.y, data.z, 0.0, 0.0, data.r, false, false, false, false, 2, true)

    self:showActions()
end



---@param msg string
---@param thisFrame boolean | nil
---@param beep boolean | nil
---@param duration number | nil
function Interact:notification(msg, thisFrame, beep, duration)
    AddTextEntry("Interact_notification", msg)
    if thisFrame then
        DisplayHelpTextThisFrame("Interact_notification", false)
    else
        BeginTextCommandDisplayHelp("Interact_notification")
        EndTextCommandDisplayHelp(0, false, beep == nil or beep, duration or -1)
    end
end


function Interact:showActions()
    while true do
        
        self:notification("Press ~INPUT_CONTEXT~ to drop the object")
        if IsControlJustReleased(0, 51) then
            DetachEntity(self.ped, true, false)
            ClearPedTasks(self.ped)
            break
        end

        Citizen.Wait(0)
    end
end


function Interact:registerContext()
    lib.registerContext({
        id = "animationMenu",
        title = "Select Animation",
        options = self.options,
        onExit = function()
            self.isCarrying = false
        end,
    })

    self:showContext("animationMenu")   
end


function Interact:showContext(context)
    lib.showContext(context)
end










local Spawn = {}
Spawn.__index = Spawn



---@param modelName string
function Spawn:createObject(modelName)
    local ped <const> = PlayerPedId()
    local pCoords <const> = GetOffsetFromEntityInWorldCoords(ped, 1.3, 1.3, -0.5)
    local model <const> = GetHashKey(modelName)

    lib.requestModel(model);
    lib.waitFor(function()
        return HasModelLoaded(model)
    end)

    local obj = CreateObject(model, pCoords.x, pCoords.y, pCoords.z, true, false, false) 
    PlaceObjectOnGroundProperly(obj)    
    SetModelAsNoLongerNeeded(obj)
    table.insert(self.objects, obj)
end


function Spawn:addRadialItem()
    lib.registerRadial({
        id = 'omc_menu',
        items = self.options
    })
end

function Spawn:refresh()
    self.options = {}

    if ((CFGSpawn ~= nil) and (#CFGSpawn > 0)) then
        for i=1, #CFGSpawn do
            local spawn = CFGSpawn[i]
            if ((spawn.label ~= nil) and (spawn.model ~= nil)) then
                table.insert(self.options, {
                    label = spawn.label,
                    icon = 'fas fa-box',
                    onSelect = function()
                        self:createObject(spawn?.model)
                    end
                })
            end
        end

        if (#self.options > 0) then
            self:addRadialItem()
        end
    end
end

function Spawn:init()
    self.objects = {}
    self:refresh()

    lib.addRadialItem({
        {
            id = 'omc_spawn',
            label = 'Object O.M.C',
            icon = 'fas fa-box',
            menu = 'omc_menu'
        }
    })
end


function Spawn:removeAll()
    if (self.objects and (#self.objects > 0)) then
        for i=1, #self.objects do
            local obj = self.objects[i]
            if DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
    end
end



Citizen.CreateThread(function()
    while true do

        if NetworkIsSessionStarted() then
            Interact:init()
            Spawn:init()
            return
        end

        Citizen.Wait(0)
    
    end
end)




AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return 
    end

    Spawn:removeAll()
end)