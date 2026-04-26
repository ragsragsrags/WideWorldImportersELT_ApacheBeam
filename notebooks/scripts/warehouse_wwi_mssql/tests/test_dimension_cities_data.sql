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
                    WHEN WD.Warehouse_WWICityID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWICityID IS NULL THEN ''Missing in original data''
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWICityID] = DC.[WWICityID], 
                    [Warehouse_City] = DC.[City], 
                    [Warehouse_StateProvince] = DC.[StateProvince], 
                    [Warehouse_Location] = CAST(DC.[Location] AS VARBINARY(MAX)), 
                    [Warehouse_Country] = DC.[Country], 
                    [Warehouse_Continent] = DC.[Continent], 
                    [Warehouse_SalesTerritory] = DC.[SalesTerritory], 
                    [Warehouse_Region] = DC.[Region], 
                    [Warehouse_LatestRecordedPopulation] = DC.[LatestRecordedPopulation], 
                    [Warehouse_Subregion] = DC.[Subregion], 
                    [Warehouse_LoadDate] = DC.[LoadDate], 
                    [Warehouse_StateProvinceCode] = DC.[StateProvinceCode] 
                FROM 
                    {{ DimCities }} DC 
                WHERE 
                    DC.[LoadDate] = ''<< NewCutoffDate >>'' AND 
                    DC.CityKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    [Original_WWICityID] = C.[CityID], 
                    [Original_City] = C.CityName, 
                    [Original_StateProvince] = SP.StateProvinceName, 
                    [Original_Location] = CAST(C.Location AS VARBINARY(MAX)),
                    [Original_Country] = CA.CountryName, 
                    [Original_Continent] = CA.Continent, 
                    [Original_SalesTerritory] = SP.SalesTerritory, 
                    [Original_Region] = CA.Region, 
                    [Original_LatestRecordedPopulation] = C.LatestRecordedPopulation, 
                    [Original_Subregion] = CA.Subregion, 
                    [Original_LoadDate] = ''<< NewCutoffDate >>'', 
                    [Original_StateProvinceCode] = SP.StateProvinceCode 
                FROM 
                    (
                        SELECT 
                            C.CityID, 
                            C.CityName, 
                            C.Location, 
                            C.LatestRecordedPopulation, 
                            C.StateProvinceID,
                            C.ValidFrom,
                            C.ValidTo
                        FROM 
                            {{ ApplicationCities }} AS C 
                        WHERE 
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo 
                            
                        UNION ALL 
                        
                        SELECT 
                            CA.CityID, 
                            CA.CityName, 
                            CA.Location, 
                            CA.LatestRecordedPopulation, 
                            CA.StateProvinceID,
                            CA.ValidFrom,
                            CA.ValidTo 
                        FROM 
                            {{ ApplicationCitiesArchive }} AS CA 
                        WHERE 
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo 
                    ) C LEFT JOIN 
                    ( 
                        SELECT 
                            SP.StateProvinceID, 
                            SP.CountryID, 
                            SP.StateProvinceName, 
                            SP.SalesTerritory, 
                            SP.StateProvinceCode 
                        FROM 
                            {{ ApplicationStateProvinces }} AS SP 
                        WHERE 
                            ''<< NewCutoffDate >>'' BETWEEN SP.ValidFrom AND SP.ValidTo 
                            
                        UNION ALL 
                        
                        SELECT 
                            SPA.StateProvinceID, 
                            SPA.CountryID, 
                            SPA.StateProvinceName, 
                            SPA.SalesTerritory, 
                            SPA.StateProvinceCode 
                        FROM 
                            {{ ApplicationStateProvincesArchive }} AS SPA 
                        WHERE 
                            ''<< NewCutoffDate >>'' BETWEEN SPA.ValidFrom AND SPA.ValidTo 
                    ) SP ON 
                        SP.StateProvinceID = C.StateProvinceID LEFT JOIN 
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
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo 
                            
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
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo 
                    ) CA ON 
                        CA.CountryID = SP.CountryID 
                WHERE
                    (
                        C.ValidFrom > ''<< LastCutoffDate >>'' OR
                        C.CityID IN
                        (
                            SELECT 
                                C.CityID
                            FROM 
                                {{ ApplicationCities }} AS C 
                            WHERE 
                                C.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo 
                                
                            UNION ALL 
                            
                            SELECT 
                                CA.CityID
                            FROM 
                                {{ ApplicationCitiesArchive }} AS CA 
                            WHERE
                                CA.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                        ) OR
                        SP.StateProvinceID IN
                        (
                            SELECT 
                                SP.StateProvinceID
                            FROM 
                                {{ ApplicationStateProvinces }} AS SP 
                            WHERE 
                                SP.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN SP.ValidFrom AND SP.ValidTo 
                                
                            UNION ALL 
                            
                            SELECT 
                                SPA.StateProvinceID
                            FROM 
                                {{ ApplicationStateProvincesArchive }} AS SPA 
                            WHERE 
                                SPA.ValidFrom> ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN SPA.ValidFrom AND SPA.ValidTo 
                        ) OR
                        CA.CountryID IN
                        (
                            SELECT 
                                C.CountryID 
                            FROM 
                                {{ ApplicationCountries }} AS C 
                            WHERE 
                                C.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo 
                                
                            UNION ALL 
                            
                            SELECT 
                                CA.CountryID 
                            FROM 
                                {{ ApplicationCountriesArchive }} CA 
                            WHERE
                                CA.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                        )
                    ) AND
                    ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                    
            ) TD ON 
                    WD.[Warehouse_WWICityID] = TD.[Original_WWICityID] 
            WHERE 
                WD.Warehouse_WWICityID IS NULL OR 
                TD.Original_WWICityID IS NULL OR 
                ( 
                    WD.Warehouse_WWICityID IS NOT NULL AND 
                    TD.Original_WWICityID IS NOT NULL AND 
                    ( 
                        ( 
                            WD.[Warehouse_City] != TD.[Original_City] OR 
                            WD.[Warehouse_StateProvince] != TD.[Original_StateProvince] OR 
                            WD.[Warehouse_Location] != TD.[Original_Location] OR 
                            WD.[Warehouse_Country] != TD.[Original_Country] OR 
                            WD.[Warehouse_Continent] != TD.[Original_Continent] OR 
                            WD.[Warehouse_SalesTerritory] != TD.[Original_SalesTerritory] OR 
                            WD.[Warehouse_Region] != TD.[Original_Region] OR 
                            ISNULL(WD.[Warehouse_LatestRecordedPopulation], 0) != ISNULL(TD.[Original_LatestRecordedPopulation], 0) OR 
                            WD.[Warehouse_Subregion] != TD.[Original_Subregion] OR 
                            WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] OR 
                            WD.[Warehouse_StateProvinceCode] != TD.[Original_StateProvinceCode] 
                        ) 
                    )
                )

    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWICityID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWICityID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWICityID] = DC.[WWICityID], 
                    [Warehouse_City] = DC.[City], 
                    [Warehouse_StateProvince] = DC.[StateProvince], 
                    [Warehouse_Location] = CAST(DC.[Location] AS VARBINARY(MAX)), 
                    [Warehouse_Country] = DC.[Country], 
                    [Warehouse_Continent] = DC.[Continent], 
                    [Warehouse_SalesTerritory] = DC.[SalesTerritory], 
                    [Warehouse_Region] = DC.[Region], 
                    [Warehouse_LatestRecordedPopulation] = DC.[LatestRecordedPopulation], 
                    [Warehouse_Subregion] = DC.[Subregion], 
                    [Warehouse_LoadDate] = DC.[LoadDate], 
                    [Warehouse_StateProvinceCode] = DC.[StateProvinceCode] 
                FROM 
                    {{ DimCities }} DC 
                WHERE 
                    DC.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DC.CityKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    [Original_WWICityID] = C.[CityID], 
                    [Original_City] = C.CityName, 
                    [Original_StateProvince] = SP.StateProvinceName, 
                    [Original_Location] = CAST(C.Location AS VARBINARY(MAX)),
                    [Original_Country] = CA.CountryName, 
                    [Original_Continent] = CA.Continent, 
                    [Original_SalesTerritory] = SP.SalesTerritory, 
                    [Original_Region] = CA.Region, 
                    [Original_LatestRecordedPopulation] = C.LatestRecordedPopulation, 
                    [Original_Subregion] = CA.Subregion, 
                    [Original_LoadDate] = '<< NewCutoffDate >>', 
                    [Original_StateProvinceCode] = SP.StateProvinceCode 
                FROM 
                    (
                        SELECT 
                            C.CityID, 
                            C.CityName, 
                            C.Location, 
                            C.LatestRecordedPopulation, 
                            C.StateProvinceID,
                            C.ValidFrom,
                            C.ValidTo
                        FROM 
                            {{ ApplicationCities }} AS C 
                        WHERE 
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 
                            
                        UNION ALL 
                        
                        SELECT 
                            CA.CityID, 
                            CA.CityName, 
                            CA.Location, 
                            CA.LatestRecordedPopulation, 
                            CA.StateProvinceID,
                            CA.ValidFrom,
                            CA.ValidTo 
                        FROM 
                            {{ ApplicationCitiesArchive }} AS CA 
                        WHERE 
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo 
                    ) C LEFT JOIN 
                    ( 
                        SELECT 
                            SP.StateProvinceID, 
                            SP.CountryID, 
                            SP.StateProvinceName, 
                            SP.SalesTerritory, 
                            SP.StateProvinceCode 
                        FROM 
                            {{ ApplicationStateProvinces }} AS SP 
                        WHERE 
                            '<< NewCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo 
                            
                        UNION ALL 
                        
                        SELECT 
                            SPA.StateProvinceID, 
                            SPA.CountryID, 
                            SPA.StateProvinceName, 
                            SPA.SalesTerritory, 
                            SPA.StateProvinceCode 
                        FROM 
                            {{ ApplicationStateProvincesArchive }} AS SPA 
                        WHERE 
                            '<< NewCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo 
                    ) SP ON 
                        SP.StateProvinceID = C.StateProvinceID LEFT JOIN 
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
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo 
                    ) CA ON 
                        CA.CountryID = SP.CountryID 
                WHERE
                    (
                        C.ValidFrom > '<< LastCutoffDate >>' OR
                        C.CityID IN
                        (
                            SELECT 
                                C.CityID
                            FROM 
                                {{ ApplicationCities }} AS C 
                            WHERE 
                                C.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 
                                
                            UNION ALL 
                            
                            SELECT 
                                CA.CityID
                            FROM 
                                {{ ApplicationCitiesArchive }} AS CA 
                            WHERE
                                CA.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                        ) OR
                        SP.StateProvinceID IN
                        (
                            SELECT 
                                SP.StateProvinceID
                            FROM 
                                {{ ApplicationStateProvinces }} AS SP 
                            WHERE 
                                SP.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo 
                                
                            UNION ALL 
                            
                            SELECT 
                                SPA.StateProvinceID
                            FROM 
                                {{ ApplicationStateProvincesArchive }} AS SPA 
                            WHERE 
                                SPA.ValidFrom> '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo 
                        ) OR
                        CA.CountryID IN
                        (
                            SELECT 
                                C.CountryID 
                            FROM 
                                {{ ApplicationCountries }} AS C 
                            WHERE 
                                C.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 
                                
                            UNION ALL 
                            
                            SELECT 
                                CA.CountryID 
                            FROM 
                                {{ ApplicationCountriesArchive }} CA 
                            WHERE
                                CA.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                        )
                    ) AND
                    '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo
                    
            ) TD ON 
                    WD.[Warehouse_WWICityID] = TD.[Original_WWICityID] 
            WHERE 
                WD.Warehouse_WWICityID IS NULL OR 
                TD.Original_WWICityID IS NULL OR 
                ( 
                    WD.Warehouse_WWICityID IS NOT NULL AND 
                    TD.Original_WWICityID IS NOT NULL AND 
                    ( 
                        ( 
                            WD.[Warehouse_City] != TD.[Original_City] OR 
                            WD.[Warehouse_StateProvince] != TD.[Original_StateProvince] OR 
                            WD.[Warehouse_Location] != TD.[Original_Location] OR 
                            WD.[Warehouse_Country] != TD.[Original_Country] OR 
                            WD.[Warehouse_Continent] != TD.[Original_Continent] OR 
                            WD.[Warehouse_SalesTerritory] != TD.[Original_SalesTerritory] OR 
                            WD.[Warehouse_Region] != TD.[Original_Region] OR 
                            ISNULL(WD.[Warehouse_LatestRecordedPopulation], 0) != ISNULL(TD.[Original_LatestRecordedPopulation], 0) OR 
                            WD.[Warehouse_Subregion] != TD.[Original_Subregion] OR 
                            WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] OR 
                            WD.[Warehouse_StateProvinceCode] != TD.[Original_StateProvinceCode] 
                        ) 
                    )
                )

    ) R