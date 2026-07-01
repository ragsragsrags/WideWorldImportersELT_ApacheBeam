DELETE 
    [<< Schema >>].[<< Table >>] 
WHERE
    LoadDate > (
		SELECT
			ISNULL(MAX([LoadDate]), CAST('<< LastCutoffDate >>' AS DATETIME2(6)))
		FROM
			[<< LHSchema >>].[<< LHTable >>]
		WHERE
			[TableName] = '<< TableName >>' AND
			[SchemaName] = '<< SchemaName >>' AND
			[Status] = 'Successful'
	);