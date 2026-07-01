DELETE 
    `<< Database >>.<< Schema >>.<< Table >>` 
WHERE
    LoadDate > (
		SELECT
			IFNULL(MAX(LoadDate), CAST('<< LastCutoffDate >>' AS DATETIME))
		FROM
			`<< Database >>.<< LHSchema >>.<< LHTable >>`
		WHERE
			TableName = '<< TableName >>' AND
			SchemaName = '<< SchemaName >>' AND
			Status = 'Successful'
	);