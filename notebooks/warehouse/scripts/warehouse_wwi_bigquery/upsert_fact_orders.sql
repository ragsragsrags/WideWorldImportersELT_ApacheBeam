DECLARE MaxOrderKey INT64;

SET MaxOrderKey = 
(
    SELECT
        IFNULL(MAX(OrderKey), 0)
    FROM
        {{ FctOrders }}
);

CREATE TEMP TABLE TempFctOrders AS
WITH packageTypesChanged AS 
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

	UNION ALL

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
		CASE
			WHEN FO.OrderKey IS NULL THEN CAST(MaxOrderKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY FO.OrderKey, O.OrderID, OL.OrderLineID))
			ELSE FO.OrderKey
		END AS OrderKey,
		IFNULL(CT.CityKey, 0) AS CityKey,
		IFNULL(C.CustomerKey, 0) AS CustomerKey,
		IFNULL(SI.StockItemKey, 0) AS StockItemKey,
		CAST(O.OrderDate AS DATE) AS OrderDateKey,
		CAST(O.PickingCompletedWhen AS DATE) AS PickedDateKey,
		IFNULL(E.EmployeeKey, 0) AS SalesPersonKey,
		IFNULL(E2.EmployeeKey, 0) AS PickerKey,
		O.OrderID AS WWIOrderID,
		OL.OrderLineID AS WWIOrderLineID,
		O.BackorderOrderID AS WWIBackorderID,
		OL.Description AS Description,
		PTA.PackageTypeName AS Package,
		OL.Quantity AS Quantity,
		OL.UnitPrice AS UnitPrice,
		OL.TaxRate AS TaxRate,
		ROUND(OL.Quantity * OL.UnitPrice, 2) AS TotalExcludingTax,
		ROUND((OL.Quantity * OL.UnitPrice * OL.TaxRate) / 100.0, 2) AS TaxAmount,
		(
			ROUND(OL.Quantity * OL.UnitPrice, 2) + 
			ROUND((OL.Quantity * OL.UnitPrice * OL.TaxRate) / 100.0, 2)
		) AS TotalIncludingTax,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate, 
		CASE
			WHEN FO.OrderKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
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
FROM
	final;

-- Update Existing
UPDATE
	{{ FctOrders }} O2
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
	O2.LoadDate = O.LoadDate,
	O2.LastLoadDate = O2.LoadDate
FROM
	TempFctOrders O 
WHERE
	O.Exist = TRUE AND
	O2.WWIOrderID = O.WWIOrderID AND
	O2.WWIOrderLineID = O.WWIOrderLineID;

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
	LoadDate,
	LastLoadDate
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
	O.LoadDate,
	CAST(NULL AS DATETIME)
FROM
	TempFctOrders O
WHERE
	O.Exist = FALSE
ORDER BY
	O.OrderKey;