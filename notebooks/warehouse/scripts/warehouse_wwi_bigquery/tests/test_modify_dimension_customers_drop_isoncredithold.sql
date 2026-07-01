SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    'SELECT 1 FROM `<< Database >>`.`<< Schema >>`.INFORMATION_SCHEMA.COLUMNS T WHERE T.table_catalog = \'<< Database >>\' AND T.table_schema = \'<< Schema >>\' AND T.table_name = \'<< Table >>\' AND T.column_name = \'IsOnCreditHold\'' AS Sql
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    EXISTS (
        SELECT 
            1 
        FROM
            `<< Database >>`.`<< Schema >>`.INFORMATION_SCHEMA.COLUMNS T  
        WHERE
            T.table_catalog = '<< Database >>' AND
            T.table_schema = '<< Schema >>' AND
            T.table_name = '<< Table >>' AND
            T.column_name = 'IsOnCreditHold'
    )