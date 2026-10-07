--!strict
-- Phase 0 catalog. Road volumes and enforcement are implemented in phases 2/5.
return table.freeze({
    Residential = table.freeze({ RoadId = "residential", SpeedLimit = 30, RoadType = "Residential", District = "Residential", PoliceEnabled = true }),
    City = table.freeze({ RoadId = "city", SpeedLimit = 50, RoadType = "City", District = "Downtown", PoliceEnabled = true }),
    MainRoad = table.freeze({ RoadId = "main", SpeedLimit = 70, RoadType = "MainRoad", District = "Industrial", PoliceEnabled = true }),
    Highway = table.freeze({ RoadId = "highway", SpeedLimit = 90, RoadType = "Highway", District = "Highway", PoliceEnabled = true }),
})
