local sx, sy = guiGetScreenSize()

local menuData = nil
local menuOpen = false
local selectedDays = 3
local rentAction = "rent"
local onlinePlayers = {}
local showPlayers = false
local selectedPlayer = 1
local activeMarker = nil

local panel = { w = 600, h = 460 }

-- Палитра интерфейса BlackWood: тёмный графит и лесные зелёные оттенки.
-- Поддерживает тот же визуальный язык, что и игровые окна: спокойный фон,
-- зелёные активные элементы и светло-зелёные акценты без красно-медных кнопок.
local C = {
    shadow = tocolor(0, 0, 0, 170),
    panel = tocolor(12, 18, 15, 248),
    panel2 = tocolor(20, 31, 24, 250),
    panel3 = tocolor(29, 43, 33, 245),
    greenAccent = tocolor(57, 133, 76, 255),
    greenHover = tocolor(76, 161, 94, 255),
    highlight = tocolor(169, 218, 166, 255),
    text = tocolor(232, 239, 229, 255),
    muted = tocolor(153, 171, 154, 255),
    green = tocolor(115, 197, 126, 255),
    closed = tocolor(119, 145, 119, 255),
    border = tocolor(65, 94, 69, 220),
}

local function inside(x, y, w, h)
    local cx, cy = getCursorPosition()
    if not cx or not cy then return false end
    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w and cy >= y and cy <= y + h
end

local function drawButton(x, y, w, h, label, primary)
    local hovered = inside(x, y, w, h)
    local base = primary and C.greenAccent or C.panel3
    if hovered then
        base = primary and C.greenHover or tocolor(39, 65, 44, 250)
    end

    dxDrawRectangle(x, y, w, h, base)
    dxDrawRectangle(x, y, w, 1, C.border)
    dxDrawRectangle(x, y + h - 2, w, 2, primary and C.highlight or C.greenAccent)
    dxDrawText(label, x + 8, y, x + w - 8, y + h,
        C.text, 1, "default-bold", "center", "center", true, true)
end

local function drawLabel(label, x, y, w, h, color, scale, font, align)
    dxDrawText(label, x, y, x + w, y + h, color or C.text,
        scale or 1, font or "default", align or "left", "center", true, true)
end

local function closeMenu()
    menuOpen = false
    showPlayers = false
    menuData = nil
    rentAction = "rent"
    showCursor(false)
end

addEvent("bwbase:openMenu", true)
addEventHandler("bwbase:openMenu", resourceRoot, function(data)
    if type(data) ~= "table" then return end

    menuData = data
    menuOpen = true
    showPlayers = false
    rentAction = "rent"
    selectedDays = math.max(
        tonumber(data.minRentDays) or 3,
        math.min(tonumber(data.maxRentDays) or 30, selectedDays)
    )
    showCursor(true)
end)

addEvent("bwbase:closeMenu", true)
addEventHandler("bwbase:closeMenu", resourceRoot, closeMenu)

addEvent("bwbase:notify", true)
addEventHandler("bwbase:notify", resourceRoot, function(message, r, g, b)
    outputChatBox("[BlackWood] " .. tostring(message),
        tonumber(r) or 220, tonumber(g) or 220, tonumber(b) or 220)
end)

addEvent("bwbase:onlinePlayers", true)
addEventHandler("bwbase:onlinePlayers", resourceRoot, function(players)
    onlinePlayers = type(players) == "table" and players or {}
    selectedPlayer = 1
    showPlayers = true
end)

local function drawKeyPrompt()
    if menuOpen or not isElement(activeMarker) then return end

    local pointName = getElementData(activeMarker, "bwbase:point")
    local isVehiclePoint = pointName == "vehicleEntrance"
    local vehicle = getPedOccupiedVehicle(localPlayer)

    if isVehiclePoint and (not vehicle or getVehicleOccupant(vehicle, 0) ~= localPlayer) then
        return
    elseif not isVehiclePoint and vehicle then
        return
    end

    local w, h = 390, 54
    local x, y = (sx - w) / 2, sy - 122
    dxDrawRectangle(x + 2, y + 3, w, h, C.shadow)
    dxDrawRectangle(x, y, w, h, C.panel)
    dxDrawRectangle(x, y, 4, h, C.greenAccent)
    dxDrawRectangle(x + 13, y + 9, 40, 36, C.greenAccent)
    dxDrawText("E", x + 13, y + 9, x + 53, y + 45,
        C.text, 1.25, "default-bold", "center", "center")
    drawLabel("BLACKWOOD  /  ВЗАИМОДЕЙСТВИЕ", x + 65, y + 5, w - 78, 20,
        C.highlight, 0.82, "default-bold")
    drawLabel(isVehiclePoint and "Открыть меню въезда на автомобиле"
        or "Открыть меню базы", x + 65, y + 25, w - 78, 22,
        C.text, 1, "default")
end

addEventHandler("onClientRender", root, function()
    drawKeyPrompt()

    if not menuOpen or not menuData then return end

    local x, y = (sx - panel.w) / 2, (sy - panel.h) / 2
    local d = menuData

    dxDrawRectangle(x + 5, y + 6, panel.w, panel.h, C.shadow)
    dxDrawRectangle(x, y, panel.w, panel.h, C.panel)
    dxDrawRectangle(x, y, panel.w, 58, C.panel2)
    dxDrawRectangle(x, y, 5, panel.h, C.greenAccent)
    dxDrawRectangle(x + 5, y + 56, panel.w - 5, 2, C.greenAccent)
    dxDrawRectangle(x + 18, y + 15, 3, 28, C.highlight)

    drawLabel("BLACKWOOD", x + 32, y + 8, 220, 24, C.highlight, 1.12, "default-bold")
    drawLabel("СИСТЕМА БАЗ  /  ГЛЕНДЕЙЛ", x + 32, y + 31, 300, 17,
        C.muted, 0.8, "default-bold")
    drawLabel(string.upper(tostring(d.name or "БАЗА")), x + 300, y + 13,
        panel.w - 325, 28, C.text, 0.95, "default-bold", "right")

    local leaseText
    if d.active then
        leaseText = "АРЕНДА ДО  " .. os.date("%d.%m.%Y  %H:%M",
            tonumber(d.leaseUntil) or 0)
    else
        leaseText = "СТАТУС  /  СВОБОДНА"
    end

    dxDrawRectangle(x + 22, y + 75, panel.w - 44, 48, C.panel2)
    dxDrawRectangle(x + 22, y + 75, 3, 48, d.active and C.green or C.greenAccent)
    drawLabel(leaseText, x + 36, y + 77, 330, 22,
        d.active and C.green or C.highlight, 0.92, "default-bold")
    drawLabel("ЖЕТОНЫ  " .. tostring(d.tokens or 0), x + 36, y + 98,
        panel.w - 72, 19, C.highlight, 0.9, "default-bold")

    if d.mode == "outside" or d.mode == "vehicle" then
        if rentAction == "extend" or not d.active then
            drawLabel(rentAction == "extend" and "ПРОДЛЕНИЕ АРЕНДЫ"
                or "АРЕНДА БАЗЫ", x + 26, y + 137, 260, 25,
                C.text, 1, "default-bold")

            drawLabel("Срок: " .. selectedDays .. " дней", x + 26, y + 166,
                245, 34, C.text, 1.05, "default-bold")
            drawButton(x + 300, y + 166, 48, 34, "−", false)
            drawButton(x + 354, y + 166, 48, 34, "+", false)

            drawLabel("Стоимость: " .. (selectedDays * (d.pricePerDay or 0))
                .. " Жетонов", x + 26, y + 207, panel.w - 52, 25,
                C.highlight, 1, "default-bold")

            drawButton(x + 22, y + 247, panel.w - 44, 42,
                rentAction == "extend" and "ПРОДЛИТЬ АРЕНДУ" or "АРЕНДОВАТЬ БАЗУ", true)
            if rentAction == "extend" then
                drawLabel("Оплата спишется после подтверждения сервером.",
                    x + 25, y + 293, panel.w - 50, 22, C.muted, 0.85)
            else
                drawLabel("Минимум " .. tostring(d.minRentDays) .. " дн.  /  Максимум "
                    .. tostring(d.maxRentDays) .. " дн.",
                    x + 25, y + 293, panel.w - 50, 22, C.muted, 0.85)
            end
        elseif d.mode == "vehicle" then
            if d.hasAccess or d.isOpen then
                drawLabel("ВЪЕЗД НА АВТОМОБИЛЕ", x + 26, y + 143,
                    panel.w - 52, 27, C.text, 1.05, "default-bold")
                drawLabel("Вы и автомобиль будете перемещены на парковку базы.",
                    x + 26, y + 174, panel.w - 52, 27, C.muted, 0.92)
                drawButton(x + 22, y + 216, panel.w - 44, 44,
                    "ЗАЕХАТЬ НА БАЗУ", true)
                if d.owner then
                    drawButton(x + 22, y + 272, panel.w - 44, 36,
                        "ПРОДЛИТЬ АРЕНДУ", false)
                end
            else
                drawLabel("БАЗА УЖЕ АРЕНДОВАНА", x + 26, y + 155,
                    panel.w - 52, 30, C.highlight, 1.05, "default-bold")
                drawLabel("Владелец закрыл доступ для посторонних.",
                    x + 26, y + 190, panel.w - 52, 25, C.muted, 0.95)
            end
        elseif d.hasAccess or d.isOpen then
            drawLabel("ДОСТУП К БАЗЕ РАЗРЕШЁН", x + 26, y + 145,
                panel.w - 52, 27, C.green, 1, "default-bold")
            drawButton(x + 22, y + 185, panel.w - 44, 42, "ВОЙТИ НА БАЗУ", true)
            if d.owner then
                drawButton(x + 22, y + 239, panel.w - 44, 36,
                    "ПРОДЛИТЬ АРЕНДУ", false)
            end
        else
            drawLabel("ЭТА БАЗА УЖЕ АРЕНДОВАНА", x + 26, y + 155,
                panel.w - 52, 30, C.highlight, 1.05, "default-bold")
            drawLabel("Войти может владелец и игроки с доступом.",
                x + 26, y + 190, panel.w - 52, 25, C.muted, 0.95)
        end
    else
        drawLabel("ПАРАМЕТРЫ БАЗЫ", x + 26, y + 132,
            panel.w - 52, 24, C.highlight, 0.95, "default-bold")
        drawLabel("Транспорт: " .. tostring(d.vehicleLimit or 1)
            .. " шт.  /  Доступ посторонним: "
            .. (d.isOpen and "ОТКРЫТ" or "ЗАКРЫТ"),
            x + 26, y + 158, panel.w - 52, 25,
            d.isOpen and C.green or C.closed, 0.92, "default-bold")

        if d.owner then
            drawButton(x + 22, y + 197, 267, 36,
                d.isOpen and "ЗАКРЫТЬ ДОСТУП" or "ОТКРЫТЬ ДОСТУП", false)
            drawButton(x + 299, y + 197, 279, 36, "ДОБАВИТЬ ИГРОКА", true)
            drawButton(x + 22, y + 244, panel.w - 44, 34,
                "ПРОДЛИТЬ АРЕНДУ", false)

            drawLabel("УЧАСТНИКИ БАЗЫ", x + 26, y + 286,
                panel.w - 52, 20, C.highlight, 0.82, "default-bold")
            local members = type(d.members) == "table" and d.members or {}
            if #members == 0 then
                drawLabel("Дополнительных участников нет.", x + 26, y + 307,
                    panel.w - 52, 20, C.muted, 0.86)
            else
                for i, member in ipairs(members) do
                    if i <= 4 then
                        drawLabel("•  " .. tostring(member.name or "Игрок"),
                            x + 28, y + 304 + (i - 1) * 19, 330, 19, C.text, 0.82)
                    end
                end
            end
            drawButton(x + 22, y + 365, panel.w - 44, 32, "ВЫЙТИ ИЗ БАЗЫ", true)
        else
            drawLabel("Вы находитесь внутри арендованной базы.",
                x + 26, y + 205, panel.w - 52, 25, C.muted, 0.95)
            drawButton(x + 22, y + 265, panel.w - 44, 40, "ВЫЙТИ ИЗ БАЗЫ", true)
        end
    end

    drawButton(x + 22, y + panel.h - 42, panel.w - 44, 28, "ЗАКРЫТЬ ОКНО", false)

    if showPlayers then
        local pw, ph = 430, 320
        local px, py = (sx - pw) / 2, (sy - ph) / 2
        dxDrawRectangle(px + 4, py + 5, pw, ph, C.shadow)
        dxDrawRectangle(px, py, pw, ph, C.panel)
        dxDrawRectangle(px, py, pw, 46, C.panel2)
        dxDrawRectangle(px, py, 4, ph, C.greenAccent)
        drawLabel("BLACKWOOD  /  ВЫБОР ИГРОКА", px + 18, py, pw - 36, 46,
            C.highlight, 0.95, "default-bold")

        if #onlinePlayers == 0 then
            drawLabel("Нет доступных игроков онлайн.", px + 16, py + 65,
                pw - 32, 35, C.muted, 0.95)
        else
            for i, p in ipairs(onlinePlayers) do
                local rowY = py + 56 + (i - 1) * 31
                if rowY < py + ph - 52 then
                    dxDrawRectangle(px + 14, rowY, pw - 28, 27,
                        i == selectedPlayer and C.greenAccent or C.panel2)
                    drawLabel(tostring(p.name or "Игрок"), px + 24, rowY,
                        pw - 48, 27, C.text, 0.9)
                end
            end
        end

        drawButton(px + 14, py + ph - 42, 194, 30, "ДОБАВИТЬ", true)
        drawButton(px + 222, py + ph - 42, 194, 30, "НАЗАД", false)
    end
end)

addEventHandler("onClientClick", root, function(button, state)
    if button ~= "left" or state ~= "down" or not menuOpen or not menuData then return end

    local x, y = (sx - panel.w) / 2, (sy - panel.h) / 2
    local d = menuData

    if showPlayers then
        local pw, ph = 430, 320
        local px, py = (sx - pw) / 2, (sy - ph) / 2

        if inside(px + 14, py + ph - 42, 194, 30) then
            local p = onlinePlayers[selectedPlayer]
            if p and p.serial then
                triggerServerEvent("bwbase:addMember", resourceRoot, d.id, p.serial)
                showPlayers = false
            end
            return
        elseif inside(px + 222, py + ph - 42, 194, 30) then
            showPlayers = false
            return
        end

        for i, p in ipairs(onlinePlayers) do
            local rowY = py + 56 + (i - 1) * 31
            if rowY < py + ph - 52 and inside(px + 14, rowY, pw - 28, 27) then
                selectedPlayer = i
                return
            end
        end
        return
    end

    if inside(x + 22, y + panel.h - 42, panel.w - 44, 28) then
        closeMenu()
        return
    end

    if d.mode == "outside" or d.mode == "vehicle" then
        if rentAction == "extend" or not d.active then
            if inside(x + 300, y + 166, 48, 34) then
                selectedDays = math.max(tonumber(d.minRentDays) or 3, selectedDays - 1)
                return
            elseif inside(x + 354, y + 166, 48, 34) then
                selectedDays = math.min(tonumber(d.maxRentDays) or 30, selectedDays + 1)
                return
            elseif inside(x + 22, y + 247, panel.w - 44, 42) then
                if rentAction == "extend" then
                    triggerServerEvent("bwbase:extend", resourceRoot, d.id, selectedDays)
                else
                    triggerServerEvent("bwbase:rent", resourceRoot, d.id, selectedDays)
                end
                return
            end
        elseif d.mode == "vehicle" then
            if (d.hasAccess or d.isOpen) and inside(x + 22, y + 216, panel.w - 44, 44) then
                triggerServerEvent("bwbase:enterVehicle", resourceRoot, d.id)
                return
            end
            if d.owner and inside(x + 22, y + 272, panel.w - 44, 36) then
                rentAction = "extend"
                selectedDays = tonumber(d.minRentDays) or 3
                return
            end
        else
            if (d.hasAccess or d.isOpen) and inside(x + 22, y + 185, panel.w - 44, 42) then
                triggerServerEvent("bwbase:enter", resourceRoot, d.id)
                return
            end
            if d.owner and inside(x + 22, y + 239, panel.w - 44, 36) then
                rentAction = "extend"
                selectedDays = tonumber(d.minRentDays) or 3
                return
            end
        end
    else
        if d.owner then
            if inside(x + 22, y + 197, 267, 36) then
                triggerServerEvent("bwbase:toggleOpen", resourceRoot, d.id, not d.isOpen)
                return
            elseif inside(x + 299, y + 197, 279, 36) then
                triggerServerEvent("bwbase:requestOnlinePlayers", resourceRoot, d.id)
                return
            elseif inside(x + 22, y + 244, panel.w - 44, 34) then
                rentAction = "extend"
                menuData.mode = "outside"
                selectedDays = tonumber(d.minRentDays) or 3
                return
            elseif inside(x + 22, y + 365, panel.w - 44, 32) then
                triggerServerEvent("bwbase:exit", resourceRoot, d.id)
                return
            end
        elseif inside(x + 22, y + 265, panel.w - 44, 40) then
            triggerServerEvent("bwbase:exit", resourceRoot, d.id)
            return
        end
    end
end)

addEventHandler("onClientKey", root, function(key, press)
    if not press then return end

    if key == "escape" and menuOpen then
        cancelEvent()
        closeMenu()
        return
    end

    if key == "e" and not menuOpen and isElement(activeMarker) then
        local baseId = getElementData(activeMarker, "bwbase:id")
        local pointName = getElementData(activeMarker, "bwbase:point")
        if baseId and pointName then
            triggerServerEvent("bwbase:interact", resourceRoot, baseId, pointName)
            cancelEvent()
        end
    end
end)

addEventHandler("onClientMarkerHit", root, function(hitElement, matchingDimension)
    if not matchingDimension then return end

    local pointName = getElementData(source, "bwbase:point")
    if not pointName or not getElementData(source, "bwbase:id") then return end

    local vehicle = getPedOccupiedVehicle(localPlayer)
    local hitPlayer = hitElement == localPlayer and not vehicle
    local hitVehicle = vehicle and hitElement == vehicle
        and getVehicleOccupant(vehicle, 0) == localPlayer

    if pointName == "vehicleEntrance" then
        if hitVehicle then activeMarker = source end
    elseif hitPlayer then
        activeMarker = source
    end
end)

addEventHandler("onClientMarkerLeave", root, function(leaveElement)
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if leaveElement == localPlayer or (vehicle and leaveElement == vehicle) then
        if activeMarker == source then activeMarker = nil end
    end
end)

addEventHandler("onClientVehicleExit", root, function(player)
    if player == localPlayer and isElement(activeMarker)
        and getElementData(activeMarker, "bwbase:point") == "vehicleEntrance" then
        activeMarker = nil
    end
end)
