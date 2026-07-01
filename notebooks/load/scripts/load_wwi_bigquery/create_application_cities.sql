CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>`
(
    CityID INTEGER, 
    CityName STRING, 
    StateProvinceID INTEGER, 
    Location STRING, 
    LatestRecordedPopulation INTEGER, 
    LastEditedBy INTEGER, 
    ValidFrom DATETIME, 
    ValidTo DATETIME, 
    LoadDate DATETIME,
    NewColumn STRING
);