;WITH merged_states AS 
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
    	[WWICityID] = MC.CityID,
        [StateProvinceCode] = MS.StateProvinceCode
    FROM
    	merged_cities MC LEFT JOIN
        merged_states MS ON
            MS.StateProvinceID = MC.StateProvinceID

)

UPDATE
    DC
SET 
    DC.StateProvinceCode = DCU.StateProvinceCode
FROM
    {{ DimCities }} DC JOIN
    cities DCU ON 
        DCU.WWICityID = DC.WWICityID
WHERE
    DC.LoadDate <= '<< LastCutoffDate >>' 

-- Update Unknown Record
UPDATE
    {{ DimCities }}
SET
    StateProvinceCode = 'N/A'
WHERE
    CityKey = 0
