BWBaseConfig = {
    resourceName = "bw_base_system",

    -- Валюта.
    -- ВАЖНО: проверь название element data в своём DayZ.
    currency = {
        mode = "elementData",
        elementData = "bw:tokens",
    },

    -- Стоимость аренды за один день.
    pricePerDay = 100,

    minRentDays = 3,
    maxRentDays = 30,

    -- Максимальное число дополнительных игроков.
    maxMembers = 4,

    -- Лимит транспорта по умолчанию.
    defaultVehicleLimit = 1,

    -- Права администратора.
    adminACLGroup = "Admin",

    -- Файл базы SQLite создастся автоматически.
    databaseFile = "data.db",

    -- Список баз.
    -- Впиши свои координаты вместо nil.
    bases = {
        ["glendale_01"] = {
            name = "Глендейл — база №1",

            -- Вход снаружи.
            entrance = {
                x = 727.26361083984, y = -1328.2690429688, z = 13.539068222046,
                interior = 0,
                dimension = 0,
                markerSize = 1.5,
            },

            -- Точка появления внутри.
            inside = {
                x = 712.46142578125, y = -1320.1197509766, z = 13.398408889771,
                interior = 0,
                dimension = 0,
            },

            -- Выход из базы.
            exit = {
                x = 705.24224853516, y = -1320.2175292969, z = 13.423271179199,
                interior = 0,
                dimension = 0,
                markerSize = 1.5,
            },

            -- Точка управления базой внутри.
            management = {
                x = 698.67449951172, y = -1320.5084228516, z = 13.461763381958,
                interior = 0,
                dimension = 0,
                markerSize = 1.5,
            },

            -- Границы зоны для транспорта.
            -- До настройки зоны транспорт не будет автоматически
            -- замораживаться по координатам.
            vehicleZone = {
                minX = nil, maxX = nil,
                minY = nil, maxY = nil,
                minZ = nil, maxZ = nil,
            },

            vehicleLimit = 1,
        },
    },
}