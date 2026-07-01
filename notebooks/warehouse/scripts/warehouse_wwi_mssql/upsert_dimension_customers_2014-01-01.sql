DECLARE @MaxCustomerKey INT 
    
SELECT
    @MaxCustomerKey = ISNULL(MAX(CustomerKey), 0)
FROM
    {{ DimCustomers }}

IF OBJECT_ID('tempdb..#DimCustomers') IS NOT NULL
    DROP TABLE #DimCustomers

;WITH buyingGroupsChanged AS 
(

	SELECT
		BG.BuyingGroupID
	FROM
		{{ SalesBuyingGroups }} BG
	WHERE
		BG.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN BG.ValidFrom AND BG.ValidTo 

	UNION

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

	UNION

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

	UNION

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

	UNION

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

	UNION

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

	UNION

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

	UNION

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
        [CustomerKey] = DC.CustomerKey,
        C.*,
        [Exists] = 
            CASE
                WHEN DC.WWICustomerID IS NOT NULL THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END
    FROM
        customers C LEFT JOIN
        {{ DimCustomers }} DC ON
            DC.WWICustomerID = C.CustomerID
        

    UNION ALL

    SELECT
        [CustomerKey] = DC.CustomerKey,
        CA.*,
        [Exists] = 
            CASE
                WHEN DC.WWICustomerID IS NOT NULL THEN CAST(1 AS BIT)
                ELSE CAST(0 AS BIT)
            END
    FROM
        customersArchive CA LEFT JOIN
        {{ DimCustomers }} DC ON
            DC.WWICustomerID = CA.CustomerID

),

final AS (

	SELECT
		[CustomerKey] = 
            CASE 
                WHEN C.CustomerKey IS NULL THEN @MaxCustomerKey + (ROW_NUMBER() OVER (ORDER BY C.[Exists], C.[CustomerID]))
                ELSE C.CustomerKey
            END,
		[WWICustomerID] = C.CustomerID,
		[WWIDeliveryCityID] = ISNULL(C.DeliveryCityID, 0),
		[Customer] = C.CustomerName,
		[BillToCustomer] = CA.CustomerName,
		[Category] = CCA.CustomerCategoryName,
		[BuyingGroup] = ISNULL(BGA.BuyingGroupName, ''),
		[PrimaryContact] = PCA.FullName,
		[PostalCode] = C.DeliveryPostalCode,
		[Exists] = C.[Exists],
		[LoadDate] = '<< NewCutoffDate >>'
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
		[CustomerKey] = 0,
		[WWICustomerID] = 0, 
		[WWIDeliveryCityID] = 0, 
		[Customer] = 'N/A', 
		[BillToCustomer] = 'N/A', 
		[Category] = 'N/A',
		[BuyingGroup] = 'N/A', 
		[PrimaryContact] = 'N/A', 
		[PostalCode] = 'N/A', 
		[Exists] = 0,
		[LoadDate] = '<< NewCutoffDate >>'
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
INTO
	#DimCustomers
FROM
	Final

BEGIN TRAN

-- Update Existing
UPDATE
	C2
SET
	C2.WWIDeliveryCityID = C.WWIDeliveryCityID,
	C2.Customer = C.Customer,
	C2.BillToCustomer = C.BillToCustomer,
	C2.Category = C.Category,
	C2.BuyingGroup = C.BuyingGroup,
	C2.PrimaryContact = C.PrimaryContact,
	C2.PostalCode = C.PostalCode,
	C2.LoadDate = '<< NewCutoffDate >>',
	C2.LastLoadDate = C2.LoadDate
FROM
	#DimCustomers C JOIN
	{{ DimCustomers }} C2 ON
		C2.WWICustomerID = C.WWICustomerID
WHERE
	C.[Exists] = 1

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
	'<< NewCutoffDate >>',
	NULL
FROM
	#DimCustomers C 
WHERE
	C.[Exists] = 0
ORDER BY
	C.WWICustomerID

COMMIT TRAN
