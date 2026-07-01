DECLARE @MaxSupplierKey INT 
    
SELECT
    @MaxSupplierKey = ISNULL(MAX(SupplierKey), 0)
FROM
    {{ DimSuppliers }}

IF OBJECT_ID('tempdb..#DimSuppliers') IS NOT NULL
    DROP TABLE #DimSuppliers

;WITH supplierCategoriesChanged AS 
(

	SELECT
		SC.SupplierCategoryID
	FROM
		{{ PurchasingSupplierCategories }} SC
	WHERE
		SC.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN SC.ValidFrom AND SC.ValidTo 

	UNION ALL

	SELECT
		SCA.SupplierCategoryID
	FROM
		{{ PurchasingSupplierCategoriesArchive }} SCA
	WHERE
		SCA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN SCA.ValidFrom AND SCA.ValidTo 

),

primaryContactsChanged AS 
(

	SELECT
		P.PersonID
	FROM
		{{ ApplicationPeople }} P
	WHERE
		P.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo 

	UNION ALL

	SELECT
		PA.PersonID
	FROM
		{{ ApplicationPeopleArchive }} PA
	WHERE
		PA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo 

),

supplierCategoriesAvailable AS 
(

	SELECT
		SC.SupplierCategoryID,
		SC.SupplierCategoryName
	FROM
		{{ PurchasingSupplierCategories }} SC
	WHERE
		'<< NewCutoffDate >>' BETWEEN SC.ValidFrom AND SC.ValidTo

	UNION

	SELECT
		SCA.SupplierCategoryID,
		SCA.SupplierCategoryName
	FROM
		{{ PurchasingSupplierCategoriesArchive }} SCA
	WHERE
		'<< NewCutoffDate >>' BETWEEN SCA.ValidFrom AND SCA.ValidTo

),

primaryContactsAvailable AS 
(

	SELECT
		P.PersonID,
		P.FullName
	FROM
		{{ ApplicationPeople }} P
	WHERE
		'<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo

	UNION

	SELECT
		PA.PersonID,
		PA.FullName
	FROM
		{{ ApplicationPeopleArchive }} PA
	WHERE
		'<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo

),

mergedSuppliers AS
(

	SELECT
		DS.SupplierKey,
		S.SupplierID,
		S.SupplierName,
		S.SupplierReference,
		S.PaymentDays,
		S.DeliveryPostalCode,
		S.SupplierCategoryID,
		S.PrimaryContactPersonID 
	FROM
		{{ PurchasingSuppliers }} S LEFT JOIN
		{{ DimSuppliers }} DS ON
			DS.WWISupplierID = S.SupplierID
	WHERE
		(
			S.ValidFrom > '<< LastCutoffDate >>' OR
			S.SupplierCategoryID IN
			(
				SELECT
					SCC.SupplierCategoryID
				FROM
					supplierCategoriesChanged SCC
			) OR
			S.PrimaryContactPersonID IN
			(
				SELECT
					PCC.PersonID
				FROM
					primaryContactsChanged PCC
			)
		) AND
		'<< NewCutoffDate >>' BETWEEN S.ValidFrom AND S.ValidTo

	UNION ALL

	SELECT
		DS.SupplierKey,
		S.SupplierID,
		S.SupplierName,
		S.SupplierReference,
		S.PaymentDays,
		S.DeliveryPostalCode,
		S.SupplierCategoryID,
		S.PrimaryContactPersonID
	FROM
		{{ PurchasingSuppliersArchive }} S LEFT JOIN
		{{ DimSuppliers }} DS ON
			DS.WWISupplierID = S.SupplierID
	WHERE
		(
			S.ValidFrom > '<< LastCutoffDate >>' OR
			S.SupplierCategoryID IN
			(
				SELECT
					SCC.SupplierCategoryID
				FROM
					supplierCategoriesChanged SCC
			) OR
			S.PrimaryContactPersonID IN
			(
				SELECT
					PCC.PersonID
				FROM
					primaryContactsChanged PCC
			)
		) AND
		'<< NewCutoffDate >>' BETWEEN S.ValidFrom AND S.ValidTo

),

final AS 
(

	SELECT
		[SupplierKey] = 
			CASE
				WHEN S.SupplierKey IS NULL THEN @MaxSupplierKey + (ROW_NUMBER() OVER(ORDER BY S.SupplierKey, S.SupplierID))
				ELSE S.SupplierKey
			END,
		[WWISupplierID] = S.SupplierID,
		[Supplier] = S.SupplierName,
		[Category] = SCA.SupplierCategoryName,
		[PrimaryContact] = PCA.FullName,
		S.SupplierReference,
		S.PaymentDays,
		[PostalCode] = S.DeliveryPostalCode,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN S.SupplierKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM
		mergedSuppliers S LEFT JOIN
		supplierCategoriesAvailable SCA ON
			S.SupplierCategoryID = SCA.SupplierCategoryID LEFT JOIN
		primaryContactsAvailable PCA ON
			S.PrimaryContactPersonID = PCA.PersonID

	UNION ALL

	SELECT
		[SupplierKey] = 0,
		[WWISupplierID] = 0,
		[Supplier] = 'Unknown',
		[Category] = 'N/A',
		[PrimaryContact] = 'N/A',
		[SupplierReference] = 'N/A',
		[PaymentDays] = 0,
		[PostalCode] = 'N/A',
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = CAST(0 AS BIT)
	WHERE
		NOT EXISTS
		(
			SELECT
				1
			FROM
				{{ DimSuppliers }}
			WHERE
				SupplierKey = 0
		)

)

SELECT 
	*
INTO
	#DimSuppliers
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	S2
SET
	S2.Supplier = S.Supplier,
	S2.Category = S.Category,
	S2.PrimaryContact = S.PrimaryContact,
	S2.SupplierReference = S.SupplierReference,
	S2.PaymentDays = S.PaymentDays,
	S2.PostalCode = S.PostalCode,
	S2.LoadDate = S.LoadDate,
	S2.LastLoadDate = S2.LoadDate
FROM
	#DimSuppliers S JOIN
	{{ DimSuppliers }} S2 ON
		S2.WWISupplierID = S.WWISupplierID
WHERE
	S.[Exists] = 1

-- Insert New
INSERT INTO {{ DimSuppliers }}
(
	SupplierKey,
	WWISupplierID,
	Supplier,
	Category,
	PrimaryContact,
	SupplierReference,
	PaymentDays,
	PostalCode,
	LoadDate,
	LastLoadDate
)
SELECT
	S.SupplierKey,
	S.WWISupplierID,
	S.Supplier,
	S.Category,
	S.PrimaryContact,
	S.SupplierReference,
	S.PaymentDays,
	S.PostalCode,
	S.LoadDate,
	NULL
FROM
	#DimSuppliers S 
WHERE
	S.[Exists] = 0
ORDER BY
	S.SupplierKey

COMMIT TRAN