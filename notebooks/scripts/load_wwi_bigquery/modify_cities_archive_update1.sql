UPDATE
	`<< Database >>.<< Schema >>.<< Table >>` AC
SET
	AC.NewColumn = ACS.NewColumn
FROM 
	`<< Database >>.<< Schema >>.<< StagingTable >>` ACS
WHERE
	AC.CityID = ACS.CityID AND
	AC.ValidFrom = ACS.ValidFrom AND
	AC.ValidTo = ACS.ValidTo AND
	AC.LoadDate <= '<< LastCutoffDate >>';