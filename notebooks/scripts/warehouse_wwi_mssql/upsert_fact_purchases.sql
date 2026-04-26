DECLARE @MaxPurchaseKey INT 
    
SELECT
    @MaxPurchaseKey = ISNULL(MAX(PurchaseKey), 0)
FROM
    {{ FctPurchases }}

IF OBJECT_ID('tempdb..#FctPurchases') IS NOT NULL
    DROP TABLE #FctPurchases

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

stockItemsChanged AS 
(

	SELECT
		SI.StockItemID
	FROM
		{{ WarehouseStockItems }} SI
	WHERE
		SI.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN SI.ValidFrom  AND SI.ValidTo

	UNION ALL

	SELECT
		SIA.StockItemID
	FROM
		{{ WarehouseStockItemsArchive }} SIA
	WHERE
		SIA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN SIA.ValidFrom  AND SIA.ValidTo

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
		[PurchaseKey] = 
			CASE
				WHEN FP.PurchaseKey IS NULL THEN @MaxPurchaseKey + (ROW_NUMBER() OVER (ORDER BY FP.PurchaseKey, PO.PurchaseOrderID, POL.PurchaseOrderLineID))
				ELSE FP.PurchaseKey
			END,
		[DateKey] = CAST(PO.OrderDate AS DATE),
		[SupplierKey] = ISNULL(S.SupplierKey, 0),
		[StockItemKey] = ISNULL(SI.StockItemKey, 0),
		[WWIPurchaseOrderID] = PO.PurchaseOrderID,
		[WWIPurchaseOrderLineID] = POL.PurchaseOrderLineID,
		[OrderedOuters] = POL.OrderedOuters,
		[OrderedQuantity] = POL.OrderedOuters * SI.QuantityPerOuter,
		[ReceivedOuters] = POL.ReceivedOuters,
		[Package] = PTA.PackageTypeName,
		[IsOrderFinalized] = POL.IsOrderLineFinalized,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN FP.PurchaseKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM 
		{{ PurchasingPurchaseOrders }} PO JOIN 
		{{ PurchasingPurchaseOrderLines }} AS POL ON 
			PO.PurchaseOrderID = POL.PurchaseOrderID LEFT JOIN 
		{{ DimSuppliers }} S ON
			S.WWISupplierID = PO.SupplierID LEFT JOIN
		{{ DimStockItems }} SI ON
			SI.WWIStockItemID = POL.StockItemID LEFT JOIN
		packageTypesAvailable AS PTA ON 
			PTA.PackageTypeID = POL.PackageTypeID LEFT JOIN
		{{ FctPurchases }} FP ON
			FP.WWIPurchaseOrderID = PO.PurchaseOrderID AND
			FP.WWIPurchaseOrderLineID = POL.PurchaseOrderLineID
	WHERE 
		(
			PO.LastEditedWhen > '<< LastCutoffDate >>' OR
			POL.LastEditedWhen > '<< LastCutoffDate >>' OR
			POL.PackageTypeID IN 
			(
				SELECT 
					PTC.PackageTypeID 
				FROM 
					packageTypesChanged PTC
			) OR
			POL.StockItemID IN 
			(
				SELECT 
					SIC.StockItemID
				FROM 
					stockItemsChanged SIC
			)
		) AND
		PO.LastEditedWhen <= '<< NewCutoffDate >>' AND
		POL.LastEditedWhen <= '<< NewCutoffDate >>'

)

SELECT 
	*
INTO
	#FctPurchases
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	P2
SET
	P2.DateKey = P.DateKey,
	P2.SupplierKey = P.SupplierKey,
	P2.StockItemKey = P.StockItemKey,
	P2.OrderedOuters = P.OrderedOuters,
	P2.OrderedQuantity = P.OrderedQuantity,
	P2.ReceivedOuters = P.ReceivedOuters,
	P2.Package = P.Package,
	P2.IsOrderFinalized = P.IsOrderFinalized,
	P2.LoadDate = P.LoadDate
FROM
	#FctPurchases P JOIN
	{{ FctPurchases }} P2 ON
		P2.WWIPurchaseOrderID = P.WWIPurchaseOrderID AND
		P2.WWIPurchaseOrderLineID = P.WWIPurchaseOrderLineID
WHERE
	P.[Exists] = 1

-- Insert New
INSERT INTO {{ FctPurchases }}
(
    PurchaseKey,
	DateKey,
	SupplierKey,
	StockItemKey,
	WWIPurchaseOrderID,
	WWIPurchaseOrderLineID,
	OrderedOuters,
	OrderedQuantity,
	ReceivedOuters,
	Package,
	IsOrderFinalized,
	LoadDate
)
SELECT
    P.PurchaseKey,
	P.DateKey,
	P.SupplierKey,
	P.StockItemKey,
	P.WWIPurchaseOrderID,
	P.WWIPurchaseOrderLineID,
	P.OrderedOuters,
	P.OrderedQuantity,
	P.ReceivedOuters,
	P.Package,
	P.IsOrderFinalized,
	P.LoadDate
FROM
	#FctPurchases P 
WHERE
	P.[Exists] = 0
ORDER BY
	P.PurchaseKey

COMMIT TRAN