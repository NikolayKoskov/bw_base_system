local sx, sy = guiGetScreenSize()
local menuData = nil
local menuOpen = false
local selectedDays = 3
local onlinePlayers = {}
local showPlayers = false
local selectedPlayer = 1
local activeMarker = nil

local panel = {
    w = 560,
    h = 430,
}

local function inside(x, y, w, h)
    local cx, cy = getCursorPosition()
    if not cx or not cy then return false end

    cx, cy = cx * sx, cy * sy
    return cx >= x and cx <= x + w
        and cy >= y and cy <= y + h
end

local function drawButton(x, y, w, h, label, color)
    local hovered = inside(x, y, w, h)
    local c = hovered and tocolor(95, 55, 40, 245)
        or (color or tocolor(45, 45, 45, 235))

    dxDrawRectangle(x, y, w, h, c)
    dxDrawRectangle(x, y + h - 2, w, 2, tocolor(160, 100, 65, 230))
    dxDrawText(label, x, y, x + w, y + h,
        tocolor(245, 238, 225), 1, "default-bold",
        "center", "center", true, true)
end

local function closeMenu()
    menuOpen = false
    showPlayers = false
    menuData = nil
    showCursor(false)
end

addEvent("bwbase:openMenu", true)
addEventHandler("bwbase:openMenu", resourceRoot, function(data)
    if type(data) ~= "table" then return end

    menuData = data
    menuOpen = true
    showPlayers = false
    selectedDays = math.max(3, tonumber(data.minRentDays) or 3)
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

addEventHandler("onClientRender", root, function()
    if not menuOpen or not menuData then return end

    local x = (sx - panel.w) / 2
    local y = (sy - panel.h) / 2
    local d = menuData

    dxDrawRectangle(x, y, panel.w, panel.h, tocolor(15, 16, 16, 242))
    dxDrawRectangle(x, y, panel.w, 48, tocolor(35, 37, 35, 250))
    dxDrawRectangle(x, y + 46, panel.w, 2, tocolor(155, 95, 55, 255))

    dxDrawText("BLACKWOOD  /  " .. tostring(d.name),
        x + 18, y, x + panel.w - 18, y + 46,
        tocolor(238, 218, 190), 1.05, "default-bold",
        "left", "center", true, false)

    local leaseText = d.active
        and ("Аренда до: " .. os.date("%d.%m.%Y %H:%M", d.leaseUntil))
        or "Статус: свободна"

    dxDrawText(leaseText, x + 22, y + 65, x + panel.w - 22, y + 90,
        tocolor(225, 225, 225), 1, "default", "left", "center")

    dxDrawText("Токены: " .. tostring(d.tokens or 0),
        x + 22, y + 92, x + panel.w - 22, y + 115,
        tocolor(215, 190, 135), 1, "default", "left", "center")

    if d.mode == "outside" then
        if not d.active then
            dxDrawText("Срок аренды: " .. selectedDays .. " дней",
                x + 22, y + 130, x + 300, y + 160,
                tocolor(235, 235, 235), 1, "default-bold", "left", "center")

            drawButton(x + 320, y + 130, 45, 30, "-", tocolor(55, 55, 55, 240))
            drawButton(x + 370, y + 130, 45, 30, "+", tocolor(55, 55, 55, 240))

            dxDrawText("Цена: " .. (selectedDays * (d.pricePerDay or 0))
                .. " токенов",
                x + 22, y + 165, x + panel.w - 22, y + 190,
                tocolor(215, 190, 135), 1, "default", "left", "center")

            drawButton(x + 22, y + 205, panel.w - 44, 38, "АРЕНДОВАТЬ БАЗУ")
        elseif d.hasAccess then
            drawButton(x + 22, y + 145, panel.w - 44, 40, "ВОЙТИ НА БАЗУ")
            if d.owner then
                drawButton(x + 22, y + 195, panel.w - 44, 36, "ПРОДЛИТЬ АРЕНДУ")
            end
        else
            dxDrawText("Эта база уже арендована.",
                x + 22, y + 145, x + panel.w - 22, y + 185,
                tocolor(220, 170, 130), 1, "default", "left", "center")
        end
    else
        dxDrawText("Транспорт: " .. tostring(d.vehicleLimit)
            .. " шт. максимум",
            x + 22, y + 125, x + panel.w - 22, y + 150,
            tocolor(220, 220, 220), 1, "default", "left", "center")

        dxDrawText("Доступ посторонним: "
            .. (d.isOpen and "ОТКРЫТ" or "ЗАКРЫТ"),
            x + 22, y + 153, x + panel.w - 22, y + 178,
            d.isOpen and tocolor(120, 220, 130) or tocolor(240, 110, 100),
            1, "default-bold", "left", "center")

        if d.owner then
            drawButton(x + 22, y + 190, 250, 34,
                d.isOpen and "ЗАКРЫТЬ БАЗУ" or "ОТКРЫТЬ БАЗУ")
            drawButton(x + 288, y + 190, 250, 34, "ДОБАВИТЬ ИГРОКА")
            drawButton(x + 22, y + 237, 250, 34, "ПРОДЛИТЬ АРЕНДУ")
        end

        drawButton(x + 22, y + 285, panel.w - 44, 34, "ВЫЙТИ ИЗ БАЗЫ")
    end

    drawButton(x + 22, y + panel.h - 52, panel.w - 44, 32, "ЗАКРЫТЬ МЕНЮ",
        tocolor(55, 40, 35, 245))

    if showPlayers then
        local px, py, pw, ph = (sx - 420) / 2, (sy - 300) / 2, 420, 300
        dxDrawRectangle(px, py, pw, ph, tocolor(12, 13, 13, 250))
        dxDrawRectangle(px, py, pw, 40, tocolor(40, 40, 38, 255))
        dxDrawText("ВЫБЕРИ ИГРОКА", px, py, px + pw, py + 40,
            tocolor(235, 215, 185), 1, "default-bold", "center", "center")

        if #onlinePlayers == 0 then
            dxDrawText("Нет доступных игроков онлайн.",
                px + 15, py + 65, px + pw - 15, py + 100,
                tocolor(220, 220, 220), 1, "default", "center", "center")
        else
            for i, p in ipairs(onlinePlayers) do
                local rowY = py + 48 + (i - 1) * 28
                if rowY < py + ph - 48 then
                    local color = i == selectedPlayer
                        and tocolor(105, 65, 40, 240)
                        or tocolor(35, 35, 35, 220)
                    dxDrawRectangle(px + 12, rowY, pw - 24, 25, color)
                    dxDrawText(p.name, px + 20, rowY, px + pw - 20, rowY + 25,
                        tocolor(240, 240, 240), 1, "default", "left", "center")
                end
            end
        end

        drawButton(px + 12, py + ph - 38, 190, 28, "ДОБАВИТЬ")
        drawButton(px + 218, py + ph - 38, 190, 28, "НАЗАД")
    end
end)

addEventHandler("onClientClick", root, function(button, state, cx, cy)
    if button ~= "left" or state ~= "down" then return end

    -- Принимаем клики только внутри открытого меню.
    if not menuOpen or not menuData then return end

    local x = (sx - panel.w) / 2
    local y = (sy - panel.h) / 2
    local d = menuData

    if showPlayers then
        local px, py, pw, ph = (sx - 420) / 2, (sy - 300) / 2, 420, 300

        if inside(px + 12, py + ph - 38, 190, 28) then
            local p = onlinePlayers[selectedPlayer]
            if p and p.serial then
                triggerServerEvent("bwbase:addMember", resourceRoot, d.id, p.serial)
                showPlayers = false
            end
            return
        end

        if inside(px + 218, py + ph - 38, 190, 28) then
            showPlayers = false
            return
        end

        for i, p in ipairs(onlinePlayers) do
            local rowY = py + 48 + (i - 1) * 28
            if rowY < py + ph - 48 and inside(px + 12, rowY, pw - 24, 25) then
                selectedPlayer = i
                return
            end
        end
        return
    end

    if inside(x + 22, y + panel.h - 52, panel.w - 44, 32) then
        closeMenu()
        return
    end

    if d.mode == "outside" then
        if not d.active then
            if inside(x + 320, y + 130, 45, 30) then
                selectedDays = math.max(d.minRentDays, selectedDays - 1)
                return
            end
            if inside(x + 370, y + 130, 45, 30) then
                selectedDays = math.min(d.maxRentDays, selectedDays + 1)
                return
            end
            if inside(x + 22, y + 205, panel.w - 44, 38) then
                if d.extendMode then
                triggerServerEvent("bwbase:extend", resourceRoot, d.id, selectedDays)
                else
                triggerServerEvent("bwbase:rent", resourceRoot, d.id, selectedDays)
            end
            return
            end
        elseif d.hasAccess then
            if inside(x + 22, y + 145, panel.w - 44, 40) then
                triggerServerEvent("bwbase:enter", resourceRoot, d.id)
                return
            end
            if d.owner and inside(x + 22, y + 195, panel.w - 44, 36) then
                showCursor(false)
                -- Для продления используем то же окно выбора срока.
                d.active = false
                d.mode = "outside"
                d.extendMode = true
                menuData = d
                showCursor(true)
                return
            end
        end
    else
        if d.owner then
            if inside(x + 22, y + 190, 250, 34) then
                triggerServerEvent("bwbase:toggleOpen", resourceRoot,
                    d.id, not d.isOpen)
                return
            end
            if inside(x + 288, y + 190, 250, 34) then
                triggerServerEvent("bwbase:requestOnlinePlayers", resourceRoot, d.id)
                return
            end
            if inside(x + 22, y + 237, 250, 34) then
                -- Продление будет отправлено после выбора срока.
                selectedDays = d.minRentDays or 3
                d.extendMode = true
                d.mode = "outside"
                d.active = false
                menuData = d
                return
            end
        end

        if inside(x + 22, y + 285, panel.w - 44, 34) then
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

    if key == "e" and isElement(activeMarker) then
        local baseId = getElementData(activeMarker, "bwbase:id")
        local pointName = getElementData(activeMarker, "bwbase:point")
        if baseId and pointName then
            triggerServerEvent("bwbase:interact", resourceRoot, baseId, pointName)
        end
    end
end)

addEventHandler("onClientMarkerHit", root, function(hitElement, matchingDimension)
    if hitElement ~= localPlayer or not matchingDimension then return end

    if getElementData(source, "bwbase:id") then
        activeMarker = source
        outputChatBox("[BlackWood] Нажми E для взаимодействия.", 220, 190, 140)
    end
end)

addEventHandler("onClientMarkerLeave", root, function(leaveElement)
    if leaveElement == localPlayer and activeMarker == source then
        activeMarker = nil
    end
end)