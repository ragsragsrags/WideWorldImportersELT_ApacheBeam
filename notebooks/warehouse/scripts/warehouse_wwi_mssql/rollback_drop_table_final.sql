BEGIN TRAN

-- Delete Warehouse History
DELETE
    [<< SchemaWH >>].[<< TableWH >>]
WHERE
    [TableName] = '<< Table >>' AND
    [SchemaName] = '<< Schema >>'

-- Delete Modify Warehouse History
DELETE 
    [<< SchemaMWH >>].[<< TableMWH >>]
WHERE
    [TableName] = '<< Table >>' AND
    [SchemaName] = '<< Schema >>'

COMMIT TRAN