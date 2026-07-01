BEGIN TRAN

-- Delete Load History
DELETE
    [<< SchemaLH >>].[<< TableLH >>]
WHERE
    [TableName] = '<< Table >>' AND
    [SchemaName] = '<< Schema >>' AND
    [LoadDate] > '<< LoadDate >>'

-- Delete Modify Load History
DELETE 
    [<< SchemaMLH >>].[<< TableMLH >>]
WHERE
    [TableName] = '<< Table >>' AND
    [SchemaName] = '<< Schema >>' AND
    [LoadDate] >=  '<< LoadDate >>'

COMMIT TRAN