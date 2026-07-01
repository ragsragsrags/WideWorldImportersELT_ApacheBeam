UPDATE
	AC
SET
	AC.NewColumn = ACS.NewColumn
FROM 
	[<< Schema >>].[<< StagingTable >>] ACS JOIN
	[<< Schema >>].[<< Table >>] AC ON
		AC.CityID = ACS.CityID AND
        AC.ValidFrom = ACS.ValidFrom AND
        AC.ValidTo = ACS.ValidTo
WHERE
	AC.LoadDate <= '<< LastCutoffDate >>'