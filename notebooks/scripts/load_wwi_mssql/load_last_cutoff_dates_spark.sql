SELECT
    TableName,
    MAX(CAST(LoadDate AS DATETIME2(6))) AS LastCutoffDate
FROM
    [<< Schema >>].[<< Table >>]
GROUP BY
    TableName