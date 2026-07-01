DECLARE MaxCityKey INT64;

SET MaxCityKey = 
(
    SELECT
        IFNULL(MAX(CityKey), 0)
    FROM
        {{ DimCities }}
);

CREATE TEMP TABLE TempDimCities AS
WITH changed_cities AS 
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
        DC.CityKey,
        cities.*, 
        CASE
            WHEN DC.WWICityID IS NOT NULL THEN CAST(TRUE AS BOOLEAN)
            ELSE CAST(FALSE AS BOOLEAN)
        END AS Exist
    FROM
        cities LEFT JOIN
        {{ DimCities }} DC ON
            DC.WWICityID = cities.CityID
        

    UNION ALL

    SELECT
        DC.CityKey,
        cities_archive.*,
        CASE
            WHEN DC.WWICityID IS NOT NULL THEN CAST(TRUE AS BOOLEAN)
            ELSE CAST(FALSE AS BOOLEAN)
        END AS Exist
    FROM
        cities_archive LEFT JOIN
        {{ DimCities }} DC ON
            DC.WWICityID = cities_archive.CityID

),

final AS 
(

    SELECT 
        CASE 
            WHEN C.CityKey IS NULL THEN CAST(MaxCityKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY C.Exist, C.CityID))
            ELSE C.CityKey
        END AS CityKey,
        C.CityID AS WWICityID,
        C.CityName AS City,
        S.StateProvinceName AS StateProvince,
        ST_GEOGFROMTEXT(C.Location) AS Location,
        CO.CountryName AS Country,
        CO.Continent AS Continent,
        S.SalesTerritory AS SalesTerritory,
        CO.Region AS Region,
        CO.Subregion AS Subregion,
        C.LatestRecordedPopulation AS LatestRecordedPopulation,
        C.Exist AS Exist,
        CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate
    FROM
        merged_cities C LEFT JOIN
        merged_states S ON
            S.StateProvinceID = C.StateProvinceID LEFT JOIN
        merged_countries CO ON
            CO.CountryID = S.CountryID
    
    UNION ALL

    SELECT
        0 AS CityKey,
        0 AS WWICityID,
        'Unknown' AS City,
        'N/A' AS StateProvince,
        NULL AS Location,
        'N/A' AS Country,
        'N/A' AS Continent,
        'N/A' AS SalesTerritory,
        'N/A' AS Region,
        'N/A' AS Subregion,
        0 AS LatestRecordedPopulation,
        FALSE AS Exist,
        CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate
    FROM
        (
            SELECT
                1
        )
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
FROM 
    final 
ORDER BY
    CityKey;

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
    LastLoadDate
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
    CAST(NULL AS DATETIME)
FROM
    TempDimCities
WHERE
    Exist = False;

-- Update Existing
UPDATE
    {{ DimCities }} DC
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
    DC.LastLoadDate = DC.LoadDate
FROM
    TempDimCities DCU
WHERE
    DCU.WWICityID = DC.WWICityID AND
    DCU.Exist = True;