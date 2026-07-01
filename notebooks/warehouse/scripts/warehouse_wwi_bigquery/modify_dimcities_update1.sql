CREATE TEMP TABLE ModifiedCities AS
WITH merged_states AS 
(
       
    SELECT
        *
    FROM
        {{ ApplicationStateProvinces }} SP 
    WHERE
        '<< LastCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo

    UNION ALL

    SELECT
        *
    FROM
        {{ ApplicationStateProvincesArchive }} SPA
    WHERE
        '<< LastCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo

),

merged_cities AS
(
    SELECT
        *
    FROM
        {{ ApplicationCities }} SP 
    WHERE
        '<< LastCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo

    UNION ALL

    SELECT
        *
    FROM
        {{ ApplicationCitiesArchive }} SPA
    WHERE
        '<< LastCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo
),

cities AS 
(

    SELECT
    	MC.CityID AS WWICityID,
        MS.StateProvinceCode AS StateProvinceCode
    FROM
    	merged_cities MC LEFT JOIN
        merged_states MS ON
            MS.StateProvinceID = MC.StateProvinceID

)

SELECT
    *
FROM
    cities;

UPDATE
    {{ DimCities }} DC
SET 
    DC.StateProvinceCode = DCU.StateProvinceCode
FROM
    ModifiedCities DCU
WHERE
    DCU.WWICityID = DC.WWICityID AND
    DC.LoadDate <= '<< LastCutoffDate >>'; 

-- Update Unknown Record
UPDATE
    {{ DimCities }}
SET
    StateProvinceCode = 'N/A'
WHERE
    CityKey = 0;
