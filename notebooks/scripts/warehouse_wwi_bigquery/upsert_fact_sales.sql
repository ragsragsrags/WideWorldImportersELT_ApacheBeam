DECLARE MaxSaleKey INT64;

SET MaxSaleKey = 
(
    SELECT
        IFNULL(MAX(SaleKey), 0)
    FROM
        {{ FctSales }}
);

CREATE TEMP TABLE TempFctSales AS
WITH stockItemsChanged AS 
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
	
	UNION ALL
	
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
		CASE 
			WHEN FS.SaleKey IS NULL THEN CAST(MaxSaleKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY FS.SaleKey, I.InvoiceID, IL.InvoiceLineID))
			ELSE FS.SaleKey
		END AS SaleKey,
		IFNULL(CT.CityKey, 0) AS CityKey,
		IFNULL(C.CustomerKey, 0) AS CustomerKey,
		IFNULL(BC.CustomerKey, 0) AS BillToCustomerKey,
		IFNULL(SI.StockItemKey, 0) AS StockItemKey,
		CAST(I.InvoiceDate AS DATE) AS InvoiceDateKey,
		CAST(I.ConfirmedDeliveryTime AS DATE) AS DeliveryDateKey,
		E.EmployeeKey AS SalespersonKey,
		I.InvoiceID AS WWIInvoiceID,
		IL.InvoiceLineID AS WWIInvoiceLineID,
		IL.Description AS Description,
		PTA.PackageTypeName AS Package,
		IL.Quantity AS Quantity,
		IL.UnitPrice AS UnitPrice,
		IL.TaxRate AS TaxRate,
		(IL.ExtendedPrice - IL.TaxAmount) AS TotalExcludingTax,
		IL.TaxAmount AS TaxAmount,
		IL.LineProfit AS Profit,
		IL.ExtendedPrice AS TotalIncludingTax,
		CASE 
			WHEN SI.IsChillerStock = FALSE THEN IL.Quantity 
			ELSE 0 
		END AS TotalDryItems,
		CASE 
			WHEN SI.IsChillerStock <> FALSE THEN IL.Quantity 
			ELSE 0 
		END AS TotalChillerItems,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE 
			WHEN FS.SaleKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
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
FROM
	final;

-- Update Existing
UPDATE
	{{ FctSales }} S2
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
	TempFctSales S 
WHERE
	S.Exist = TRUE AND
	S2.WWIInvoiceID = S.WWIInvoiceID AND
	S2.WWIInvoiceLineID = S.WWIInvoiceLineID;

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
	TempFctSales S 
WHERE
	S.Exist = FALSE
ORDER BY
	S.SaleKey;