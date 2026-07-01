SELECT
    MS.*
FROM
    (
        << ModifyTableScripts >>
    ) MS LEFT JOIN
    [dbo].[ModifyLoadHistory] MTH ON
        MTH.ScriptName = MS.Name AND
        MTH.[TableName] = '<< TableName >>' AND
        MTH.[LoadDate] <= '<< RollbackDate >>' AND
        MTH.[Status] = 'Successful'
ORDER BY
    MTH.ProcessedDate DESC

SELECT
    MS.*
FROM
    (
        << ModifyTableScripts >>
    ) MS LEFT JOIN
    [<< Schema >>].[<< Table >>] MTH ON
        MTH.ScriptName = MS.Name AND
        MTH.[TableName] = '<< TableName >>' AND
        MTH.[LoadDate] >= '<< RollbackDate >>' AND
        MTH.[Status] = 'Successful'
WHERE
    MTH.ScriptName IS NULL