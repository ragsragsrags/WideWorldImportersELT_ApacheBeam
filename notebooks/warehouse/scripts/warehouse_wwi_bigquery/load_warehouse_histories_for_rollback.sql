WITH MaxWarehouseDates AS
(

    SELECT
        WH.TableName AS TableName,
        WH.SchemaName AS SchemaName,
        MAX(WH.LoadDate) AS LoadDate
    FROM
        `<< Database >>.<< Schema >>.<< Table >>` WH
    GROUP BY
        WH.TableName,
        WH.SchemaName

),

WarehouseHistories AS (

    SELECT
        WH.TableName, 
        WH.SchemaName,
        WH.LoadDate,
        WH.LastCutoffDate, 
        WH.Status, 
        WH.Details,
        WH.TableSchema,
        WH.RollbackVersion
    FROM
        `<< Database >>.<< Schema >>.<< Table >>` WH
    WHERE
        WH.LoadDate = '<< LoadDate >>'

),

WarehouseHistoryColumns AS (

    SELECT 
        WH.TableName,
        WH.SchemaName,
        WH.LoadDate,
        JSON_VALUE(TS, '$.Name') AS Name,
        JSON_VALUE(TS, '$.DataType') AS DataType,
        JSON_VALUE(TS, '$.CharacterMaximumLength') AS CharacterMaximumLength,
        JSON_VALUE(TS, '$.IsNullable') AS IsNullable
    FROM 
        WarehouseHistories WH
        CROSS JOIN UNNEST(JSON_QUERY_ARRAY(WH.TableSchema)) TS

),

MaxWarehouseHistoryColumns AS (

    SELECT
        WH.TableName,
        WH.SchemaName,
        WH.LoadDate,
        JSON_VALUE(TS, '$.Name') AS Name,
        JSON_VALUE(TS, '$.DataType') AS DataType,
        JSON_VALUE(TS, '$.CharacterMaximumLength') AS CharacterMaximumLength,
        JSON_VALUE(TS, '$.IsNullable') IsNullable
    FROM 
        `<< Database >>.<< Schema >>.<< Table >>` WH JOIN
        MaxWarehouseDates MWD ON
            MWD.TableName = WH.TableName AND
            MWD.SchemaName = WH.SchemaName AND
            MWD.LoadDate = WH.LoadDate
        CROSS JOIN UNNEST(JSON_QUERY_ARRAY(WH.TableSchema)) AS TS

),

MissingColumns AS (

    SELECT
        WH.TableName,
        WH.SchemaName,
        COUNT(*) AS Count
    FROM
    (
        SELECT
            WHC.*
        FROM
            WarehouseHistoryColumns WHC LEFT JOIN
            MaxWarehouseHistoryColumns MWHC ON
                MWHC.TableName = WHC.TableName AND
                MWHC.SchemaName = WHC.SchemaName AND
                MWHC.Name = WHC.Name AND
                MWHC.DataType = WHC.DataType AND
                MWHC.IsNullable = WHC.IsNullable
        WHERE
            MWHC.TableName IS NULL
    ) WH
    GROUP BY
        WH.TableName,
        WH.SchemaName

),

MaxAddedColumns AS (

    SELECT
        LH.TableName,
        LH.SchemaName,
        COUNT(*) AS Count,
        STRING_AGG(LH.Name, ',') AS AddedColumns
    FROM
    (
        SELECT
            LHM.*
        FROM
            MaxWarehouseHistoryColumns LHM LEFT JOIN
            WarehouseHistoryColumns LH ON
                LHM.TableName = LH.TableName AND
                LHM.SchemaName = LH.SchemaName AND
                LHM.Name = LH.Name AND
                LHM.DataType = LH.DataType AND
                LHM.IsNullable = LH.IsNullable
        WHERE
            LH.TableName IS NULL
    ) LH
    GROUP BY
        LH.TableName,
        LH.SchemaName

),

MaxWarehouseHistories AS (

    SELECT
        WH.TableName,
        WH.SchemaName,
        WH.LoadDate,
        WH.LastCutoffDate,
        WH.RollbackVersion
    FROM
        `<< Database >>.<< Schema >>.<< Table >>` WH JOIN
        MaxWarehouseDates MWD ON
            MWD.TableName = WH.TableName AND
            MWD.SchemaName = WH.SchemaName AND
            MWD.LoadDate = WH.LoadDate
)

SELECT
    WH.TableName,
    WH.SchemaName,
    CASE 
        WHEN WH.LoadDate = MWH.LoadDate THEN 'Load Date Is Latest'
        WHEN 
            (
                IFNULL(MC.Count, 0) > 0 OR 
                MWH.RollbackVersion != WH.RollbackVersion
            ) THEN 'Recreate Table' -- Recreate Table
        ELSE 'Drop Records'
    END AS Type,
    IFNULL(MAC.AddedColumns, '') AS AddedColumns,
    WH.LastCutoffDate AS WarehouseLastCutoffDate
FROM
    WarehouseHistories WH LEFT JOIN 
    MissingColumns MC ON
        MC.TableName = WH.TableName AND 
        MC.SchemaName = WH.SchemaName LEFT JOIN
    MaxAddedColumns MAC ON
        MAC.TableName = WH.TableName LEFT JOIN
    MaxWarehouseHistories MWH ON
        MWH.TableName = WH.TableName AND 
        MWH.SchemaName = WH.SchemaName 

UNION ALL

SELECT
    MWH.TableName,
    MWH.SchemaName,
    'Drop Table' AS Type,
    '' AS AddedColumns,
    MWH.LastCutoffDate AS WarehouseLastCutoffDate
FROM
    MaxWarehouseHistories MWH LEFT JOIN
    WarehouseHistories WH ON 
        WH.TableName = MWH.TableName AND
        WH.SchemaName = MWH.SchemaName
WHERE
    WH.TableName IS NULL 