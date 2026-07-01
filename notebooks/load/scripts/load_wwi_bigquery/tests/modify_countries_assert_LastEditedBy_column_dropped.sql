IF NOT EXISTS (
	SELECT 
		1 
	FROM
		`<< Database >>`.`<< Schema >>`.INFORMATION_SCHEMA.COLUMNS T  
	WHERE
		T.table_catalog = '<< Database >>' AND
		T.table_schema = '<< Schema >>' AND
		T.table_name = '<< Table >>' AND
		T.column_name = 'LastEditedBy'
) THEN
	SELECT CAST(1 AS BOOLEAN) AS Result;
ELSE
	SELECT CAST(0 AS BOOLEAN) AS Result;
END IF;