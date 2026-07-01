DECLARE LastCutoffDate DATETIME;

SET LastCutoffDate = 
(
    SELECT
        MAX(LoadDate)
    FROM 
        `<< Database >>.<< MHSchema >>.<< MHTable >>`
    WHERE
        TableName = '<< TableName >>' AND
        SchemaName = '<< SchemaName >>' AND
        Status = 'Successful'
);

SELECT
    MS.*
FROM
    (
        << ModifyTableScripts >>
    ) MS LEFT JOIN
    `<< Database >>.<< Schema >>.<< Table >>` MTH ON
        MTH.ScriptName = MS.Name AND
        MTH.TableName = '<< TableName >>' AND
        MTH.LoadDate <= CAST(LastCutoffDate AS DATETIME) AND
        MTH.Status = 'Successful'
WHERE
    MTH.ScriptName IS NULL