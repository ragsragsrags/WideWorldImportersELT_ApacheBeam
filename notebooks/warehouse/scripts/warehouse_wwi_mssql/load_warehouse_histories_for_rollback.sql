;WITH MaxWarehouseDates AS
(

    SELECT
        [TableName] = WH.TableName,
        [SchemaName] = WH.SchemaName,
        [LoadDate] = MAX(WH.LoadDate)
    FROM
        [<< Schema >>].[<< Table >>] WH
    GROUP BY
        WH.TableName,
        WH.SchemaName

),

WarehouseHistories AS (

    SELECT
        *
    FROM
        [<< Schema >>].[<< Table >>] WH
    WHERE
        WH.LoadDate = '<< LoadDate >>'

),

WarehouseHistoryColumns AS (

    SELECT 
        WH.TableName,
        WH.SchemaName,
        WH.LoadDate,
        TS.Name,
        TS.DataType,
        TS.CharacterMaximumLength,
        TS.IsNullable
    FROM 
        WarehouseHistories WH
        CROSS APPLY OPENJSON(WH.TableSchema)
        WITH (
            Name NVARCHAR(50) '$.Name',
            DataType NVARCHAR(50) '$.DataType',
            CharacterMaximumLength INT '$.CharacterMaximumLength',
            IsNullable NVARCHAR(50) '$.IsNullable'
        ) AS TS 

),

MaxWarehouseHistoryColumns AS (

    SELECT 
        WH.TableName,
        WH.SchemaName,
        WH.LoadDate,
        TS.Name,
        TS.DataType,
        TS.CharacterMaximumLength,
        TS.IsNullable
    FROM 
        [<< Schema >>].[<< Table >>] WH
        CROSS APPLY OPENJSON(WH.TableSchema)
        WITH (
            Name NVARCHAR(50) '$.Name',
            DataType NVARCHAR(50) '$.DataType',
            CharacterMaximumLength INT '$.CharacterMaximumLength',
            IsNullable NVARCHAR(50) '$.IsNullable'
        ) AS TS JOIN
        MaxWarehouseDates MWD ON
            MWD.TableName = WH.TableName AND
            MWD.SchemaName = WH.SchemaName AND
            MWD.LoadDate = WH.LoadDate

),

MissingColumns AS (

    SELECT
        WH.TableName,
        WH.SchemaName,
        [Count] = COUNT(*)
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
        [Count] = COUNT(*),
        [AddedColumns] = STRING_AGG(LH.[Name], ',')
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
        WH.[LastCutoffDate],
        WH.[RollbackVersion]
    FROM
        [<< Schema >>].[<< Table >>] WH JOIN
        MaxWarehouseDates MWD ON
            MWD.TableName = WH.TableName AND
            MWD.SchemaName = WH.SchemaName AND
            MWD.LoadDate = WH.LoadDate
)

SELECT
    WH.TableName,
    WH.SchemaName,
    [Type] = 
        CASE 
            WHEN WH.LoadDate = MWH.LoadDate THEN 
                'Load Date Is Latest'
            WHEN 
                (
                    ISNULL(MC.[Count], 0) > 0 OR 
                    MWH.[RollbackVersion] != WH.RollbackVersion
                ) THEN 'Recreate Table' -- Recreate Table
            ELSE 'Drop Records'
        END,
    [AddedColumns] = ISNULL(MAC.AddedColumns, ''),
    [WarehouseLastCutoffDate] = WH.LastCutoffDate
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
    [Type] = 'Drop Table',
    [AddedColumns] = '',
    [WarehouseLastCutoffDate] = MWH.LastCutoffDate
FROM
    MaxWarehouseHistories MWH LEFT JOIN
    WarehouseHistories WH ON 
        WH.TableName = MWH.TableName AND
        WH.SchemaName = MWH.SchemaName
WHERE
    WH.TableName IS NULL 