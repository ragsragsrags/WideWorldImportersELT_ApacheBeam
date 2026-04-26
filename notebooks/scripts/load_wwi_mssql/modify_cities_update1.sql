UPDATE
	AC
SET
	AC.NewColumn = ACS.NewColumn
FROM 
	[<< Schema >>].[<< StagingTable >>] ACS JOIN
	[<< Schema >>].[<< Table >>] AC ON
		AC.CityID = ACS.CityID 
WHERE
	AC.LoadDate <= '<< LastCutoffDate >>'