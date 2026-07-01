SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 	
            CASE 
                WHEN WD.Warehouse_WWIEmployeeID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWIEmployeeID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DE.WWIEmployeeID AS Warehouse_WWIEmployeeID, 
                    DE.Employee AS Warehouse_Employee, 
                    DE.PreferredName AS Warehouse_PreferredName, 
                    DE.IsSalesPerson AS Warehouse_IsSalesPerson, 
                    CAST(DE.Photo AS BYTES) AS Warehouse_Photo, 
                    DE.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimEmployees }} DE
                WHERE 
                    DE.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DE.EmployeeKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    P.PersonID AS Original_WWIEmployeeID,
                    P.FullName AS Original_Employee,
                    P.PreferredName AS Original_PreferredName,
                    P.IsSalesperson AS Original_IsSalesPerson,
                    CAST(P.Photo AS BYTES) AS Original_Photo
                FROM 
                    {{ ApplicationPeople }} P 
                WHERE
                    P.IsEmployee = TRUE AND
                    P.ValidFrom > ''<< LastCutoffDate >>'' AND
                    ''<< NewCutoffDate >>'' BETWEEN P.ValidFrom AND P.ValidTo

                UNION ALL

                SELECT 
                    PA.PersonID,
                    PA.FullName,
                    PA.PreferredName,
                    PA.IsSalesperson,
                    CAST(PA.Photo AS BYTES)
                FROM 
                    {{ ApplicationPeopleArchive }} PA 
                WHERE
                    PA.IsEmployee = TRUE AND
                    PA.ValidFrom > ''<< LastCutoffDate >>'' AND
                    ''<< NewCutoffDate >>'' BETWEEN PA.ValidFrom AND PA.ValidTo
            ) TD ON 
                WD.Warehouse_WWIEmployeeID = TD.Original_WWIEmployeeID 
        WHERE 
            WD.Warehouse_WWIEmployeeID IS NULL OR 
            TD.Original_WWIEmployeeID IS NULL OR 
            ( 
                WD.Warehouse_WWIEmployeeID IS NOT NULL AND 
                TD.Original_WWIEmployeeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_Employee != TD.Original_Employee OR 
                        WD.Warehouse_PreferredName != TD.Original_PreferredName OR 
                        WD.Warehouse_IsSalesPerson != TD.Original_IsSalesPerson OR 
                        WD.Warehouse_Photo != TD.Original_Photo 
                    ) 
                )
            )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 	
            CASE 
                WHEN WD.Warehouse_WWIEmployeeID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWIEmployeeID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DE.WWIEmployeeID AS Warehouse_WWIEmployeeID, 
                    DE.Employee AS Warehouse_Employee, 
                    DE.PreferredName AS Warehouse_PreferredName, 
                    DE.IsSalesPerson AS Warehouse_IsSalesPerson, 
                    CAST(DE.Photo AS BYTES) AS Warehouse_Photo, 
                    DE.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimEmployees }} DE
                WHERE 
                    DE.LoadDate = '<< NewCutoffDate >>' AND 
                    DE.EmployeeKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    P.PersonID AS Original_WWIEmployeeID,
                    P.FullName AS Original_Employee,
                    P.PreferredName AS Original_PreferredName,
                    P.IsSalesperson AS Original_IsSalesPerson,
                    CAST(P.Photo AS BYTES) AS Original_Photo
                FROM 
                    {{ ApplicationPeople }} P 
                WHERE
                    P.IsEmployee = TRUE AND
                    P.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo

                UNION ALL

                SELECT 
                    PA.PersonID,
                    PA.FullName,
                    PA.PreferredName,
                    PA.IsSalesperson,
                    CAST(PA.Photo AS BYTES)
                FROM 
                    {{ ApplicationPeopleArchive }} PA 
                WHERE
                    PA.IsEmployee = TRUE AND
                    PA.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo
            ) TD ON 
                WD.Warehouse_WWIEmployeeID = TD.Original_WWIEmployeeID 
        WHERE 
            WD.Warehouse_WWIEmployeeID IS NULL OR 
            TD.Original_WWIEmployeeID IS NULL OR 
            ( 
                WD.Warehouse_WWIEmployeeID IS NOT NULL AND 
                TD.Original_WWIEmployeeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_Employee != TD.Original_Employee OR 
                        WD.Warehouse_PreferredName != TD.Original_PreferredName OR 
                        WD.Warehouse_IsSalesPerson != TD.Original_IsSalesPerson OR 
                        WD.Warehouse_Photo != TD.Original_Photo 
                    ) 
                )
            )
    ) R