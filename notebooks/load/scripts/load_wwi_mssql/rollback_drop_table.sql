BEGIN TRAN

-- Drop Table
IF EXISTS 
(
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.TABLES T  
	WHERE
		T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>'
)
	BEGIN
    DROP TABLE [<< Schema >>].[<< Table >>]
    END

-- Delete Load History
DELETE
    [<< SchemaLH >>].[<< TableLH >>]
WHERE
    [TableName] = '<< Table >>' AND
    [SchemaName] = '<< Schema >>'

-- Delete Modify Load History
DELETE 
    [<< SchemaMLH >>].[<< TableMLH >>]
WHERE
    [TableName] = '<< Table >>' AND
    [SchemaName] = '<< Schema >>'

COMMIT TRAN