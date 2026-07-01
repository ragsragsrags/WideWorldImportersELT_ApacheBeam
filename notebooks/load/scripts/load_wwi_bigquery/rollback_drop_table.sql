-- Drop Table
DROP TABLE IF EXISTS `<< Database >>.<< Schema >>.<< Table >>`;

-- Delete Load History
DELETE
    `<< Database >>.<< SchemaLH >>.<< TableLH >>`
WHERE
    TableName = '<< Table >>' AND
    SchemaName = '<< Schema >>';

-- Delete Modify Load History
DELETE 
    `<< Database >>.<< SchemaMLH >>.<< TableMLH >>`
WHERE
    TableName = '<< Table >>' AND
    SchemaName = '<< Schema >>';