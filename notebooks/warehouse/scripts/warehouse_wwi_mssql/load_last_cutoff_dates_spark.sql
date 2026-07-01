SELECT
    TableName,
    SchemaName,
    MAX(CAST(LoadDate AS DATETIME2(7))) AS LastCutoffDate
FROM
    [<< Schema >>].[<< Table >>]
GROUP BY
    TableName,
    SchemaName