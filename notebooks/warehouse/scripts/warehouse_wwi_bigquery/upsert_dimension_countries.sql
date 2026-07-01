DECLARE MaxCountryKey INT64;

SET MaxCountryKey = 
(
    SELECT
        IFNULL(MAX(CountryKey), 0)
    FROM
        {{ DimCountries }}
);

CREATE TEMP TABLE TempDimCountries AS
WITH mergedCountries AS
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
		CASE
			WHEN MC.CountryKey IS NULL THEN CAST(MaxCountryKey AS INTEGER) + (ROW_NUMBER() OVER(ORDER BY MC.CountryKey, MC.CountryID))
			ELSE MC.CountryKey
		END AS CountryKey,
		MC.CountryID AS WWICountryID,
		MC.CountryName AS Country,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE
			WHEN MC.CountryKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist 
	FROM
		mergedCountries MC

	UNION ALL

	SELECT
		0 AS CountryKey,
		0 AS WWICountryID,
		'Unknown' AS Country,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CAST(FALSE AS BOOLEAN) AS Exist
	FROM
        (
            SELECT
                1
        )
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
FROM
	final;

-- Update Existing
UPDATE
	{{ DimCountries }} C2
SET
	C2.Country = C.Country,
	C2.LoadDate = C.LoadDate,
	C2.LastLoadDate = C2.LoadDate
FROM
	TempDimCountries C 
WHERE
	C2.WWICountryID = C.WWICountryID AND
	C.Exist = TRUE;

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
	CAST(NULL AS DATETIME)
FROM
	TempDimCountries C
WHERE
	C.Exist = FALSE
ORDER BY
	C.CountryKey;