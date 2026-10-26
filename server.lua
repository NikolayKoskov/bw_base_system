local cfg = BWBaseConfig
local db
local baseMarkers = {}
local protectedVehicles = {}

local function notify(player, message, r, g, b)
    if isElement(player) then
        triggerClientEvent(
            player, "bwbase:notify", resourceRoot,
            tostring(message), r or 220, g or 220, b or 220
        )
    end
end

local function validCoords(point)
    return type(point) == "table"
        and type(point.x) == "number"
        and type(point.y) == "number"
        and type(point.z) == "number"
end

local function getSerial(player)
    return isElement(player) and getPlayerSerial(player) or nil
end

local function isAdmin(player)
    if not isElement(player) then return false end

    local account = getPlayerAccount(player)
    if not account or isGuestAccount(account) then
        return false
    end

    local accountName = getAccountName(account)
    local group = aclGetGroup(cfg.adminACLGroup)

    return group and isObjectInACLGroup(
        "user." .. accountName, group
    ) or false
end

local function query(sql, ...)
    if not db then return false end
    return dbExec(db, sql, ...)
end

local function selectRows(sql, ...)
    if not db then return {} end

    local handle = dbQuery(db, sql, ...)
    local rows = dbPoll(handle, -1)

    return rows or {}
end

local function getBase(baseId)
    return cfg.bases[tostring(baseId)]
end

local function getBaseRecord(baseId)
    local rows = selectRows(
        "SELECT * FROM bases WHERE base_id = ?",
        tostring(baseId)
    )
    return rows[1]
end

local function ensureBase(baseId)
    local config = getBase(baseId)
    if not config then return nil end

    query([[
        INSERT OR IGNORE INTO bases
        (base_id, owner_serial, lease_until, is_open, vehicle_limit)
        VALUES (?, '', 0, 1, ?)
    ]], tostring(baseId), tonumber(config.vehicleLimit)
        or cfg.defaultVehicleLimit)

    return getBaseRecord(baseId)
end

local function isLeaseActive(record)
    return record
        and record.owner_serial
        and record.owner_serial ~= ""
        and tonumber(record.lease_until or 0) > os.time()
end

local function hasAccess(player, baseId)
    local record = getBaseRecord(baseId)
    local serial = getSerial(player)

    if not record or not serial or not isLeaseActive(record) then
        return false
    end

    if record.owner_serial == serial then
        return true
    end

    local rows = selectRows(
        "SELECT serial FROM base_members WHERE base_id = ? AND serial = ?",
        tostring(baseId), serial
    )

    return #rows > 0
end

local function isOwner(player, baseId)
    local record = getBaseRecord(baseId)
    return record and getSerial(player)
        and record.owner_serial == getSerial(player)
        and isLeaseActive(record) or false
end

local function getTokens(player)
    if cfg.currency.mode == "elementData" then
        return tonumber(getElementData(
            player, cfg.currency.elementData
        )) or 0
    end

    -- Неизвестный режим валюты: безопасно запрещаем оплату.
    return nil
end

local function takeTokens(player, amount)
    amount = tonumber(amount)
    if not amount or amount < 0 then return false end

    if cfg.currency.mode == "elementData" then
        local current = getTokens(player)
        if not current or current < amount then
            return false
        end

        setElementData(
            player, cfg.currency.elementData,
            current - amount, true
        )
        return true
    end

    return false
end

local function pointDistance(player, point)
    if not validCoords(point) then return math.huge end

    if getElementInterior(player) ~= (point.interior or 0)
        or getElementDimension(player) ~= (point.dimension or 0) then
        return math.huge
    end

    local x, y, z = getElementPosition(player)
    local dx, dy, dz = x - point.x, y - point.y, z - point.z

    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function nearPoint(player, point, maxDistance)
    return pointDistance(player, point) <= (maxDistance or 3)
end

local function createPoint(baseId, pointName, point, markerType)
    if not validCoords(point) then return end

    local marker = createMarker(
        point.x, point.y, point.z - 1,
        markerType or "cylinder",
        point.markerSize or 1.5,
        120, 25, 25, 160
    )

    if not marker then return end
    setElementData(marker, "bwbase:id", tostring(baseId), true)
    setElementData(marker, "bwbase:point", tostring(pointName), true)
    setElementInterior(marker, point.interior or 0)
    setElementDimension(marker, point.dimension or 0)

    baseMarkers[marker] = {
        baseId = baseId,
        pointName = pointName,
    }
end

local function createConfiguredMarkers()
    for baseId, base in pairs(cfg.bases) do
        ensureBase(baseId)

        createPoint(baseId, "entrance", base.entrance, "cylinder")
        createPoint(baseId, "exit", base.exit, "cylinder")
        createPoint(baseId, "management", base.management, "cylinder")
    end
end

local function sendMenu(player, baseId, mode)
    local base = getBase(baseId)
    local record = getBaseRecord(baseId)

    if not base or not record then return end

    local serial = getSerial(player)
    local owner = serial and record.owner_serial == serial
    local active = isLeaseActive(record)
    local access = hasAccess(player, baseId)

    local members = {}
    if owner then
        local rows = selectRows(
            "SELECT serial FROM base_members WHERE base_id = ?",
            tostring(baseId)
        )

        for _, row in ipairs(rows) do
            local memberSerial = row.serial
            local onlineName = "Не в сети"

            for _, p in ipairs(getElementsByType("player")) do
                if getSerial(p) == memberSerial then
                    onlineName = getPlayerName(p)
                    break
                end
            end

            members[#members + 1] = {
                serial = memberSerial,
                name = onlineName,
            }
        end
    end

    triggerClientEvent(player, "bwbase:openMenu", resourceRoot, {
        id = tostring(baseId),
        name = base.name,
        mode = mode or "outside",
        owner = owner or false,
        hasAccess = access,
        active = active or false,
        leaseUntil = tonumber(record.lease_until) or 0,
        isOpen = tonumber(record.is_open) == 1,
        vehicleLimit = tonumber(record.vehicle_limit)
            or cfg.defaultVehicleLimit,
        maxMembers = cfg.maxMembers,
        memberCount = #members,
        members = members,
        pricePerDay = cfg.pricePerDay,
        minRentDays = cfg.minRentDays,
        maxRentDays = cfg.maxRentDays,
        tokens = getTokens(player) or 0,
    })
end

addEvent("bwbase:interact", true)
addEventHandler("bwbase:interact", resourceRoot,
    function(baseId, pointName)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        local base = getBase(baseId)
        if not base then return end

        if pointName == "entrance" then
            if not nearPoint(player, base.entrance, 4) then return end
            sendMenu(player, baseId, "outside")

        elseif pointName == "exit" then
            if not nearPoint(player, base.exit, 4) then return end
            sendMenu(player, baseId, "inside")

        elseif pointName == "management" then
            if not nearPoint(player, base.management, 4) then return end
            if not hasAccess(player, baseId) then
                notify(player, "У вас нет доступа к этой базе.", 220, 70, 70)
                return
            end
            sendMenu(player, baseId, "inside")
        end
    end
)

addEvent("bwbase:rent", true)
addEventHandler("bwbase:rent", resourceRoot,
    function(baseId, days)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        days = math.floor(tonumber(days) or 0)

        local base = getBase(baseId)
        local record = getBaseRecord(baseId)

        if not base or not record then return end
        if not nearPoint(player, base.entrance, 5) then
            notify(player, "Арендовать базу можно у входа.", 220, 70, 70)
            return
        end

        if days < cfg.minRentDays or days > cfg.maxRentDays then
            notify(player, "Недопустимый срок аренды.", 220, 70, 70)
            return
        end

        if isLeaseActive(record) then
            notify(player, "Эта база уже арендована.", 220, 70, 70)
            return
        end

        local cost = days * cfg.pricePerDay
        if not takeTokens(player, cost) then
            notify(player, "Недостаточно токенов или валюта не настроена.", 220, 70, 70)
            return
        end

        local newExpiry = os.time() + days * 86400
        query([[
            UPDATE bases
            SET owner_serial = ?, lease_until = ?, is_open = 1
            WHERE base_id = ?
        ]], getSerial(player), newExpiry, baseId)

        query("DELETE FROM base_members WHERE base_id = ?", baseId)

        notify(player, "База арендована на " .. days .. " дн.", 100, 220, 120)
        sendMenu(player, baseId, "outside")
    end
)

addEvent("bwbase:extend", true)
addEventHandler("bwbase:extend", resourceRoot,
    function(baseId, days)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        days = math.floor(tonumber(days) or 0)

        local base = getBase(baseId)
        local record = getBaseRecord(baseId)

        if not base or not record or not isOwner(player, baseId) then
            notify(player, "Продлить аренду может только владелец.", 220, 70, 70)
            return
        end

        if days < cfg.minRentDays or days > cfg.maxRentDays then
            notify(player, "Недопустимый срок продления.", 220, 70, 70)
            return
        end

        local cost = days * cfg.pricePerDay
        if not takeTokens(player, cost) then
            notify(player, "Недостаточно токенов или валюта не настроена.", 220, 70, 70)
            return
        end

        local oldExpiry = math.max(os.time(), tonumber(record.lease_until) or 0)
        local newExpiry = oldExpiry + days * 86400

        query("UPDATE bases SET lease_until = ? WHERE base_id = ?",
            newExpiry, baseId)

        notify(player, "Аренда продлена на " .. days .. " дн.", 100, 220, 120)
        sendMenu(player, baseId, "inside")
    end
)

addEvent("bwbase:enter", true)
addEventHandler("bwbase:enter", resourceRoot,
    function(baseId)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        local base = getBase(baseId)
        if not base or not validCoords(base.inside) then
            notify(player, "Координаты внутри базы ещё не настроены.", 220, 70, 70)
            return
        end

        if not nearPoint(player, base.entrance, 5) then return end

        local record = getBaseRecord(baseId)
        if not record or not isLeaseActive(record) then
            notify(player, "База не арендована.", 220, 70, 70)
            return
        end

        if not hasAccess(player, baseId) then
            if tonumber(record.is_open) ~= 1 then
                notify(player, "База закрыта владельцем.", 220, 70, 70)
                return
            end
        end

        fadeCamera(player, false, 0.3)
        setTimer(function(p, b, id)
            if not isElement(p) then return end
            setElementInterior(p, b.inside.interior or 0)
            setElementDimension(p, b.inside.dimension or 0)
            setElementPosition(p, b.inside.x, b.inside.y, b.inside.z)
            fadeCamera(p, true, 0.3)
            triggerClientEvent(p, "bwbase:closeMenu", resourceRoot)
        end, 350, 1, player, base, baseId)
    end
)

addEvent("bwbase:exit", true)
addEventHandler("bwbase:exit", resourceRoot,
    function(baseId)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        local base = getBase(baseId)
        if not base or not validCoords(base.exit) then return end
        if not nearPoint(player, base.exit, 5) then return end

        -- Возвращаем игрока к наружному входу.
        if not validCoords(base.entrance) then
            notify(player, "Координаты выхода наружу не настроены.", 220, 70, 70)
            return
        end

        fadeCamera(player, false, 0.3)
        setTimer(function(p, b)
            if not isElement(p) then return end
            setElementInterior(p, b.entrance.interior or 0)
            setElementDimension(p, b.entrance.dimension or 0)
            setElementPosition(p, b.entrance.x, b.entrance.y, b.entrance.z)
            fadeCamera(p, true, 0.3)
            triggerClientEvent(p, "bwbase:closeMenu", resourceRoot)
        end, 350, 1, player, base)
    end
)

addEvent("bwbase:toggleOpen", true)
addEventHandler("bwbase:toggleOpen", resourceRoot,
    function(baseId, isOpen)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        if not isOwner(player, baseId) then return end

        query("UPDATE bases SET is_open = ? WHERE base_id = ?",
            isOpen and 1 or 0, baseId)

        notify(player, isOpen and "База открыта для посетителей."
            or "База закрыта для посторонних.", 100, 220, 120)
        sendMenu(player, baseId, "inside")
    end
)

addEvent("bwbase:requestOnlinePlayers", true)
addEventHandler("bwbase:requestOnlinePlayers", resourceRoot,
    function(baseId)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        if not isOwner(player, baseId) then return end

        local result = {}
        for _, p in ipairs(getElementsByType("player")) do
            if p ~= player then
                result[#result + 1] = {
                    name = getPlayerName(p),
                    serial = getSerial(p),
                }
            end
        end

        triggerClientEvent(player, "bwbase:onlinePlayers", resourceRoot, result)
    end
)

addEvent("bwbase:addMember", true)
addEventHandler("bwbase:addMember", resourceRoot,
    function(baseId, targetSerial)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        targetSerial = tostring(targetSerial or "")

        if not isOwner(player, baseId) then return end
        if targetSerial == "" or targetSerial == getSerial(player) then return end

        local rows = selectRows(
            "SELECT serial FROM base_members WHERE base_id = ?",
            baseId
        )

        for _, row in ipairs(rows) do
            if row.serial == targetSerial then
                notify(player, "Этот игрок уже имеет доступ.", 220, 190, 80)
                return
            end
        end

        if #rows >= cfg.maxMembers then
            notify(player, "Достигнут лимит участников базы.", 220, 70, 70)
            return
        end

        query(
            "INSERT INTO base_members (base_id, serial) VALUES (?, ?)",
            baseId, targetSerial
        )

        notify(player, "Игрок добавлен в список доступа.", 100, 220, 120)
        sendMenu(player, baseId, "inside")
    end
)

addEvent("bwbase:removeMember", true)
addEventHandler("bwbase:removeMember", resourceRoot,
    function(baseId, targetSerial)
        local player = client
        if not isElement(player) then return end

        baseId = tostring(baseId)
        targetSerial = tostring(targetSerial or "")
        if not isOwner(player, baseId) then return end

        query(
            "DELETE FROM base_members WHERE base_id = ? AND serial = ?",
            baseId, targetSerial
        )

        sendMenu(player, baseId, "inside")
    end
)

-- Администратор меняет лимит:
-- /bwbase_limit glendale_01 2
addCommandHandler("bwbase_limit", function(player, _, baseId, limit)
    if not isElement(player) or not isAdmin(player) then
        if isElement(player) then
            notify(player, "Недостаточно прав.", 220, 70, 70)
        end
        return
    end

    baseId = tostring(baseId or "")
    limit = math.floor(tonumber(limit) or -1)

    if not getBase(baseId) or limit < 0 or limit > 20 then
        outputChatBox(
            "Использование: /bwbase_limit <baseId> <0-20>",
            player, 255, 200, 80
        )
        return
    end

    ensureBase(baseId)
    query("UPDATE bases SET vehicle_limit = ? WHERE base_id = ?",
        limit, baseId)

    outputChatBox(
        "Лимит транспорта для " .. baseId .. " установлен: " .. limit,
        player, 100, 255, 120
    )
end)

addEventHandler("onResourceStart", resourceRoot, function()
    db = dbConnect("sqlite", cfg.databaseFile)
    if not db then
        outputDebugString("[bw_base_system] Не удалось открыть SQLite.", 1)
        return
    end

    query([[
        CREATE TABLE IF NOT EXISTS bases (
            base_id TEXT PRIMARY KEY,
            owner_serial TEXT NOT NULL DEFAULT '',
            lease_until INTEGER NOT NULL DEFAULT 0,
            is_open INTEGER NOT NULL DEFAULT 1,
            vehicle_limit INTEGER NOT NULL DEFAULT 1
        )
    ]])

    query([[
        CREATE TABLE IF NOT EXISTS base_members (
            base_id TEXT NOT NULL,
            serial TEXT NOT NULL,
            PRIMARY KEY (base_id, serial)
        )
    ]])

    createConfiguredMarkers()
    outputDebugString("[bw_base_system] Ресурс запущен.")
end)

-- Освобождаем ресурсы SQLite при остановке.
addEventHandler("onResourceStop", resourceRoot, function()
    if db then
        destroyElement(db)
        db = nil
    end
end)