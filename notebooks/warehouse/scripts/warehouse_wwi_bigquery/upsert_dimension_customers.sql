DECLARE MaxCustomerKey INT64;

SET MaxCustomerKey = 
(
    SELECT
        IFNULL(MAX(CustomerKey), 0)
    FROM
        {{ DimCustomers }}
);

CREATE TEMP TABLE TempDimCustomers AS
WITH buyingGroupsChanged AS 
(

	SELECT
		BG.BuyingGroupID
	FROM
		{{ SalesBuyingGroups }} BG
	WHERE
		BG.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN BG.ValidFrom AND BG.ValidTo 

	UNION DISTINCT

	SELECT
		BGA.BuyingGroupID
	FROM
		{{ SalesBuyingGroupsArchive }} BGA
	WHERE
		BGA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN BGA.ValidFrom AND BGA.ValidTo 

),

customerCategoriesChanged AS 
(

	SELECT
		CC.CustomerCategoryID
	FROM
		{{ SalesCustomerCategories }} CC
	WHERE
		CC.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN CC.ValidFrom AND CC.ValidTo 

	UNION DISTINCT

	SELECT
		CCA.CustomerCategoryID
	FROM
		{{ SalesCustomerCategoriesArchive }} CCA
	WHERE
		CCA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN CCA.ValidFrom AND CCA.ValidTo 

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

	UNION DISTINCT

	SELECT
		PA.PersonID
	FROM
		{{ ApplicationPeopleArchive }} PA
	WHERE
		PA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo 

),

customersAvailable AS 
(

	SELECT
		C.CustomerID,
		C.CustomerName
	FROM
		{{ SalesCustomers }} C
	WHERE
		'<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

	UNION DISTINCT

	SELECT
		CA.CustomerID,
		CA.CustomerName
	FROM
		{{ SalesCustomersArchive }} CA
	WHERE
		'<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo

),

customerCategoriesAvailable AS 
(

	SELECT
		CC.CustomerCategoryID,
		CC.CustomerCategoryName
	FROM
		{{ SalesCustomerCategories }} CC
	WHERE
		'<< NewCutoffDate >>' BETWEEN CC.ValidFrom AND CC.ValidTo

	UNION DISTINCT

	SELECT
		CCA.CustomerCategoryID,
		CCA.CustomerCategoryName
	FROM
		{{ SalesCustomerCategoriesArchive }} CCA
	WHERE
		'<< NewCutoffDate >>' BETWEEN CCA.ValidFrom AND CCA.ValidTo

),

buyingGroupsAvailable AS 
(

	SELECT
		BG.BuyingGroupID,
		BG.BuyingGroupName
	FROM
		{{ SalesBuyingGroups }} BG
	WHERE
		'<< NewCutoffDate >>' BETWEEN BG.ValidFrom AND BG.ValidTo

	UNION DISTINCT

	SELECT
		BGA.BuyingGroupID,
		BGA.BuyingGroupName
	FROM
		{{ SalesBuyingGroupsArchive }} BGA
	WHERE
		'<< NewCutoffDate >>' BETWEEN BGA.ValidFrom AND BGA.ValidTo

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

	UNION DISTINCT

	SELECT
		PA.PersonID,
		PA.FullName
	FROM
		{{ ApplicationPeopleArchive }} PA
	WHERE
		'<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo

),

customers AS 
(

	SELECT
		C.*
	FROM
		{{ SalesCustomers }} C WHERE
		(
			C.ValidFrom > '<< LastCutoffDate >>' OR
			C.BuyingGroupID IN
			(
				SELECT
					BGC.BuyingGroupID
				FROM
					BuyingGroupsChanged BGC
                
			) OR
			C.CustomerCategoryID IN
			(
				SELECT
					CCC.CustomerCategoryID
				FROM
					CustomerCategoriesChanged CCC
			) OR
			C.PrimaryContactPersonID IN
			(
				SELECT
					PCC.PersonID
				FROM
					PrimaryContactsChanged PCC
			)
		) AND
		'<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

),

customersArchive AS 
(

	SELECT
		CA.*
	FROM
		{{ SalesCustomersArchive }} CA 
	WHERE
		(
			CA.ValidFrom > '<< LastCutoffDate >>' OR
			CA.BuyingGroupID IN
			(
				SELECT
					BGC.BuyingGroupID
				FROM
					BuyingGroupsChanged BGC
                
			) OR
			CA.CustomerCategoryID IN
			(
				SELECT
					CCC.CustomerCategoryID
				FROM
					CustomerCategoriesChanged CCC
			) OR
			CA.PrimaryContactPersonID IN
			(
				SELECT
					PCC.PersonID
				FROM
					PrimaryContactsChanged PCC
			)
		) AND
		'<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo

),

mergedCustomers AS 
(

	SELECT
        DC.CustomerKey AS CustomerKey,
        C.*,
		CASE
			WHEN DC.WWICustomerID IS NOT NULL THEN CAST(TRUE AS BOOLEAN)
			ELSE CAST(FALSE AS BOOLEAN)
		END AS Exist
    FROM
        customers C LEFT JOIN
        {{ DimCustomers }} DC ON
            DC.WWICustomerID = C.CustomerID
        
    UNION ALL

    SELECT
        DC.CustomerKey AS CustomerKey,
        CA.*,
		CASE
			WHEN DC.WWICustomerID IS NOT NULL THEN CAST(TRUE AS BOOLEAN)
			ELSE CAST(FALSE AS BOOLEAN)
		END AS Exist
    FROM
        customersArchive CA LEFT JOIN
        {{ DimCustomers }} DC ON
            DC.WWICustomerID = CA.CustomerID

),

final AS (

	SELECT
		CASE 
			WHEN C.CustomerKey IS NULL THEN CAST(MaxCustomerKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY C.Exist, C.CustomerID))
			ELSE C.CustomerKey
		END AS CustomerKey,
		C.CustomerID AS WWICustomerID,
		IFNULL(C.DeliveryCityID, 0) AS WWIDeliveryCityID,
		C.CustomerName AS Customer,
		CA.CustomerName AS BillToCustomer,
		CCA.CustomerCategoryName AS Category,
		IFNULL(BGA.BuyingGroupName, '') AS BuyingGroup,
		PCA.FullName AS PrimaryContact,
		C.DeliveryPostalCode AS PostalCode,
		C.Exist AS Exist,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate
	FROM
		mergedCustomers C LEFT JOIN
		CustomersAvailable CA ON
			CA.CustomerID = C.BillToCustomerID LEFT JOIN
		CustomerCategoriesAvailable CCA ON
			CCA.CustomerCategoryID = C.CustomerCategoryID LEFT JOIN
		BuyingGroupsAvailable BGA ON
			BGA.BuyingGroupID = C.BuyingGroupID LEFT JOIN
		PrimaryContactsAvailable PCA ON
			PCA.PersonID = C.PrimaryContactPersonID

	UNION ALL

    SELECT
		0 AS CustomerKey,
		0 AS WWICustomerID, 
		0 AS WWIDeliveryCityID, 
		'N/A' AS Customer, 
		'N/A' AS BillToCustomer, 
		'N/A' AS Category,
		'N/A' AS BuyingGroup, 
		'N/A' AS PrimaryContact, 
		'N/A' AS PostalCode, 
		FALSE AS Exist,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate
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
                {{ DimCustomers }}
            WHERE
                CustomerKey = 0
        )
	
)

SELECT
	*
FROM
	Final;

-- Update Existing
UPDATE
	{{ DimCustomers }} C2
SET
	C2.WWIDeliveryCityID = C.WWIDeliveryCityID,
	C2.Customer = C.Customer,
	C2.BillToCustomer = C.BillToCustomer,
	C2.Category = C.Category,
	C2.BuyingGroup = C.BuyingGroup,
	C2.PrimaryContact = C.PrimaryContact,
	C2.PostalCode = C.PostalCode,
	C2.LoadDate = C.LoadDate,
	C2.LastLoadDate = C2.LoadDate
FROM
	TempDimCustomers C 
WHERE
	C.Exist = TRUE AND
	C2.WWICustomerID = C.WWICustomerID;

-- Insert New
INSERT INTO {{ DimCustomers }}
(
	CustomerKey,
	WWICustomerID,
	WWIDeliveryCityID,
	Customer,
	BillToCustomer,
	Category,
	BuyingGroup,
	PrimaryContact,
	PostalCode,
	LoadDate,
	LastLoadDate
)
SELECT
	C.CustomerKey,
	C.WWICustomerID,
	C.WWIDeliveryCityID,
	C.Customer,
	C.BillToCustomer,
	C.Category,
	C.BuyingGroup,
	C.PrimaryContact,
	C.PostalCode,
	C.LoadDate,
	CAST(NULL AS DATETIME)
FROM
	TempDimCustomers C 
WHERE
	C.Exist = FALSE
ORDER BY
	C.WWICustomerID;