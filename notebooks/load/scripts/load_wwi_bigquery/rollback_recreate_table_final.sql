-- Delete Load History
DELETE
    `<< Database >>.<< SchemaLH >>.<< TableLH >>`
WHERE
    TableName = '<< Table >>' AND
    SchemaName = '<< Schema >>' AND
    LoadDate > '<< LoadDate >>';

-- Delete Modify Load History
DELETE 
    `<< Database >>.<< SchemaMLH >>.<< TableMLH >>`
WHERE
    TableName = '<< Table >>' AND
    SchemaName = '<< Schema >>' AND
    LoadDate >=  '<< LoadDate >>';