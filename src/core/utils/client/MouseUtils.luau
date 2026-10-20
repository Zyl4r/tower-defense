local Players = game:GetService("Players")

local player = Players.LocalPlayer

local MouseUtils = {}

function MouseUtils.GetWorldPosition(filter: Instance): Vector3
    local mouse = player:GetMouse()
    mouse.TargetFilter = filter
    return mouse.Hit.Position
end

function MouseUtils.GetMouseRay(params: RaycastParams): RaycastResult?
    local mouse = player:GetMouse()
    local camera = workspace.CurrentCamera
    local viewportRay = camera:ScreenPointToRay(mouse.X, mouse.Y)

    return workspace:Blockcast(CFrame.new(viewportRay.Origin), Vector3.one, viewportRay.Direction * 1000, params)
end

function MouseUtils.GetMouseTarget(filter: Instance): Instance
    local mouse = player:GetMouse()
    mouse.TargetFilter = filter
    return mouse.Target
end

return MouseUtils
