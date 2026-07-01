UPDATE 
    `<< Database >>.<< Schema >>.<< Table >>`
SET 
    LastRolledBackProcessedDate = CAST(CURRENT_TIMESTAMP() AS DATETIME)
WHERE
    TableName = '<< TableName >>' AND
    SchemaName = '<< SchemaName >>' AND
    LoadDate = '<< LoadDate >>'