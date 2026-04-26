DECLARE @MaxSaleKey INT 
    
SELECT
    @MaxSaleKey = ISNULL(MAX(SaleKey), 0)
FROM
    {{ FctSales }}

IF OBJECT_ID('tempdb..#FctSales') IS NOT NULL
    DROP TABLE #FctSales

;WITH stockItemsChanged AS 
(

	SELECT
		ST.StockItemID
	FROM
		{{ WarehouseStockItems }} ST
	WHERE
		ST.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN ST.ValidFrom  AND ST.ValidTo

	UNION ALL

	SELECT
		SIA.StockItemID
	FROM
		{{ WarehouseStockItemsArchive }} SIA
	WHERE
		SIA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo

),

packageTypesChanged AS 
(

	SELECT
		PT.PackageTypeID
	FROM
		{{ WarehousePackageTypes }} PT
	WHERE
		PT.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PT.ValidFrom  AND PT.ValidTo

	UNION ALL

	SELECT
		PTA.PackageTypeID
	FROM
		{{ WarehousePackageTypesArchive }} PTA
	WHERE
		PTA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PTA.ValidFrom  AND PTA.ValidTo

),

packageTypesAvailable AS 
(

	SELECT
		PT.PackageTypeID,
		PT.PackageTypeName
	FROM
		{{ WarehousePackageTypes }} PT
	WHERE
		'<< NewCutoffDate >>' BETWEEN PT.ValidFrom AND PT.ValidTo
	
	UNION
	
	SELECT
		PTA.PackageTypeID,
		PTA.PackageTypeName
	FROM
		{{ WarehousePackageTypesArchive }} PTA
	WHERE
		'<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo

),

final AS 
(

	SELECT 
		[SaleKey] =	
			CASE 
				WHEN FS.SaleKey IS NULL THEN @MaxSaleKey + (ROW_NUMBER() OVER (ORDER BY FS.SaleKey, I.InvoiceID, IL.InvoiceLineID))
				ELSE FS.SaleKey
			END,
		[CityKey] = ISNULL(CT.CityKey, 0),
		[CustomerKey] = ISNULL(C.CustomerKey, 0),
		[BillToCustomerKey] = ISNULL(BC.CustomerKey, 0),
		[StockItemKey] = ISNULL(SI.StockItemKey, 0),
		[InvoiceDateKey] = CAST(I.InvoiceDate AS DATE),
		[DeliveryDateKey] = CAST(I.ConfirmedDeliveryTime AS DATE),
		[SalespersonKey] = E.EmployeeKey,
		[WWIInvoiceID] = I.InvoiceID,
		[WWIInvoiceLineID] = IL.InvoiceLineID,
		[Description] = IL.Description,
		[Package] = PTA.PackageTypeName,
		[Quantity] = IL.Quantity,
		[UnitPrice] = IL.UnitPrice,
		[TaxRate] = IL.TaxRate,
		[TotalExcludingTax] = IL.ExtendedPrice - IL.TaxAmount,
		[TaxAmount] = IL.TaxAmount,
		[Profit] = IL.LineProfit,
		[TotalIncludingTax] = IL.ExtendedPrice,
		[TotalDryItems] = 
			CASE 
				WHEN SI.IsChillerStock = 0 THEN IL.Quantity 
				ELSE 0 
			END,
		[TotalChillerItems] =
			CASE 
				WHEN SI.IsChillerStock <> 0 THEN IL.Quantity 
				ELSE 0 
			END,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] =	
			CASE 
				WHEN FS.SaleKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM 
		{{ SalesInvoices }} AS I JOIN 
		{{ SalesInvoiceLines }} IL ON 
			I.InvoiceID = IL.InvoiceID LEFT JOIN
		{{ DimStockItems }} SI ON
			IL.StockItemID = SI.WWIStockItemID LEFT JOIN
		packageTypesAvailable PTA ON
			IL.PackageTypeID = PTA.PackageTypeID LEFT JOIN
		{{ DimCustomers }} C ON
			I.CustomerID = C.WWICustomerID LEFT JOIN
		{{ DimCities }} CT ON
			C.WWIDeliveryCityID = CT.WWICityID LEFT JOIN
		{{ DimCustomers }} BC ON
			I.BillToCustomerID = BC.WWICustomerID LEFT JOIN
		{{ DimEmployees }} E ON
			I.SalespersonPersonID = E.WWIEmployeeID LEFT JOIN
		{{ FctSales }} FS ON
			FS.WWIInvoiceID = I.InvoiceID AND
			FS.WWIInvoiceLineID = IL.InvoiceLineID
	WHERE 
		(
			I.LastEditedWhen > '<< LastCutoffDate >>' OR
			IL.LastEditedWhen > '<< LastCutoffDate >>' OR
			IL.PackageTypeID IN (
				SELECT 
					PTC.PackageTypeID
				FROM 
					packageTypesChanged PTC
			) OR
			IL.StockItemID IN (
				SELECT 
					SIC.StockItemID
				FROM 
					stockItemsChanged SIC
			) 
		) AND
		I.LastEditedWhen <= '<< NewCutoffDate >>' AND
		IL.LastEditedWhen <= '<< NewCutoffDate >>'

)

SELECT 
	*
INTO
	#FctSales
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	S2
SET
	S2.CityKey = S.CityKey,
	S2.CustomerKey = S.CustomerKey,
	S2.BillToCustomerKey = S.BillToCustomerKey,
	S2.StockItemKey = S.StockItemKey,
	S2.InvoiceDateKey = S.InvoiceDateKey,
	S2.DeliveryDateKey = S.DeliveryDateKey,
	S2.SalespersonKey = S.SalespersonKey,
	S2.Description = S.Description,
	S2.Package = S.Package,
	S2.Quantity = S.Quantity,
	S2.UnitPrice = S.UnitPrice,
	S2.TaxRate = S.TaxRate,
	S2.TotalExcludingTax = S.TotalExcludingTax,
	S2.TaxAmount = S.TaxAmount,
	S2.Profit = S.Profit,
	S2.TotalIncludingTax = S.TotalIncludingTax,
	S2.TotalDryItems = S.TotalDryItems,
	S2.TotalChillerItems = S.TotalChillerItems,
	S2.LoadDate = S.LoadDate
FROM
	#FctSales S JOIN
	{{ FctSales }} S2 ON
		S2.WWIInvoiceID = S.WWIInvoiceID AND
		S2.WWIInvoiceLineID = S.WWIInvoiceLineID
WHERE
	S.[Exists] = 1

-- Insert New
INSERT INTO {{ FctSales }}
(
	SaleKey,
	CityKey,
	CustomerKey,
	BillToCustomerKey,
	StockItemKey,
	InvoiceDateKey,
	DeliveryDateKey,
	SalespersonKey,
	WWIInvoiceID,
	WWIInvoiceLineID,
	Description,
	Package,
	Quantity,
	UnitPrice,
	TaxRate,
	TotalExcludingTax,
	TaxAmount,
	Profit,
	TotalIncludingTax,
	TotalDryItems,
	TotalChillerItems,
	LoadDate
)
SELECT
	S.SaleKey,
	S.CityKey,
	S.CustomerKey,
	S.BillToCustomerKey,
	S.StockItemKey,
	S.InvoiceDateKey,
	S.DeliveryDateKey,
	S.SalespersonKey,
	S.WWIInvoiceID,
	S.WWIInvoiceLineID,
	S.Description,
	S.Package,
	S.Quantity,
	S.UnitPrice,
	S.TaxRate,
	S.TotalExcludingTax,
	S.TaxAmount,
	S.Profit,
	S.TotalIncludingTax,
	S.TotalDryItems,
	S.TotalChillerItems,
	S.LoadDate
FROM
	#FctSales S 
WHERE
	S.[Exists] = 0
ORDER BY
	S.SaleKey

COMMIT TRAN