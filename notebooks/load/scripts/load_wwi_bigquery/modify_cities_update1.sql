UPDATE
	`<< Database >>.<< Schema >>.<< Table >>` AC
SET
	AC.NewColumn = ACS.NewColumn
FROM 
	`<< Database >>.<< Schema >>.<< StagingTable >>` ACS
WHERE
	AC.CityID = ACS.CityID AND
	AC.LoadDate <= '<< LastCutoffDate >>'