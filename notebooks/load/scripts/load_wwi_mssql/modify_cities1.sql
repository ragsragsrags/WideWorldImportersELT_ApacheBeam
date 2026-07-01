IF NOT EXISTS (
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.COLUMNS T  
	WHERE
		T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>' AND
		T.COLUMN_NAME = 'NewColumn'
)
BEGIN

	ALTER TABLE [<< Schema >>].[<< Table >>]
	ADD NewColumn NVARCHAR(50)

END