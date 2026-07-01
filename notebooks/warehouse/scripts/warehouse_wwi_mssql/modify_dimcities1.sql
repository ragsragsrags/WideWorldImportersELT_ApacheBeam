IF NOT EXISTS (
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.COLUMNS T  
	WHERE
		T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>' AND
		T.COLUMN_NAME = 'StateProvinceCode'
)
BEGIN

	ALTER TABLE [<< Schema >>].[<< Table >>]
	ADD StateProvinceCode NVARCHAR(5)

END