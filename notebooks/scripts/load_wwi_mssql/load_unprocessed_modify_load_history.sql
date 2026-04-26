SELECT
    MS.*
FROM
    (
        << ModifyTableScripts >>
    ) MS LEFT JOIN
    [<< Schema >>].[<< Table >>] MTH ON
        MTH.ScriptName = MS.Name AND
        MTH.[TableName] = '<< TableName >>' AND
        MTH.[LoadDate] <= '<< LoadDate >>' AND
        MTH.[Status] = 'Successful'
WHERE
    MTH.ScriptName IS NULL