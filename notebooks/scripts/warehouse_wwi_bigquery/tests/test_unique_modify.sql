SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    'SELECT << Column >>, COUNT(*) AS Count FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE LoadDate <= \'<< LoadDate >>\' GROUP BY << Column >> HAVING COUNT(*) > 1' AS Sql
FROM
    (
        SELECT
            COUNT(*) AS Count
        FROM
            `<< Database >>.<< Schema >>.<< Table >>`
        WHERE
            LoadDate <= '<< LoadDate >>'
        GROUP BY
            << Column >>
        HAVING
            COUNT(*) > 1
    ) U