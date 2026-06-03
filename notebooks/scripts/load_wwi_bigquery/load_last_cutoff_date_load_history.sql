SELECT
	MAX(LoadDate)
FROM
	`<< Database >>.<< Schema >>.<< Table >>`
WHERE
	TableName = '<< TableName >>' AND
	Status = 'Successful'