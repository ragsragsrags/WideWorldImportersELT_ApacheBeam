WITH MaxLoadDates AS
(

    SELECT
        LH.TableName AS TableName,
        LH.SchemaName AS SchemaName,
        MAX(LH.LoadDate) AS LoadDate
    FROM
        `<< Database >>.<< Schema >>.<< Table >>` LH
    GROUP BY
        LH.TableName,
        LH.SchemaName

),

LoadHistories AS (

    SELECT
        *
    FROM
        `<< Database >>.<< Schema >>.<< Table >>` LH
    WHERE
        LH.LoadDate = '<< LoadDate >>'

),

LoadHistoryColumns AS (

    SELECT 
        LH.TableName,
        LH.SchemaName,
        LH.LoadDate,
        JSON_VALUE(TS, '$.Name') AS Name,
        JSON_VALUE(TS, '$.DataType') AS DataType,
        JSON_VALUE(TS, '$.CharacterMaximumLength') AS CharacterMaximumLength,
        JSON_VALUE(TS, '$.IsNullable') AS IsNullable
    FROM 
        LoadHistories LH
        CROSS JOIN UNNEST(JSON_QUERY_ARRAY(LH.TableSchema)) AS TS 

),

MaxLoadHistoryColumns AS (

    SELECT 
        LH.TableName,
        LH.SchemaName,
        LH.LoadDate,
        JSON_VALUE(TS, '$.Name') AS Name,
        JSON_VALUE(TS, '$.DataType') AS DataType,
        JSON_VALUE(TS, '$.CharacterMaximumLength') AS CharacterMaximumLength,
        JSON_VALUE(TS, '$.IsNullable') AS IsNullable
    FROM 
        `<< Database >>.<< Schema >>.<< Table >>` LH  JOIN
        MaxLoadDates MLD ON
            MLD.TableName = LH.TableName AND
            MLD.SchemaName = LH.SchemaName AND
            MLD.LoadDate = LH.LoadDate
        CROSS JOIN UNNEST(JSON_QUERY_ARRAY(LH.TableSchema)) AS TS

),

MissingColumns AS (

    SELECT
        LH.TableName,
        LH.SchemaName,
        COUNT(*) AS Count 
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
        COUNT(*) AS Count,
        STRING_AGG(LH.Name, ',') AS AddedColumns
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
        `<< Database >>.<< Schema >>.<< Table >>` LH JOIN
        MaxLoadDates MLD ON
            MLD.TableName = LH.TableName AND
            MLD.SchemaName = LH.SchemaName AND
            MLD.LoadDate = LH.LoadDate
)

SELECT
    LH.TableName,
    LH.SchemaName,
    CASE 
        WHEN LH.LoadDate = MLH.LoadDate THEN 'Load Date Is Latest'
        WHEN IFNULL(MC.Count, 0) > 0 THEN 'Recreate Table' -- Recreate Table
        ELSE 'Drop Records'
    END AS Type,
    IFNULL(MAC.AddedColumns, '') AS AddedColumns,
    CAST(LH.LastCutoffDate AS TIMESTAMP) AS LoadLastCutoffDate
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
    'Drop Table' AS Type,
    '' AS AddedColumns,
    CAST(MLH.LastCutoffDate AS TIMESTAMP) AS LoadLastCutoffDate
FROM
    MaxLoadHistories MLH LEFT JOIN
    LoadHistories LH ON 
        LH.TableName = MLH.TableName AND
        LH.SchemaName = MLH.SchemaName
WHERE
    LH.TableName IS NULL