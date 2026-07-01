SELECT TOP 1
	[LoadDate]
FROM
	[<< Schema >>].[<< Table >>]
WHERE
	[TableName] = '<< TableName >>' AND
	[SchemaName] = '<< SchemaName >>' AND
	[Status] = 'Successful'
ORDER BY
	[LoadDate] DESC