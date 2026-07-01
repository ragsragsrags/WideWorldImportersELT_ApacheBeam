BEGIN TRAN

-- Update Warehouse History
UPDATE 
	[<< SchemaWH >>].[<< TableWH >>]
SET
	[LastRolledBackProcessedDate] = CURRENT_TIMESTAMP
WHERE
	[TableName] = '<< Table >>' AND
	[SchemaName] = '<< Schema >>' AND
	[LoadDate] = '<< LoadDate >>'

-- Delete Warehouse History Records 
DELETE
	[<< SchemaWH >>].[<< TableWH >>] 
WHERE
	[TableName] = '<< Table >>' AND
	[SchemaName] = '<< Schema >>' AND
	[LoadDate] > '<< LoadDate >>'

-- Delete Modify Warehouse History Records 
DELETE
	[<< SchemaMWH >>].[<< TableMWH >>] 
WHERE
	[TableName] = '<< Table >>' AND
	[SchemaName] = '<< Schema >>' AND
	[LoadDate] >= '<< LoadDate >>'

COMMIT TRAN