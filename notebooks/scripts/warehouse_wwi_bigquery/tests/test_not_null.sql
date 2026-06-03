SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    'SELECT * FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE << Column >> IS NULL AND LoadDate = \'<< LoadDate >>\'' AS Sql
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    << Column >> IS NULL AND
    LoadDate = '<< LoadDate >>'