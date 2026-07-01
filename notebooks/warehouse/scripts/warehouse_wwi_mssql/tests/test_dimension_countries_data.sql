SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = REPLACE('
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWICountryID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWICountryID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWICountryID] = DC.[WWICountryID],
                    [Warehouse_Country] = DC.[Country],
                    [Warehouse_LoadDate] = DC.[LoadDate]
                FROM 
                    {{ DimCountries }} DC
                WHERE 
                    DC.[LoadDate] = ''<< NewCutoffDate >>'' AND 
                    DC.[CountryKey] != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            [Original_WWICountryID] = AC.CountryID,		            
		            [Original_Country] = AC.CountryName,
                    [Original_LoadDate] = CAST(''<< NewCutoffDate >>'' AS DATETIME2(7))
	            FROM
		            {{ ApplicationCountries }} AC 
	            WHERE
		            AC.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN AC.ValidFrom AND AC.ValidTo

	            UNION ALL

	            SELECT
		            [Original_WWICountryID] = ACA.CountryID,
		            [Original_Country] = ACA.CountryName,
                    [Original_LoadDate] = CAST(''<< NewCutoffDate >>'' AS DATETIME2(7))
	            FROM
		            {{ ApplicationCountriesArchive }} ACA
	            WHERE
		            ACA.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN ACA.ValidFrom AND ACA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWICountryID] = TD.[Original_WWICountryID] 
        WHERE 
            WD.Warehouse_WWICountryID IS NULL OR 
            TD.Original_WWICountryID IS NULL OR 
            ( 
                WD.Warehouse_WWICountryID IS NOT NULL AND 
                TD.Original_WWICountryID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_Country] != TD.[Original_Country] OR
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                    ) 
                )
            )
    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWICountryID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWICountryID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWICountryID] = DC.[WWICountryID],
                    [Warehouse_Country] = DC.[Country],
                    [Warehouse_LoadDate] = DC.[LoadDate]
                FROM 
                    {{ DimCountries }} DC
                WHERE 
                    DC.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DC.[CountryKey] != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            [Original_WWICountryID] = AC.CountryID,		            
		            [Original_Country] = AC.CountryName,
                    [Original_LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
	            FROM
		            {{ ApplicationCountries }} AC 
	            WHERE
		            AC.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN AC.ValidFrom AND AC.ValidTo

	            UNION ALL

	            SELECT
		            [Original_WWICountryID] = ACA.CountryID,
		            [Original_Country] = ACA.CountryName,
                    [Original_LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
	            FROM
		            {{ ApplicationCountriesArchive }} ACA
	            WHERE
		            ACA.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN ACA.ValidFrom AND ACA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWICountryID] = TD.[Original_WWICountryID] 
        WHERE 
            WD.Warehouse_WWICountryID IS NULL OR 
            TD.Original_WWICountryID IS NULL OR 
            ( 
                WD.Warehouse_WWICountryID IS NOT NULL AND 
                TD.Original_WWICountryID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_Country] != TD.[Original_Country] OR
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                    ) 
                )
            )
    ) R