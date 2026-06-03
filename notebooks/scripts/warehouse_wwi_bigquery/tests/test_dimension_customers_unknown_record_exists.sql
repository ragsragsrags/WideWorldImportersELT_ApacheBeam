SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    CASE 
        WHEN (SELECT COUNT(*) FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE CustomerKey = 0 AND Customer = 'N/A') != 1 THEN 1
        ELSE 0
    END ErrorCount,
    'SELECT COUNT(*) FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE CustomerKey = 0 AND Customer = \'N/A\'' AS Sql