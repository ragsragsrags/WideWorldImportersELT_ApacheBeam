DECLARE @MaxCityKey INT 
    
SELECT
    @MaxCityKey = ISNULL(MAX(CityKey), 0)
FROM
    {{ DimCities }}

IF OBJECT_ID('tempdb..#DimCities') IS NOT NULL
    DROP TABLE #DimCities

;WITH changed_cities AS 
(

    SELECT
    	C.CityID,
    	C.CityName,
    	C.Location,
    	C.LatestRecordedPopulation,
    	C.StateProvinceID
    FROM
    	{{ ApplicationCities }} AS C
    WHERE
        C.ValidFrom > '<< LastCutoffDate >>' AND
    	'<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 
    
    UNION ALL
    
    SELECT
    	CA.CityID,
    	CA.CityName,
    	CA.Location,
    	CA.LatestRecordedPopulation,
    	CA.StateProvinceID
    FROM
    	{{ ApplicationCitiesArchive }} AS CA
    WHERE
        CA.ValidFrom > '<< LastCutoffDate >>' AND
    	'<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo 

),

changed_states AS
(

    SELECT
    	SP.StateProvinceID,
    	SP.CountryID,
    	SP.StateProvinceName,
    	SP.SalesTerritory
    FROM
        {{ ApplicationStateProvinces }} AS SP
    WHERE
        SP.ValidFrom > '<< LastCutoffDate >>' AND
    	'<< NewCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo 
    
    UNION ALL
    
    SELECT
    	SPA.StateProvinceID,
    	SPA.CountryID,
    	SPA.StateProvinceName,
    	SPA.SalesTerritory
    FROM
    	{{ ApplicationStateProvincesArchive }} AS SPA
    WHERE
        SPA.ValidFrom > '<< LastCutoffDate >>' AND
    	'<< NewCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo

),

changed_countries AS 
(

    SELECT
    	C.CountryID,
    	C.CountryName,
    	C.Continent,
    	C.Region,
    	C.Subregion
    FROM
    	{{ ApplicationCountries }} AS C
    WHERE
        C.ValidFrom > '<< LastCutoffDate >>' AND
    	'<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 
    
    UNION ALL
    
    SELECT
    	CA.CountryID,
    	CA.CountryName,
    	CA.Continent,
    	CA.Region,
    	CA.Subregion
    FROM
    	{{ ApplicationCountriesArchive }} CA
    WHERE
        CA.ValidFrom > '<< LastCutoffDate >>' AND
    	'<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo

),

merged_states AS 
(
       
    SELECT
        *
    FROM
        {{ ApplicationStateProvinces }} SP 
    WHERE
        '<< NewCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo

    UNION ALL

    SELECT
        *
    FROM
        {{ ApplicationStateProvincesArchive }} SPA
    WHERE
        '<< NewCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo

),

merged_countries AS 
(
       
    SELECT
        *
    FROM
        {{ ApplicationCountries }} C 
    WHERE
        '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

    UNION ALL

    SELECT
        *
    FROM
        {{ ApplicationCountriesArchive }} CA
    WHERE
        '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo

),

cities AS
(

    SELECT
        cities.*
    FROM
        {{ ApplicationCities }} AS cities JOIN
        merged_states ON
            cities.StateProvinceID = merged_states.StateProvinceID
    WHERE
        (
            cities.ValidFrom > '<< LastCutoffDate >>' OR
            cities.StateProvinceID IN
            (
                SELECT
                    changed_states.StateProvinceID
                FROM
                    changed_states
            ) OR
            merged_states.CountryID IN
            (
                SELECT
                    changed_countries.CountryID
                FROM
                    changed_countries
            )
        ) AND
        '<< NewCutoffDate >>' BETWEEN cities.ValidFrom AND cities.ValidTo

),

cities_archive AS 
(

    SELECT
        cities_archive.*
    FROM
        {{ ApplicationCitiesArchive }} AS cities_archive JOIN
        merged_states ON
            cities_archive.StateProvinceID = merged_states.StateProvinceID
    WHERE
        (
            cities_archive.ValidFrom > '<< LastCutoffDate >>' OR
            cities_archive.StateProvinceID IN
            (
                SELECT
                    changed_states.StateProvinceID
                FROM
                    changed_states
            ) OR
            merged_states.CountryID IN
            (
                SELECT
                    changed_countries.CountryID
                FROM
                    changed_countries
            )
        ) AND
        '<< NewCutoffDate >>' BETWEEN cities_archive.ValidFrom AND cities_archive.ValidTo

),

merged_cities AS
(

    SELECT
        [CityKey] = DC.CityKey,
        cities.*,
        [Exists] = 
            CASE
                WHEN DC.WWICityID IS NOT NULL THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END
    FROM
        cities LEFT JOIN
        {{ DimCities }} DC ON
            DC.WWICityID = cities.CityID
        

    UNION ALL

    SELECT
        [CityKey] = DC.CityKey,
        cities_archive.*,
        [Exists] = 
            CASE
                WHEN DC.WWICityID IS NOT NULL THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END
    FROM
        cities_archive LEFT JOIN
        {{ DimCities }} DC ON
            DC.WWICityID = cities_archive.CityID

),

final AS 
(

    SELECT
        [CityKey] = 
            CASE 
                WHEN C.CityKey IS NULL THEN @MaxCityKey + (ROW_NUMBER() OVER (ORDER BY C.[Exists], C.[CityID]))
                ELSE C.CityKey
            END,
        [WWICityID] = C.CityID,
        [City] = C.CityName,
        [StateProvince] = S.StateProvinceName,
        [StateProvinceCode] = S.StateProvinceCode,
        [Location] = CAST(C.[Location] AS varbinary(MAX)),
        [Country] = CO.CountryName,
        [Continent] = CO.Continent,
        [SalesTerritory] = S.SalesTerritory,
        [Region] = CO.Region,
        [Subregion] = CO.Subregion,
        [LatestRecordedPopulation] = C.LatestRecordedPopulation,
        [Exists] = C.[Exists],
        [LoadDate] = '<< NewCutoffDate >>'
    FROM
        merged_cities C LEFT JOIN
        merged_states S ON
            S.StateProvinceID = C.StateProvinceID LEFT JOIN
        merged_countries CO ON
            CO.CountryID = S.CountryID
    
    UNION ALL

    SELECT
        [CityKey] = 0,
        [WWICityID] = 0,
        [City] = 'Unknown',
        [StateProvince] = 'N/A',
        [StateProvinceCode] = 'N/A',
        [Location] = CAST(NULL AS VARBINARY(MAX)),
        [Country] = 'N/A',
        [Continent] = 'N/A',
        [SalesTerritory] = 'N/A',
        [Region] = 'N/A',
        [Subregion] = 'N/A',
        [LatestRecordedPopulation] = 0,
        [Exists] = 0,
        [LoadDate] = '<< NewCutoffDate >>'
    WHERE
        NOT EXISTS 
        (
            SELECT 
                1
            FROM
                {{ DimCities }}
            WHERE
                CityKey = 0
        )

)

SELECT
    *
INTO 
    #DimCities
FROM 
    final 
ORDER BY
    [CityKey]

BEGIN TRAN

-- Insert New
INSERT INTO {{ DimCities }}
(
    CityKey,
    WWICityID,
    City,
    StateProvince,
    Location,
    Country,
    Continent,
    SalesTerritory,
    Region,
    Subregion,
    LatestRecordedPopulation,
    LoadDate,
    StateProvinceCode
)
SELECT
    CityKey,
    WWICityID,
    City,
    StateProvince,
    Location,
    Country,
    Continent,
    SalesTerritory,
    Region,
    Subregion,
    LatestRecordedPopulation,
    LoadDate,
    StateProvinceCode
FROM
    #DimCities
WHERE
    [Exists] = 0

-- Update Existing
UPDATE
    DC
SET 
    DC.CityKey = DCU.CityKey,
    DC.WWICityID = DCU.WWICityID,
    DC.City = DCU.City,
    DC.StateProvince = DCU.StateProvince,
    DC.Location = DCU.Location,
    DC.Country = DCU.Country,
    DC.Continent = DCU.Continent,
    DC.SalesTerritory = DCU.SalesTerritory,
    DC.Region = DCU.Region,
    DC.Subregion = DCU.Subregion,
    DC.LatestRecordedPopulation = DCU.LatestRecordedPopulation,
    DC.LoadDate = DCU.LoadDate,
    DC.StateProvinceCode = DCU.StateProvinceCode
FROM
    {{ DimCities }} DC JOIN
    #DimCities DCU ON
        DCU.WWICityID = DC.WWICityID
WHERE
    [Exists] = 1

COMMIT TRAN