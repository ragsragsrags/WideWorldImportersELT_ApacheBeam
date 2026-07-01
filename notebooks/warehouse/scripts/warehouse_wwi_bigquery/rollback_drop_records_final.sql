-- Update Warehouse History
UPDATE 
	`<< Database >>.<< SchemaWH >>.<< TableWH >>`
SET
	LastRolledBackProcessedDate = CAST(CURRENT_TIMESTAMP() AS DATETIME)
WHERE
	TableName = '<< Table >>' AND
	SchemaName = '<< Schema >>' AND
	LoadDate = '<< LoadDate >>';

-- Delete Warehouse History Records 
DELETE
	`<< Database >>.<< SchemaWH >>.<< TableWH >>`
WHERE
	TableName = '<< Table >>' AND
	SchemaName = '<< Schema >>' AND
	LoadDate > '<< LoadDate >>';

-- Delete Modify Warehouse History Records 
DELETE
	`<< Database >>.<< SchemaMWH >>.<< TableMWH >>` 
WHERE
	TableName = '<< Table >>' AND
	SchemaName = '<< Schema >>' AND
	LoadDate >= '<< LoadDate >>';