-- Delete Warehouse History
DELETE
    `<< Database >>.<< SchemaWH >>.<< TableWH >>`
WHERE
    TableName = '<< Table >>' AND
    SchemaName = '<< Schema >>';

-- Delete Modify Warehouse History
DELETE 
    `<< Database >>.<< SchemaMWH >>.<< TableMWH >>`
WHERE
    TableName = '<< Table >>' AND
    SchemaName = '<< Schema >>';