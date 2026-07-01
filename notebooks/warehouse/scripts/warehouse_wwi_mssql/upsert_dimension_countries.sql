DECLARE @MaxCountryKey INT 
    
SELECT
    @MaxCountryKey = ISNULL(MAX(CountryKey), 0)
FROM
    {{ DimCountries }}

IF OBJECT_ID('tempdb..#DimCountries') IS NOT NULL
    DROP TABLE #DimCountries

;WITH mergedCountries AS
(

	SELECT
		DC.CountryKey,
		AC.CountryID,
		AC.CountryName
	FROM
		{{ ApplicationCountries }} AC LEFT JOIN
		{{ DimCountries }} DC ON
			DC.WWICountryID = AC.CountryID
	WHERE
		AC.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN AC.ValidFrom AND AC.ValidTo

	UNION ALL

	SELECT
		DC.CountryKey,
		ACA.CountryID,
		ACA.CountryName
	FROM
		{{ ApplicationCountriesArchive }} ACA LEFT JOIN
		{{ DimCountries }} DC ON
			DC.WWICountryID = ACA.CountryID
	WHERE
		ACA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN ACA.ValidFrom AND ACA.ValidTo

),

final AS (

	SELECT
		[CountryKey] = 
			CASE
				WHEN MC.CountryKey IS NULL THEN @MaxCountryKey + (ROW_NUMBER() OVER(ORDER BY MC.CountryKey, MC.CountryID))
				ELSE MC.CountryKey
			END,
		[WWICountryID] = MC.CountryID,
		[Country] = MC.CountryName,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN MC.CountryKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END 
	FROM
		mergedCountries MC

	UNION ALL

	SELECT
		[TransactionTypeKey] = 0,
		[WWITransactionTypeID] = 0,
		[TransactionType] = 'Unknown',
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = CAST(0 AS BIT)
	WHERE
		NOT EXISTS
		(
			SELECT
				1
			FROM
				{{ DimCountries }}
			WHERE
				CountryKey = 0
		)

)

SELECT 
	*
INTO
	#DimCountries
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	C2
SET
	C2.Country = C.Country,
	C2.LoadDate = C.LoadDate,
	C2.LastLoadDate = C2.LoadDate
FROM
	#DimCountries C JOIN
	{{ DimCountries }} C2 ON
		C2.WWICountryID = C.WWICountryID
WHERE
	C.[Exists] = 1

-- Insert New
INSERT INTO {{ DimCountries }}
(
	CountryKey,
	WWICountryID,
	Country,
	LoadDate,
	LastLoadDate
)
SELECT
	C.CountryKey,
	C.WWICountryID,
	C.Country,
	C.LoadDate,
	'<< NewCutoffDate >>'
FROM
	#DimCountries C
WHERE
	C.[Exists] = 0
ORDER BY
	C.CountryKey

COMMIT TRAN