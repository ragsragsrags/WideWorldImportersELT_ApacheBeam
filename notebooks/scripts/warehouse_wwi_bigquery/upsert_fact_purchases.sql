DECLARE MaxPurchaseKey INT64;

SET MaxPurchaseKey = 
(
    SELECT
        IFNULL(MAX(PurchaseKey), 0)
    FROM
        {{ FctPurchases }}
);

CREATE TEMP TABLE TempFctPurchases AS
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
			WHEN FP.PurchaseKey IS NULL THEN CAST(MaxPurchaseKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY FP.PurchaseKey, PO.PurchaseOrderID, POL.PurchaseOrderLineID))
			ELSE FP.PurchaseKey
		END PurchaseKey,
		CAST(PO.OrderDate AS DATE) AS DateKey,
		IFNULL(S.SupplierKey, 0) AS SupplierKey,
		IFNULL(SI.StockItemKey, 0) AS StockItemKey,
		PO.PurchaseOrderID AS WWIPurchaseOrderID,
		POL.PurchaseOrderLineID AS WWIPurchaseOrderLineID,
		POL.OrderedOuters AS OrderedOuters,
		(POL.OrderedOuters * SI.QuantityPerOuter) OrderedQuantity,
		POL.ReceivedOuters AS ReceivedOuters,
		PTA.PackageTypeName AS Package,
		POL.IsOrderLineFinalized AS IsOrderFinalized,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate, 
		CASE
			WHEN FP.PurchaseKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
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
FROM
	final;

-- Update Existing
UPDATE
	{{ FctPurchases }} P2
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
	TempFctPurchases P 
WHERE
	P.Exist = TRUE AND
	P2.WWIPurchaseOrderID = P.WWIPurchaseOrderID AND
	P2.WWIPurchaseOrderLineID = P.WWIPurchaseOrderLineID;

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
	TempFctPurchases P 
WHERE
	P.Exist = FALSE
ORDER BY
	P.PurchaseKey;