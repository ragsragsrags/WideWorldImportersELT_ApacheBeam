DECLARE MaxSupplierKey INT64;

SET MaxSupplierKey = 
(
    SELECT
        IFNULL(MAX(SupplierKey), 0)
    FROM
        {{ DimSuppliers }}
);

CREATE TEMP TABLE TempDimSuppliers AS
WITH supplierCategoriesChanged AS 
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

	UNION ALL

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

	UNION ALL

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
		CASE
			WHEN S.SupplierKey IS NULL THEN CAST(MaxSupplierKey AS INTEGER) + (ROW_NUMBER() OVER(ORDER BY S.SupplierKey, S.SupplierID))
			ELSE S.SupplierKey
		END AS SupplierKey,
		S.SupplierID AS WWISupplierID,
		S.SupplierName AS Supplier,
		SCA.SupplierCategoryName AS Category,
		PCA.FullName AS PrimaryContact,
		S.SupplierReference AS SupplierReference,
		S.PaymentDays AS PaymentDays,
		S.DeliveryPostalCode AS PostalCode,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE
			WHEN S.SupplierKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
	FROM
		mergedSuppliers S LEFT JOIN
		supplierCategoriesAvailable SCA ON
			S.SupplierCategoryID = SCA.SupplierCategoryID LEFT JOIN
		primaryContactsAvailable PCA ON
			S.PrimaryContactPersonID = PCA.PersonID

	UNION ALL

	SELECT
		0 AS SupplierKey,
		0 AS WWISupplierID,
		'Unknown' AS Supplier,
		'N/A' AS Category,
		'N/A' AS PrimaryContact,
		'N/A' AS SupplierReference,
		0 AS PaymentDays,
		'N/A' AS PostalCode,
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
				{{ DimSuppliers }}
			WHERE
				SupplierKey = 0
		)

)

SELECT 
	*
FROM
	final;

-- Update Existing
UPDATE
	{{ DimSuppliers }} S2
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
	TempDimSuppliers S 
WHERE
	S.Exist = TRUE AND
	S2.WWISupplierID = S.WWISupplierID;

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
	CAST(NULL AS DATETIME)
FROM
	TempDimSuppliers S 
WHERE
	S.Exist = FALSE
ORDER BY
	S.SupplierKey;