SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWICityID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWICityID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DC.WWICityID AS Warehouse_WWICityID, 
                    DC.City AS Warehouse_City, 
                    DC.StateProvince AS Warehouse_StateProvince, 
                    DC.Location AS Warehouse_Location, 
                    DC.Country AS Warehouse_Country, 
                    DC.Continent AS Warehouse_Continent, 
                    DC.SalesTerritory AS Warehouse_SalesTerritory, 
                    DC.Region AS Warehouse_Region, 
                    DC.LatestRecordedPopulation AS Warehouse_LatestRecordedPopulation, 
                    DC.Subregion AS Warehouse_Subregion, 
                    DC.LoadDate AS Warehouse_LoadDate 
                FROM 
                    {{ DimCities }} DC 
                WHERE 
                    DC.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DC.CityKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    C.CityID AS Original_WWICityID, 
                    C.CityName AS Original_City, 
                    SP.StateProvinceName AS Original_StateProvince, 
                    ST_GEOGFROMTEXT(C.Location) AS Original_Location,
                    CA.CountryName AS Original_Country, 
                    CA.Continent AS Original_Continent, 
                    SP.SalesTerritory AS Original_SalesTerritory, 
                    CA.Region AS Original_Region, 
                    C.LatestRecordedPopulation AS Original_LatestRecordedPopulation, 
                    CA.Subregion AS Original_Subregion, 
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate 
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
                            SP.SalesTerritory 
                        FROM 
                            {{ ApplicationStateProvinces }} AS SP 
                        WHERE 
                            ''<< NewCutoffDate >>'' BETWEEN SP.ValidFrom AND SP.ValidTo 
                            
                        UNION ALL 
                        
                        SELECT 
                            SPA.StateProvinceID, 
                            SPA.CountryID, 
                            SPA.StateProvinceName, 
                            SPA.SalesTerritory 
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
                    WD.Warehouse_WWICityID = TD.Original_WWICityID 
            WHERE 
                WD.Warehouse_WWICityID IS NULL OR 
                TD.Original_WWICityID IS NULL OR 
                ( 
                    WD.Warehouse_WWICityID IS NOT NULL AND 
                    TD.Original_WWICityID IS NOT NULL AND 
                    ( 
                        ( 
                            WD.Warehouse_City != TD.Original_City OR 
                            WD.Warehouse_StateProvince != TD.Original_StateProvince OR 
                            NOT ST_EQUALS(WD.Warehouse_Location, TD.Original_Location) OR 
                            WD.Warehouse_Country != TD.Original_Country OR 
                            WD.Warehouse_Continent != TD.Original_Continent OR 
                            WD.Warehouse_SalesTerritory != TD.Original_SalesTerritory OR 
                            WD.Warehouse_Region != TD.Original_Region OR 
                            IFNULL(WD.Warehouse_LatestRecordedPopulation, 0) != IFNULL(TD.Original_LatestRecordedPopulation, 0) OR 
                            WD.Warehouse_Subregion != TD.Original_Subregion OR 
                            WD.Warehouse_LoadDate != TD.Original_LoadDate 
                        ) 
                    )
                )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWICityID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWICityID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DC.WWICityID AS Warehouse_WWICityID, 
                    DC.City AS Warehouse_City, 
                    DC.StateProvince AS Warehouse_StateProvince, 
                    DC.Location AS Warehouse_Location, 
                    DC.Country AS Warehouse_Country, 
                    DC.Continent AS Warehouse_Continent, 
                    DC.SalesTerritory AS Warehouse_SalesTerritory, 
                    DC.Region AS Warehouse_Region, 
                    DC.LatestRecordedPopulation AS Warehouse_LatestRecordedPopulation, 
                    DC.Subregion AS Warehouse_Subregion, 
                    DC.LoadDate AS Warehouse_LoadDate 
                FROM 
                    {{ DimCities }} DC 
                WHERE 
                    DC.LoadDate = '<< NewCutoffDate >>' AND 
                    DC.CityKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    C.CityID AS Original_WWICityID, 
                    C.CityName AS Original_City, 
                    SP.StateProvinceName AS Original_StateProvince, 
                    ST_GEOGFROMTEXT(C.Location) AS Original_Location,
                    CA.CountryName AS Original_Country, 
                    CA.Continent AS Original_Continent, 
                    SP.SalesTerritory AS Original_SalesTerritory, 
                    CA.Region AS Original_Region, 
                    C.LatestRecordedPopulation AS Original_LatestRecordedPopulation, 
                    CA.Subregion AS Original_Subregion, 
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate 
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
                            SP.SalesTerritory 
                        FROM 
                            {{ ApplicationStateProvinces }} AS SP 
                        WHERE 
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
                    WD.Warehouse_WWICityID = TD.Original_WWICityID 
            WHERE 
                WD.Warehouse_WWICityID IS NULL OR 
                TD.Original_WWICityID IS NULL OR 
                ( 
                    WD.Warehouse_WWICityID IS NOT NULL AND 
                    TD.Original_WWICityID IS NOT NULL AND 
                    ( 
                        ( 
                            WD.Warehouse_City != TD.Original_City OR 
                            WD.Warehouse_StateProvince != TD.Original_StateProvince OR 
                            NOT ST_EQUALS(WD.Warehouse_Location, TD.Original_Location) OR 
                            WD.Warehouse_Country != TD.Original_Country OR 
                            WD.Warehouse_Continent != TD.Original_Continent OR 
                            WD.Warehouse_SalesTerritory != TD.Original_SalesTerritory OR 
                            WD.Warehouse_Region != TD.Original_Region OR 
                            IFNULL(WD.Warehouse_LatestRecordedPopulation, 0) != IFNULL(TD.Original_LatestRecordedPopulation, 0) OR 
                            WD.Warehouse_Subregion != TD.Original_Subregion OR 
                            WD.Warehouse_LoadDate != TD.Original_LoadDate 
                        ) 
                    )
                )

    ) R