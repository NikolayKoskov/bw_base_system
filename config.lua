BWBaseConfig = {
    resourceName = "bw_base_system",

    -- Валюта BlackWood: Жетоны.
    -- Система читает и изменяет element data blackcurrency.
    currency = {
        mode = "elementData",
        elementData = "blackcurrency",
        displayName = "Жетоны",
    },

    -- Стоимость аренды за один день (в Жетонах).
    pricePerDay = 100,

    minRentDays = 3,
    maxRentDays = 30,

    maxMembers = 4,
    defaultVehicleLimit = 1,
    adminACLGroup = "Admin",
    databaseFile = "data.db",

    bases = {
        ["glendale_01"] = {
            name = "Глендейл — база №1",

            entrance = {
                x = 766.23522949219, y = -1324.3055419922, z = 13.510937690735,
                interior = 0,
                dimension = 0,
                markerSize = 1.5,
            },

            -- Дополнительный чекпоинт для заезда на автомобиле.
            -- Координаты можно отдельно подвинуть под въезд на территорию.
            vehicleEntrance = {
                x = 766.23522949219, y = -1327.3055419922, z = 13.510937690735,
                interior = 0,
                dimension = 0,
                markerSize = 3.0,
            },

            inside = {
                x = 770.74157714844, y = -1324.2495117188, z = 6.7467079162598,
                interior = 0,
                dimension = 0,
            },

            -- Точка парковки автомобиля внутри базы.
            vehicleInside = {
                x = 766.74966430664, y = -1322.1009521484, z = 7.0,
                rotation = 90,
                interior = 0,
                dimension = 0,
            },

            exit = {
                x = 761.48059082031, y = -1327.2570800781, z = 6.6553654670715,
                interior = 0,
                dimension = 0,
                markerSize = 1.5,
            },

            management = {
                x = 772.53674316406, y = -1318.3815917969, z = 6.7467079162598,
                interior = 0,
                dimension = 0,
                markerSize = 1.5,
            },

            vehicleZone = {
                minX = 759.953125, maxX = 773.54620361328,
                minY = -1328.8464355469, maxY = -1315.35546875,
                minZ = 6, maxZ = 12,
                interior = 0,
                dimension = 0,
            },

            vehicleLimit = 2,
        },
    },
}
