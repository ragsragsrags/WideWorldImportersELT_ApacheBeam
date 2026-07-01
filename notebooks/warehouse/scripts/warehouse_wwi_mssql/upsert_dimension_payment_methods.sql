DECLARE @LastCutoffDate DATETIME2 = '2012-12-31'
DECLARE @NewCutoffDate DATETIME2 = '2013-01-01'
DECLARE @MaxPaymentMethodKey INT 
    
SELECT
    @MaxPaymentMethodKey = ISNULL(MAX(PaymentMethodKey), 0)
FROM
    {{ DimPaymentMethods }}

IF OBJECT_ID('tempdb..#DimPaymentMethods') IS NOT NULL
    DROP TABLE #DimPaymentMethods

;WITH mergedPaymentMethods AS 
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
		[PaymentMethodKey] = 
			CASE 
				WHEN PM.PaymentMethodKey IS NULL THEN @MaxPaymentMethodKey + (ROW_NUMBER() OVER (ORDER BY PM.PaymentMethodKey, PM.PaymentMethodID))
				ELSE PM.PaymentMethodKey
			END,
		[WWIPaymentMethodID] = PM.PaymentMethodID,
		[PaymentMethod] = PM.PaymentMethodName,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN PM.PaymentMethodKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM
		mergedPaymentMethods PM

	UNION ALL

	SELECT
		[PaymentMethodKey] = 0,
		[WWI`PaymentMethodID] = 0,
		[PaymentMethod] = 'Unknown',
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = CAST(0 AS BIT)
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
INTO
	#DimPaymentMethods
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	PM2
SET
	PM2.PaymentMethod = PM.PaymentMethod,
	PM2.LoadDate = PM.LoadDate,
	PM2.LastLoadDate = PM2.LoadDate
FROM
	#DimPaymentMethods PM JOIN
	{{ DimPaymentMethods }} PM2 ON
		PM2.WWIPaymentMethodID = PM.WWIPaymentMethodID
WHERE
	PM.[Exists] = 1

-- Insert New
INSERT INTO {{ DimPaymentMethods }}
(
	PaymentMethodKey,
	WWIPaymentMethodID,
	PaymentMethod,
	LoadDate,
	LastLoadDate
)
SELECT
	PM.PaymentMethodKey,
	PM.WWIPaymentMethodID,
	PM.PaymentMethod,
	PM.LoadDate,
	NULL
FROM
	#DimPaymentMethods PM 
WHERE
	PM.[Exists] = 0
ORDER BY
	PM.PaymentMethodKey

COMMIT TRAN