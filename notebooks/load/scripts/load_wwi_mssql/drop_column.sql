IF EXISTS (
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.COLUMNS T  
	WHERE
        T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>' AND
		T.COLUMN_NAME = '<< Column >>'
)
BEGIN

    ALTER TABLE [<< Schema >>].[<< Table >>]
    DROP COLUMN << Column >> 

END