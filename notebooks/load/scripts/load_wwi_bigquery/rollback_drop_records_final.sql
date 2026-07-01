-- Update Load History
UPDATE 
	`<< Database >>.<< SchemaLH >>.<< TableLH >>`
SET
	LastRolledBackProcessedDate = CAST(CURRENT_TIMESTAMP() AS DATETIME)
WHERE
	TableName = '<< Table >>' AND
	SchemaName = '<< Schema >>' AND
	LoadDate = '<< LoadDate >>';

-- Delete Load History Records 
DELETE
	`<< Database >>.<< SchemaLH >>.<< TableLH >>` 
WHERE
	TableName = '<< Table >>' AND
	SchemaName = '<< Schema >>' AND
	LoadDate > '<< LoadDate >>';

-- Delete Modify Load History Records 
DELETE
	`<< Database >>.<< SchemaMLH >>.<< TableMLH >>` 
WHERE
	TableName = '<< Table >>' AND
	SchemaName = '<< Schema >>' AND
	LoadDate >= '<< LoadDate >>';