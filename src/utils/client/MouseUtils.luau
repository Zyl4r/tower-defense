--!strict
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local MouseUtils = {}

function MouseUtils.GetWorldPosition(filter: Instance): Vector3
    mouse.TargetFilter = filter
    return mouse.Hit.Position
end

function MouseUtils.GetMouseRay(params: RaycastParams): Vector3?
    local camera = workspace.CurrentCamera
    local viewportRay = camera:ViewportPointToRay(mouse.X, mouse.Y)

    local raycastResults = workspace:Raycast(viewportRay.Origin, viewportRay.Direction * 1000, params)

    if raycastResults then
        return raycastResults.Position
    end

    return nil
end

return MouseUtils
