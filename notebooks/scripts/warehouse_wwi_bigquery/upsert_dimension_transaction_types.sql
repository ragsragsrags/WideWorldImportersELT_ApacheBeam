DECLARE MaxTransactionTypeKey INT64;

SET MaxTransactionTypeKey = 
(
    SELECT
        IFNULL(MAX(TransactionTypeKey), 0)
    FROM
        {{ DimTransactionTypes }}
);

CREATE TEMP TABLE TempDimTransactionTypes AS
WITH mergedTransactionTypes AS
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
		CASE
			WHEN TT.TransactionTypeKey IS NULL THEN CAST(MaxTransactionTypeKey AS INTEGER) + (ROW_NUMBER() OVER(ORDER BY TT.TransactionTypeKey, TT.TransactionTypeID))
			ELSE TT.TransactionTypeKey
		END AS TransactionTypeKey,
		TT.TransactionTypeID AS WWITransactionTypeID,
		TT.TransactionTypeName AS TransactionType,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE
			WHEN TT.TransactionTypeKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist 
	FROM
		mergedTransactionTypes TT

	UNION ALL

	SELECT
		0 AS TransactionTypeKey,
		0 AS WWITransactionTypeID,
		'Unknown' AS TransactionType,
		CAST('<< NewCutoffDate >>' AS DATETIME),
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
				{{ DimTransactionTypes }}
			WHERE
				TransactionTypeKey = 0
		)
)

SELECT 
	*
FROM
	final;

-- Update Existing
UPDATE
	{{ DimTransactionTypes }} TT2
SET
	TT2.TransactionType = TT.TransactionType,
	TT2.LoadDate = TT.LoadDate
FROM
	TempDimTransactionTypes TT 
WHERE
	TT.Exist = TRUE AND
	TT2.WWITransactionTypeID = TT.WWITransactionTypeID;

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
	TempDimTransactionTypes TT 
WHERE
	TT.Exist = FALSE
ORDER BY
	TT.TransactionTypeKey;