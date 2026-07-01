UPDATE 
    [<< Schema >>].[<< Table >>]
SET 
    LastRolledBackProcessedDate = CURRENT_TIMESTAMP
WHERE
    [TableName] = '<< TableName >>' AND
    [SchemaName] = '<< SchemaName >>' AND
    [LoadDate] = '<< LoadDate >>'