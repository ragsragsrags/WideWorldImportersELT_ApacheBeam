DECLARE MaxEmployeeKey INT64;

SET MaxEmployeeKey = 
(
    SELECT
        IFNULL(MAX(EmployeeKey), 0)
    FROM
        {{ DimEmployees }}
);

CREATE TEMP TABLE TempDimEmployees AS
WITH mergedPeople AS 
(

	SELECT
		DE.EmployeeKey,
		P.PersonID,
		P.FullName,
		P.PreferredName,
		P.IsSalesperson,
		P.Photo
	FROM
		{{ ApplicationPeople }} P LEFT JOIN
		{{ DimEmployees }} DE ON
			DE.WWIEmployeeID = P.PersonID
	WHERE
		P.IsEmployee = TRUE AND
		P.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo 

	UNION ALL

	SELECT
		DE.EmployeeKey,
		P.PersonID,
		P.FullName,
		P.PreferredName,
		P.IsSalesperson,
		P.Photo
	FROM
		{{ ApplicationPeopleArchive }} P LEFT JOIN
		{{ DimEmployees }} DE ON
			DE.WWIEmployeeID = P.PersonID
	WHERE
		P.IsEmployee = TRUE AND
		P.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo 

),

final AS
(

	SELECT
		CASE 
			WHEN MP.EmployeeKey IS NULL THEN CAST(MaxEmployeeKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY MP.EmployeeKey, MP.PersonID))
			ELSE MP.EmployeeKey
		END AS EmployeeKey,
		MP.PersonID AS WWIEmployeeID,
		MP.FullName AS Employee,
		MP.PreferredName AS PreferredName,
		MP.IsSalesperson AS IsSalesPerson,
		MP.Photo AS Photo,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate, 
		CASE
			WHEN MP.EmployeeKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
	FROM
		mergedPeople MP

	UNION ALL

    SELECT
		0 AS EmployeeKey,
		0 AS WWIEmployeeID, 
		'Unknown' AS Employee, 
		'N/A' AS PreferredName, 
		CAST(FALSE AS BOOLEAN) AS IsSalesPerson, 
		NULL AS Photo,
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
                {{ DimEmployees }}
            WHERE
                EmployeeKey = 0
        )
)

SELECT 
	*
FROM
	final
ORDER BY
	EmployeeKey;

-- Update Existing
UPDATE
	{{ DimEmployees }} E2
SET
	E2.Employee = E.Employee,
	E2.PreferredName = E.PreferredName,
	E2.IsSalesPerson = E.IsSalesPerson,
	E2.Photo = E.Photo,
	E2.LoadDate = E.LoadDate,
	E2.LastLoadDate = E2.LoadDate
FROM
	TempDimEmployees E 
		
WHERE
    E.Exist = TRUE AND
	E2.WWIEmployeeID = E.WWIEmployeeID;

-- Insert New
INSERT INTO {{ DimEmployees }}
(
	EmployeeKey,
	WWIEmployeeID,
	Employee,
	PreferredName,
	IsSalesPerson,
	Photo,
	LoadDate,
	LastLoadDate
)
SELECT
	E.EmployeeKey,
	E.WWIEmployeeID,
	E.Employee,
	E.PreferredName,
	E.IsSalesPerson,
	E.Photo,
	E.LoadDate,
	CAST(NULL AS DATETIME)
FROM
	TempDimEmployees E 
WHERE
	E.Exist = FALSE
ORDER BY
	E.WWIEmployeeID;