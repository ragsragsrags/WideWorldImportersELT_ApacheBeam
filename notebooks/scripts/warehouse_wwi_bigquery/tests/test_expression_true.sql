SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    'SELECT * FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE [LoadDate] = \'<< LoadDate >>\' AND NOT (<< Expression >>)' AS Sql
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LoadDate = '<< LoadDate >>' AND
    NOT 
    (
        << Column >> = << Expression >>
    )