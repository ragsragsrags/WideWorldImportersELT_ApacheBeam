SELECT
    [ColorID],
    [ColorName],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    ColorID,
    ValidFrom,
    ValidTo

OFFSET 0 ROW