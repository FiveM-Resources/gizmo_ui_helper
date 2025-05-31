local gizmoEnabled = false


local function DrawText3D(x, y, z, text)
  SetTextScale(0.4, 0.4)
  SetTextFont(0)
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextCentre(true)
  SetTextEntry("STRING")
  AddTextComponentString(text)
  SetDrawOrigin(x, y, z, 0)
  DrawText(0.0, 0.0)
  ClearDrawOrigin()
end

local function DrawGizmo(pos, heading, size)
  local xDir = vector3(pos.x + size, pos.y, pos.z)
  local yDir = vector3(pos.x, pos.y + size, pos.z)
  local zDir = vector3(pos.x, pos.y, pos.z + size)

  local xFormated = string.format("%.2f", pos.x)
  local yFormated = string.format("%.2f", pos.y)
  local zFormated = string.format("%.2f", pos.z)
  local hFormated = string.format("%.2f", heading)

  DrawLine(pos.x, pos.y, pos.z, xDir.x, xDir.y, xDir.z, 255, 0, 0, 255)
  DrawText3D(xDir.x, xDir.y, xDir.z, "X  " .. xFormated)

  DrawLine(pos.x, pos.y, pos.z, yDir.x, yDir.y, yDir.z, 0, 255, 0, 255)
  DrawText3D(yDir.x, yDir.y, yDir.z, "Y  " .. yFormated)

  DrawLine(pos.x, pos.y, pos.z, zDir.x, zDir.y, zDir.z, 0, 0, 255, 255)
  DrawText3D(zDir.x, zDir.y, zDir.z, "Z  " .. zFormated)

  local headingRad = math.rad(heading) + 90
  local hX = pos.x + size * math.cos(headingRad)
  local hY = pos.y + size * math.sin(headingRad)
  local hZ = pos.z
  DrawLine(pos.x, pos.y, pos.z, hX, hY, hZ, 255, 255, 0, 255)
  DrawText3D(hX, hY, hZ, "H  " .. hFormated)
end

local closestEntity = nil
local closestDistance = 10.0

local function UpdateClosestEntity()
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)

  local entities = {}

  local function TryAddEntities(findFirstFunc, findNextFunc, endFindFunc)
    local handle, entity = findFirstFunc()
    local success = true
    if not handle then return end
    repeat
      if DoesEntityExist(entity) and not IsEntityDead(entity) then
        local entCoords = GetEntityCoords(entity)
        if #(playerCoords - entCoords) <= closestDistance then
          table.insert(entities, entity)
        end
      end
      success, entity = findNextFunc(handle)
    until not success
    endFindFunc(handle)
  end

  TryAddEntities(FindFirstObject, FindNextObject, EndFindObject)

  TryAddEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)

  local handle, entity = FindFirstPed()
  local success = true
  if handle then
    repeat
      if DoesEntityExist(entity) and not IsEntityDead(entity) and entity ~= playerPed then
        local entCoords = GetEntityCoords(entity)
        if #(playerCoords - entCoords) <= closestDistance then
          table.insert(entities, entity)
        end
      end
      success, entity = FindNextPed(handle)
    until not success
    EndFindPed(handle)
  end

  local minDist = closestDistance
  local closest = nil
  for _, ent in ipairs(entities) do
    local entCoords = GetEntityCoords(ent)
    local dist = #(playerCoords - entCoords)
    if dist < minDist then
      minDist = dist
      closest = ent
    end
  end

  closestEntity = closest
end

Citizen.CreateThread(function()
  local tickCounter = 0
  while true do
    Citizen.Wait(0)

    if not gizmoEnabled then
      Citizen.Wait(200)
    else
      tickCounter = tickCounter + 1
      if tickCounter % 15 == 0 then
        UpdateClosestEntity()
      end

      local playerPed = PlayerPedId()
      local playerCoords = GetEntityCoords(playerPed)
      local heading = GetEntityHeading(playerPed)

      if closestEntity and DoesEntityExist(closestEntity) then
        local coords = GetEntityCoords(closestEntity)
        local heading = GetEntityHeading(closestEntity)
        DrawGizmo(coords, heading, 1.5)
      else
        DrawGizmo(playerCoords, heading, 1.2)
      end
    end
  end
end)

RegisterCommand("giz", function()
  gizmoEnabled = not gizmoEnabled
  print("Gizmo " .. (gizmoEnabled and "activé" or "désactivé"))
end, false)
