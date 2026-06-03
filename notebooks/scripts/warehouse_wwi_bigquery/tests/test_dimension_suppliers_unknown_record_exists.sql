SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    CASE 
        WHEN (SELECT COUNT(*) FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE SupplierKey = 0 AND Supplier = 'Unknown') != 1 THEN 1
        ELSE 0
    END AS ErrorCount,
    'SELECT COUNT(*) FROM `<< Database >>.<< Schema >>.<< Table >>` WHERE SupplierKey = 0 AND Supplier = \'Unknown\'' AS Sql