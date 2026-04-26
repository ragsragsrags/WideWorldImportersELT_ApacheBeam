DECLARE @MaxOrderKey INT 
    
SELECT
    @MaxOrderKey = ISNULL(MAX(OrderKey), 0)
FROM
    {{ FctOrders }}

IF OBJECT_ID('tempdb..#FctOrders') IS NOT NULL
    DROP TABLE #FctOrders

;WITH packageTypesChanged AS 
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
		'<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo

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

final AS (

	SELECT
		[OrderKey] = 
			CASE
				WHEN FO.OrderKey IS NULL THEN @MaxOrderKey + (ROW_NUMBER() OVER (ORDER BY FO.OrderKey, O.OrderID, OL.OrderLineID))
				ELSE FO.OrderKey
			END,
		[CityKey] = ISNULL(CT.CityKey, 0),
		[CustomerKey] = ISNULL(C.CustomerKey, 0),
		[StockItemKey] = ISNULL(SI.StockItemKey, 0),
		[OrderDateKey] = CAST(O.OrderDate AS DATE),
		[PickedDateKey] = CAST(O.PickingCompletedWhen AS DATE),
		[SalesPersonKey] = ISNULL(E.EmployeeKey, 0),
		[PickerKey] = ISNULL(E2.EmployeeKey, 0),
		[WWIOrderID] = O.OrderID,
		[WWIOrderLineID] = OL.OrderLineID,
		[WWIBackorderID] = O.BackorderOrderID,
		[Description] = OL.Description,
		[Package] = PTA.PackageTypeName,
		[Quantity] = OL.Quantity,
		[UnitPrice] = OL.UnitPrice,
		[TaxRate] = OL.TaxRate,
		[TotalExcludingTax] = ROUND(OL.Quantity * OL.UnitPrice, 2),
		[TaxAmount] = ROUND((OL.Quantity * OL.UnitPrice * OL.TaxRate) / 100.0, 2),
		[TotalIncludingTax] = (
			ROUND(OL.Quantity * OL.UnitPrice, 2) + 
			ROUND((OL.Quantity * OL.UnitPrice * OL.TaxRate) / 100.0, 2)
		),
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN FO.OrderKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM
		{{ SalesOrders }} O JOIN
		{{ SalesOrderLines }} OL ON
			O.OrderID = OL.OrderID LEFT JOIN
		{{ DimCustomers }} C ON
			O.CustomerID = C.WWICustomerID LEFT JOIN
		{{ DimCities }} CT ON
			C.WWIDeliveryCityID = CT.WWICityID LEFT JOIN
		{{ DimStockItems }} SI ON
			OL.StockItemID = SI.WWIStockItemID LEFT JOIN
		{{ DimEmployees }} E ON
			O.SalespersonPersonID = E.WWIEmployeeID LEFT JOIN
		{{ DimEmployees }} E2 ON
			O.PickedByPersonID = E2.WWIEmployeeID LEFT JOIN
		packageTypesAvailable PTA ON
			OL.PackageTypeID = PTA.PackageTypeID LEFT JOIN
		{{ FctOrders }} FO ON
			FO.WWIOrderID = O.OrderID AND
			FO.WWIOrderLineID = OL.OrderLineID
	WHERE 
		(
			O.LastEditedWhen > '<< LastCutoffDate >>' OR
			OL.LastEditedWhen > '<< LastCutoffDate >>' OR
			OL.PackageTypeID IN (
				SELECT 
					PTC.PackageTypeID
				FROM 
					packageTypesChanged PTC
			)
		) AND
		O.LastEditedWhen <= '<< NewCutoffDate >>' AND
		OL.LastEditedWhen <= '<< NewCutoffDate >>'

)

SELECT 
	*
INTO
	#FctOrders
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	O2
SET
	O2.CityKey = O.CityKey,
	O2.CustomerKey = O.CustomerKey,
	O2.StockItemKey = O.StockItemKey,
	O2.OrderDateKey = O.OrderDateKey,
	O2.PickedDateKey = O.PickedDateKey,
	O2.SalesPersonKey = O.SalesPersonKey,
	O2.PickerKey = O.PickerKey,
	O2.WWIBackorderID = O.WWIBackorderID,
	O2.Description = O.Description,
	O2.Package = O.Package,
	O2.Quantity = O.Quantity,
	O2.UnitPrice = O.UnitPrice,
	O2.TaxRate = O.TaxRate,
	O2.TotalExcludingTax = O.TotalExcludingTax,
	O2.TaxAmount = O.TaxAmount,
	O2.TotalIncludingTax = O.TotalIncludingTax,
	O2.LoadDate = O.LoadDate
FROM
	#FctOrders O JOIN
	{{ FctOrders }} O2 ON
		O2.WWIOrderID = O.WWIOrderID AND
		O2.WWIOrderLineID = O.WWIOrderLineID
WHERE
	O.[Exists] = 1

-- Insert New
INSERT INTO {{ FctOrders }}
(
	OrderKey,
	CityKey,
	CustomerKey,
	StockItemKey,
	OrderDateKey,
	PickedDateKey,
	SalesPersonKey,
	PickerKey,
	WWIOrderID,
	WWIOrderLineID,
	WWIBackorderID,
	Description,
	Package,
	Quantity,
	UnitPrice,
	TaxRate,
	TotalExcludingTax,
	TaxAmount,
	TotalIncludingTax,
	LoadDate
)
SELECT
	O.OrderKey,
	O.CityKey,
	O.CustomerKey,
	O.StockItemKey,
	O.OrderDateKey,
	O.PickedDateKey,
	O.SalesPersonKey,
	O.PickerKey,
	O.WWIOrderID,
	O.WWIOrderLineID,
	O.WWIBackorderID,
	O.Description,
	O.Package,
	O.Quantity,
	O.UnitPrice,
	O.TaxRate,
	O.TotalExcludingTax,
	O.TaxAmount,
	O.TotalIncludingTax,
	O.LoadDate
FROM
	#FctOrders O
WHERE
	O.[Exists] = 0
ORDER BY
	O.OrderKey

COMMIT TRAN