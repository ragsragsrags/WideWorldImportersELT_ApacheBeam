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
                    DC.StateProvinceCode AS Warehouse_StateProvinceCode
                FROM
                    {{ DimCities }} DC
                WHERE
                    DC.LoadDate <= ''<< LastCutoffDate >>'' AND
                    DC.CityKey != 0 
            ) WD FULL OUTER JOIN
            (
                SELECT
                    C.CityID AS Original_WWICityID,
                    SP.StateProvinceCode AS Original_StateProvinceCode
                FROM
                    (
                        SELECT
                            C.CityID,
                            C.StateProvinceID
                        FROM
                            {{ ApplicationCities }} AS C
                        WHERE
                            ''<< LastCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo 

                        UNION ALL

                        SELECT
                            CA.CityID,
                            CA.StateProvinceID
                        FROM
                            {{ ApplicationCitiesArchive }} AS CA
                        WHERE
                            ''<< LastCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo 
                    ) C LEFT JOIN
                    (
                        SELECT
                            SP.StateProvinceID,
                            SP.StateProvinceCode
                        FROM
                            {{ ApplicationStateProvinces }} AS SP
                        WHERE
                            ''<< LastCutoffDate >>'' BETWEEN SP.ValidFrom AND SP.ValidTo 

                        UNION ALL

                        SELECT
                            SPA.StateProvinceID,
                            SPA.StateProvinceCode
                        FROM
                            {{ ApplicationStateProvincesArchive }} AS SPA
                        WHERE
                            ''<< LastCutoffDate >>'' BETWEEN SPA.ValidFrom AND SPA.ValidTo
                    ) SP ON
                        SP.StateProvinceID = C.StateProvinceID 
            ) TD ON
                WD.Warehouse_WWICityID = TD.Original_WWICityID 
        WHERE
            WD.Warehouse_WWICityID IS NULL OR
            TD.Original_WWICityID IS NULL OR
            (
                WD.Warehouse_WWICityID IS NOT NULL AND
                TD.Original_WWICityID IS NOT NULL AND
                WD.Warehouse_StateProvinceCode != TD.Original_StateProvinceCode
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
                    DC.StateProvinceCode AS Warehouse_StateProvinceCode
                FROM
                    {{ DimCities }} DC
                WHERE
                    DC.LoadDate <= '<< LastCutoffDate >>' AND
                    DC.CityKey != 0 
            ) WD FULL OUTER JOIN
            (
                SELECT
                    C.CityID AS Original_WWICityID,
                    SP.StateProvinceCode AS Original_StateProvinceCode
                FROM
                    (
                        SELECT
                            C.CityID,
                            C.StateProvinceID
                        FROM
                            {{ ApplicationCities }} AS C
                        WHERE
                            '<< LastCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 

                        UNION ALL

                        SELECT
                            CA.CityID,
                            CA.StateProvinceID
                        FROM
                            {{ ApplicationCitiesArchive }} AS CA
                        WHERE
                            '<< LastCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo 
                    ) C LEFT JOIN
                    (
                        SELECT
                            SP.StateProvinceID,
                            SP.StateProvinceCode
                        FROM
                            {{ ApplicationStateProvinces }} AS SP
                        WHERE
                            '<< LastCutoffDate >>' BETWEEN SP.ValidFrom AND SP.ValidTo 

                        UNION ALL

                        SELECT
                            SPA.StateProvinceID,
                            SPA.StateProvinceCode
                        FROM
                            {{ ApplicationStateProvincesArchive }} AS SPA
                        WHERE
                            '<< LastCutoffDate >>' BETWEEN SPA.ValidFrom AND SPA.ValidTo
                    ) SP ON
                        SP.StateProvinceID = C.StateProvinceID 
            ) TD ON
                WD.Warehouse_WWICityID = TD.Original_WWICityID 
        WHERE
            WD.Warehouse_WWICityID IS NULL OR
            TD.Original_WWICityID IS NULL OR
            (
                WD.Warehouse_WWICityID IS NOT NULL AND
                TD.Original_WWICityID IS NOT NULL AND
                WD.Warehouse_StateProvinceCode != TD.Original_StateProvinceCode
            )
    ) R