DECLARE @MaxEmployeeKey INT 
    
SELECT
    @MaxEmployeeKey = ISNULL(MAX(EmployeeKey), 0)
FROM
    {{ DimEmployees }}

IF OBJECT_ID('tempdb..#DimEmployees') IS NOT NULL
    DROP TABLE #DimEmployees

;WITH mergedPeople AS 
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
		P.IsEmployee = 1 AND
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
		P.IsEmployee = 1 AND
		P.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo 

),

final AS
(

	SELECT
		[EmployeeKey] = 
            CASE 
                WHEN MP.EmployeeKey IS NULL THEN @MaxEmployeeKey + (ROW_NUMBER() OVER (ORDER BY MP.[EmployeeKey], MP.[PersonID]))
                ELSE MP.EmployeeKey
            END,
		[WWIEmployeeID] = MP.PersonID,
		[Employee] = MP.FullName,
		[PreferredName] = MP.PreferredName,
		[IsSalesPerson] = MP.IsSalesperson,
		[Photo] = MP.Photo,
		[LoadDate] = '<< NewCutoffDate >>',
        [Exists] = 
            CASE
                WHEN MP.EmployeeKey IS NULL THEN CAST(0 AS BIT)
                ELSE CAST(1 AS BIT)
            END
	FROM
		mergedPeople MP

	UNION ALL

    SELECT
		[EmployeeKey] = 0,
		[WWIEmployeeID] = 0, 
		[Employee] = 'Unknown', 
		[PreferredName] = 'N/A', 
		[IsSalesPerson] = 0, 
		[Photo] = NULL,
		[LoadDate] = '<< NewCutoffDate >>',
        [Exists] = CAST(0 AS BIT)
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
INTO
	#DimEmployees
FROM
	final
ORDER BY
	EmployeeKey

BEGIN TRAN

-- Update Existing
UPDATE
	E2
SET
	E2.Employee = E.Employee,
	E2.PreferredName = E.PreferredName,
	E2.IsSalesPerson = E.IsSalesPerson,
	E2.Photo = E.Photo,
	E2.LoadDate = E.LoadDate
FROM
	#DimEmployees E JOIN
	{{ DimEmployees }} E2 ON
		E2.WWIEmployeeID = E.WWIEmployeeID
WHERE
    E.[Exists] = 1

-- Insert New
INSERT INTO {{ DimEmployees }}
(
	EmployeeKey,
	WWIEmployeeID,
	Employee,
	PreferredName,
	IsSalesPerson,
	Photo,
	LoadDate
)
SELECT
	E.EmployeeKey,
	E.WWIEmployeeID,
	E.Employee,
	E.PreferredName,
	E.IsSalesPerson,
	E.Photo,
	E.LoadDate
FROM
	#DimEmployees E 
WHERE
	E.[Exists] = 0
ORDER BY
	E.WWIEmployeeID

COMMIT TRAN