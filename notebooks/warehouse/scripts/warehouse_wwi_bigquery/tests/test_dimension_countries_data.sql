SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWICountryID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWICountryID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DC.WWICountryID AS Warehouse_WWICountryID,
                    DC.Country AS Warehouse_Country,
                    DC.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimCountries }} DC
                WHERE 
                    DC.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DC.CountryKey != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            AC.CountryID AS Original_WWICountryID,		            
		            AC.CountryName AS Original_Country,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationCountries }} AC 
	            WHERE
		            AC.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN AC.ValidFrom AND AC.ValidTo

	            UNION ALL

	            SELECT
		            ACA.CountryID AS Original_WWICountryID,
		            ACA.CountryName AS Original_Country,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationCountriesArchive }} ACA
	            WHERE
		            ACA.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN ACA.ValidFrom AND ACA.ValidTo
            ) TD ON 
                WD.Warehouse_WWICountryID = TD.Original_WWICountryID 
        WHERE 
            WD.Warehouse_WWICountryID IS NULL OR 
            TD.Original_WWICountryID IS NULL OR 
            ( 
                WD.Warehouse_WWICountryID IS NOT NULL AND 
                TD.Original_WWICountryID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_Country != TD.Original_Country OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate 
                    ) 
                )
            )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWICountryID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWICountryID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DC.WWICountryID AS Warehouse_WWICountryID,
                    DC.Country AS Warehouse_Country,
                    DC.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimCountries }} DC
                WHERE 
                    DC.LoadDate = '<< NewCutoffDate >>' AND 
                    DC.CountryKey != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            AC.CountryID AS Original_WWICountryID,		            
		            AC.CountryName AS Original_Country,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationCountries }} AC 
	            WHERE
		            AC.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN AC.ValidFrom AND AC.ValidTo

	            UNION ALL

	            SELECT
		            ACA.CountryID AS Original_WWICountryID,
		            ACA.CountryName AS Original_Country,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationCountriesArchive }} ACA
	            WHERE
		            ACA.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN ACA.ValidFrom AND ACA.ValidTo
            ) TD ON 
                WD.Warehouse_WWICountryID = TD.Original_WWICountryID 
        WHERE 
            WD.Warehouse_WWICountryID IS NULL OR 
            TD.Original_WWICountryID IS NULL OR 
            ( 
                WD.Warehouse_WWICountryID IS NOT NULL AND 
                TD.Original_WWICountryID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_Country != TD.Original_Country OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate 
                    ) 
                )
            )
    ) R