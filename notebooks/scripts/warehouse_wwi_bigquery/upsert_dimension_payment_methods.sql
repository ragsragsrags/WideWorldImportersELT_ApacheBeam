DECLARE MaxPaymentMethodKey INT64;

SET MaxPaymentMethodKey = 
(
    SELECT
        IFNULL(MAX(PaymentMethodKey), 0)
    FROM
        {{ DimPaymentMethods }}
);

CREATE TEMP TABLE TempDimPaymentMethods AS
WITH mergedPaymentMethods AS 
(

	SELECT
		DPM.PaymentMethodKey,
		PM.PaymentMethodID,
		PM.PaymentMethodName
	FROM
		{{ ApplicationPaymentMethods }} PM LEFT JOIN
		{{ DimPaymentMethods }} DPM ON
			DPM.WWIPaymentMethodID = PM.PaymentMethodID
	WHERE
		PM.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PM.ValidFrom AND PM.ValidTo 

	UNION ALL

	SELECT
		DPM.PaymentMethodKey,
		PM.PaymentMethodID,
		PM.PaymentMethodName
	FROM
		{{ ApplicationPaymentMethodsArchive }} PM LEFT JOIN
		{{ DimPaymentMethods }} DPM ON
			DPM.WWIPaymentMethodID = PM.PaymentMethodID
	WHERE
		PM.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PM.ValidFrom AND PM.ValidTo 

),

final AS
(

	SELECT  
		CASE 
			WHEN PM.PaymentMethodKey IS NULL THEN CAST(MaxPaymentMethodKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY PM.PaymentMethodKey, PM.PaymentMethodID))
			ELSE PM.PaymentMethodKey
		END AS PaymentMethodKey,
		PM.PaymentMethodID AS WWIPaymentMethodID,
		PM.PaymentMethodName AS PaymentMethod,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate, 
		CASE
			WHEN PM.PaymentMethodKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
	FROM
		mergedPaymentMethods PM

	UNION ALL

	SELECT
		0 AS PaymentMethodKey,
		0 AS WWIPaymentMethodID,
		'Unknown' AS PaymentMethod,
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
				{{ DimPaymentMethods }} 
			WHERE
				PaymentMethodKey = 0
		)

)

SELECT 
	*
FROM
	final;

-- Update Existing
UPDATE
	{{ DimPaymentMethods }} PM2
SET
	PM2.PaymentMethod = PM.PaymentMethod,
	PM2.LoadDate = PM.LoadDate
FROM
	TempDimPaymentMethods PM 
WHERE
	PM.Exist = TRUE AND
	PM2.WWIPaymentMethodID = PM.WWIPaymentMethodID;

-- Insert New
INSERT INTO {{ DimPaymentMethods }}
(
	PaymentMethodKey,
	WWIPaymentMethodID,
	PaymentMethod,
	LoadDate
)
SELECT
	PM.PaymentMethodKey,
	PM.WWIPaymentMethodID,
	PM.PaymentMethod,
	PM.LoadDate
FROM
	TempDimPaymentMethods PM 
WHERE
	PM.Exist = FALSE
ORDER BY
	PM.PaymentMethodKey;