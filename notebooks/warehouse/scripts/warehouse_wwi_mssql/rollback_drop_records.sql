BEGIN TRAN

-- Delete Records
DELETE
	[<< Schema >>].[<< Table >>]
WHERE
	[LoadDate] > '<< LoadDate >>' AND
	[LastLoadDate] <> '<< LastCutoffDate >>'

-- Set to Load Date to Last Load Date
UPDATE
	[<< Schema >>].[<< Table >>]
SET
	[LoadDate] = [LastLoadDate] 
WHERE
	[LastLoadDate] = '<< LastCutoffDate >>';

-- Drop Columns if existing
<< DropColumns >>

COMMIT TRAN