BEGIN TRAN

-- Update Load History
UPDATE 
	[<< SchemaLH >>].[<< TableLH >>]
SET
	[LastRolledBackProcessedDate] = CURRENT_TIMESTAMP
WHERE
	[TableName] = '<< Table >>' AND
	[SchemaName] = '<< Schema >>' AND
	[LoadDate] = '<< LoadDate >>'

-- Delete Load History Records 
DELETE
	[<< SchemaLH >>].[<< TableLH >>] 
WHERE
	[TableName] = '<< Table >>' AND
	[SchemaName] = '<< Schema >>' AND
	[LoadDate] > '<< LoadDate >>'

-- Delete Modify Load History Records 
DELETE
	[<< SchemaMLH >>].[<< TableMLH >>] 
WHERE
	[TableName] = '<< Table >>' AND
	[SchemaName] = '<< Schema >>' AND
	[LoadDate] >= '<< LoadDate >>'

COMMIT TRAN