SELECT TOP 1
	[LoadDate]
FROM
	[<< Schema >>].[<< Table >>]
WHERE
	[TableName] = '<< TableName >>' AND
	[Status] = 'Successful'
ORDER BY
	[LoadDate] DESC