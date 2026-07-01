;WITH MaxLoadDates AS
(

    SELECT
        [TableName] = LH.TableName,
        [SchemaName] = LH.SchemaName,
        [LoadDate] = MAX(LH.LoadDate)
    FROM
        [<< Schema >>].[<< Table >>] LH
    GROUP BY
        LH.TableName,
        LH.SchemaName

),

LoadHistories AS (

    SELECT
        *
    FROM
        [<< Schema >>].[<< Table >>] LH
    WHERE
        LH.LoadDate = '<< LoadDate >>'

),

LoadHistoryColumns AS (

    SELECT 
        LH.TableName,
        LH.SchemaName,
        LH.LoadDate,
        TS.Name,
        TS.DataType,
        TS.CharacterMaximumLength,
        TS.IsNullable
    FROM 
        LoadHistories LH
        CROSS APPLY OPENJSON(LH.TableSchema)
        WITH (
            Name NVARCHAR(50) '$.Name',
            DataType NVARCHAR(50) '$.DataType',
            CharacterMaximumLength INT '$.CharacterMaximumLength',
            IsNullable NVARCHAR(50) '$.IsNullable'
        ) AS TS 

),

MaxLoadHistoryColumns AS (

    SELECT 
        LH.TableName,
        LH.SchemaName,
        LH.LoadDate,
        TS.Name,
        TS.DataType,
        TS.CharacterMaximumLength,
        TS.IsNullable
    FROM 
        [<< Schema >>].[<< Table >>] LH
        CROSS APPLY OPENJSON(LH.TableSchema)
        WITH (
            Name NVARCHAR(50) '$.Name',
            DataType NVARCHAR(50) '$.DataType',
            CharacterMaximumLength INT '$.CharacterMaximumLength',
            IsNullable NVARCHAR(50) '$.IsNullable'
        ) AS TS JOIN
        MaxLoadDates MLD ON
            MLD.TableName = LH.TableName AND
            MLD.SchemaName = LH.SchemaName AND
            MLD.LoadDate = LH.LoadDate

),

MissingColumns AS (

    SELECT
        LH.TableName,
        LH.SchemaName,
        [Count] = COUNT(*)
    FROM
    (
        SELECT
            LH.*
        FROM
            LoadHistoryColumns LH LEFT JOIN
            MaxLoadHistoryColumns LHM ON
                LHM.TableName = LH.TableName AND
                LHM.SchemaName = LH.SchemaName AND
                LHM.Name = LH.Name AND
                LHM.DataType = LH.DataType AND
                LHM.IsNullable = LH.IsNullable
        WHERE
            LHM.TableName IS NULL
    ) LH
    GROUP BY
        LH.TableName,
        LH.SchemaName

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
            MaxLoadHistoryColumns LHM LEFT JOIN
            LoadHistoryColumns LH ON
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

MaxLoadHistories AS (

    SELECT
        LH.TableName,
        LH.SchemaName,
        LH.LoadDate,
        LH.LastCutoffDate
    FROM
        [<< Schema >>].[<< Table >>] LH JOIN
        MaxLoadDates MLD ON
            MLD.TableName = LH.TableName AND
            MLD.SchemaName = LH.SchemaName AND
            MLD.LoadDate = LH.LoadDate
)

SELECT
    LH.TableName,
    LH.SchemaName,
    [Type] = 
        CASE 
            WHEN LH.LoadDate = MLH.LoadDate THEN 'Load Date Is Latest' 
            WHEN ISNULL(MC.[Count], 0) > 0 THEN 'Recreate Table' -- Recreate Table
            ELSE 'Drop Records'
        END,
    [AddedColumns] = ISNULL(MAC.AddedColumns, ''),
    [LoadLastCutoffDate] = LH.LastCutoffDate
FROM
    LoadHistories LH LEFT JOIN 
    MissingColumns MC ON
        MC.TableName = LH.TableName AND 
        MC.SchemaName = LH.SchemaName LEFT JOIN
    MaxAddedColumns MAC ON
        MAC.TableName = LH.TableName AND
        MAC.SchemaName = LH.SchemaName LEFT JOIN
    MaxLoadHistories MLH ON
        MLH.TableName = LH.TableName AND
        MLH.SchemaName = LH.SchemaName

UNION ALL

SELECT
    MLH.TableName,
    MLH.SchemaName,
    [Type] = 'Drop Table',
    [AddedColumns] = '',
    [LoadLastCutoffDate] = MLH.LastCutoffDate
FROM
    MaxLoadHistories MLH LEFT JOIN
    LoadHistories LH ON 
        LH.TableName = MLH.TableName AND
        LH.SchemaName = MLH.SchemaName
WHERE
    LH.TableName IS NULL