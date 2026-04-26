DECLARE @MaxTransactionTypeKey INT 
    
SELECT
    @MaxTransactionTypeKey = ISNULL(MAX(TransactionTypeKey), 0)
FROM
    {{ DimTransactionTypes }}

IF OBJECT_ID('tempdb..#DimTransactionTypes') IS NOT NULL
    DROP TABLE #DimTransactionTypes

;WITH mergedTransactionTypes AS
(

	SELECT
		DTT.TransactionTypeKey,
		TT.TransactionTypeID,
		TT.TransactionTypeName
	FROM
		{{ ApplicationTransactionTypes }} TT LEFT JOIN
		{{ DimTransactionTypes }} DTT ON
			DTT.WWITransactionTypeID = TT.TransactionTypeID
	WHERE
		TT.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN TT.ValidFrom AND TT.ValidTo

	UNION ALL

	SELECT
		DTT.TransactionTypeKey,
		TTA.TransactionTypeID,
		TTA.TransactionTypeName
	FROM
		{{ ApplicationTransactionTypesArchive }} TTA LEFT JOIN
		{{ DimTransactionTypes }} DTT ON
			DTT.WWITransactionTypeID = TTA.TransactionTypeID
	WHERE
		TTA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN TTA.ValidFrom AND TTA.ValidTo

),

final AS (

	SELECT
		[TransactionTypeKey] = 
			CASE
				WHEN TT.TransactionTypeKey IS NULL THEN @MaxTransactionTypeKey + (ROW_NUMBER() OVER(ORDER BY TT.TransactionTypeKey, TT.TransactionTypeID))
				ELSE TT.TransactionTypeKey
			END,
		[WWITransactionTypeID] = TT.TransactionTypeID,
		[TransactionType] = TT.TransactionTypeName,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN TT.TransactionTypeKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END 
	FROM
		mergedTransactionTypes TT

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
				{{ DimTransactionTypes }}
			WHERE
				TransactionTypeKey = 0
		)

)

SELECT 
	*
INTO
	#DimTransactionTypes
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	TT2
SET
	TT2.TransactionType = TT.TransactionType,
	TT2.LoadDate = TT.LoadDate
FROM
	#DimTransactionTypes TT JOIN
	{{ DimTransactionTypes }} TT2 ON
		TT2.WWITransactionTypeID = TT.WWITransactionTypeID
WHERE
	TT.[Exists] = 1

-- Insert New
INSERT INTO {{ DimTransactionTypes }}
(
	TransactionTypeKey,
	WWITransactionTypeID,
	TransactionType,
	LoadDate
)
SELECT
	TT.TransactionTypeKey,
	TT.WWITransactionTypeID,
	TT.TransactionType,
	TT.LoadDate
FROM
	#DimTransactionTypes TT 
WHERE
	TT.[Exists] = 0
ORDER BY
	TT.TransactionTypeKey

COMMIT TRAN