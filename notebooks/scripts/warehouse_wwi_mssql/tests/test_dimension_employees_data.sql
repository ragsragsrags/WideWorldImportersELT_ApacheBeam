SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = REPLACE('
        
    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIEmployeeID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWIEmployeeID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWIEmployeeID] = DE.[WWIEmployeeID], 
                    [Warehouse_Employee] = DE.[Employee], 
                    [Warehouse_PreferredName] = DE.[PreferredName], 
                    [Warehouse_IsSalesPerson] = DE.[IsSalesPerson], 
                    [Warehouse_Photo] = CAST(DE.[Photo] AS VARBINARY(MAX)), 
                    [Warehouse_LoadDate] = DE.[LoadDate]
                FROM 
                    {{ DimEmployees }} DE
                WHERE 
                    DE.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DE.[EmployeeKey] != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    [Original_WWIEmployeeID] = P.PersonID,
                    [Original_Employee] = P.FullName,
                    [Original_PreferredName] = P.PreferredName,
                    [Original_IsSalesPerson] = P.IsSalesperson,
                    [Original_Photo] = CAST(P.Photo AS VARBINARY(MAX))
                FROM 
                    {{ ApplicationPeople }} P 
                WHERE
                    P.IsEmployee = 1 AND
                    P.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo

                UNION ALL

                SELECT 
                    PA.PersonID,
                    PA.FullName,
                    PA.PreferredName,
                    PA.IsSalesperson,
                    PA.Photo
                FROM 
                    {{ ApplicationPeopleArchive }} PA 
                WHERE
                    PA.IsEmployee = 1 AND
                    PA.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWIEmployeeID] = TD.[Original_WWIEmployeeID] 
        WHERE 
            WD.Warehouse_WWIEmployeeID IS NULL OR 
            TD.Original_WWIEmployeeID IS NULL OR 
            ( 
                WD.Warehouse_WWIEmployeeID IS NOT NULL AND 
                TD.Original_WWIEmployeeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_Employee] != TD.[Original_Employee] OR 
                        WD.[Warehouse_PreferredName] != TD.[Original_PreferredName] OR 
                        WD.[Warehouse_IsSalesPerson] != TD.[Original_IsSalesPerson] OR 
                        WD.[Warehouse_Photo] != TD.[Original_Photo] 
                    ) 
                )
            )
    ) R