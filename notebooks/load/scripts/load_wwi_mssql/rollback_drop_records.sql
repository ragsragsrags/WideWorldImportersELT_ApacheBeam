BEGIN TRAN

-- Delete Records
DELETE
	[<< Schema >>].[<< Table >>]
WHERE
	[LoadDate] > '<< LoadDate >>'

-- Drop Columns if existing
<< DropColumns >>

COMMIT TRAN