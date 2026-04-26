DECLARE @MaxStockItemKey INT 
    
SELECT
    @MaxStockItemKey = ISNULL(MAX(StockItemKey), 0)
FROM
    {{ DimStockItems }}

IF OBJECT_ID('tempdb..#DimStockItems') IS NOT NULL
    DROP TABLE #DimStockItems

;WITH packageTypesChanged AS 
(

	SELECT
		PT.PackageTypeID
	FROM
		{{ WarehousePackageTypes }} PT
	WHERE
		PT.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PT.ValidFrom AND PT.ValidTo 

	UNION ALL

	SELECT
		PTA.PackageTypeID
	FROM
		{{ WarehousePackageTypesArchive }} PTA
	WHERE
		PTA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo 

),

colorsChanged AS 
(

	SELECT
		C.ColorID
	FROM
		{{ WarehouseColors }} C
	WHERE
		C.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo 

	UNION ALL

	SELECT
		CA.ColorID
	FROM
		{{ WarehouseColorsArchive }} CA
	WHERE
		CA.ValidFrom > '<< LastCutoffDate >>' AND
		'<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo 

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

colorsAvailable AS 
(

	SELECT
		C.ColorID,
		C.ColorName
	FROM
		{{ WarehouseColors }} C
	WHERE
		'<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

	UNION

	SELECT
		CA.ColorID,
		CA.ColorName
	FROM
		{{ WarehouseColorsArchive }} CA
	WHERE
		'<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo

),

mergedStockItems AS 
(

	SELECT
		DSI.StockItemKey,
		SI.StockItemID,
		SI.StockItemName,
		SI.Brand,
		SI.Size,
		SI.LeadTimeDays,
		SI.QuantityPerOuter,
		SI.IsChillerStock,
		SI.Barcode,
		SI.TaxRate,
		SI.UnitPrice,
		SI.RecommendedRetailPrice,
		SI.TypicalWeightPerUnit,
		SI.Photo,
		SI.UnitPackageID,
		SI.OuterPackageID,
		SI.ColorID
	FROM
		{{ WarehouseStockItems }} SI LEFT JOIN
		{{ DimStockItems }} DSI ON
			DSI.WWIStockItemID = SI.StockItemID
	WHERE
		(
			SI.ValidFrom > '<< LastCutoffDate >>' OR
			SI.UnitPackageID IN
			(
				SELECT
					PTC.PackageTypeID
				FROM
					PackageTypesChanged PTC
			) OR
			SI.OuterPackageID IN
			(
				SELECT
					PTC.PackageTypeID
				FROM
					PackageTypesChanged PTC
			) OR
			SI.ColorID IN 
			(
				SELECT
					CC.ColorID
				FROM
					ColorsChanged CC
			)
		) AND
		' << NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo 

	UNION ALL

	SELECT
		DSI.StockItemKey,
		SI.StockItemID,
		SI.StockItemName, 
		SI.Brand,
		SI.Size,
		SI.LeadTimeDays,
		SI.QuantityPerOuter,
		SI.IsChillerStock,
		SI.Barcode,
		SI.TaxRate,
		SI.UnitPrice,
		SI.RecommendedRetailPrice,
		SI.TypicalWeightPerUnit,
		SI.Photo,
		SI.UnitPackageID,
		SI.OuterPackageID,
		SI.ColorID
	FROM
		{{ WarehouseStockItemsArchive }} SI LEFT JOIN
		{{ DimStockItems }} DSI ON
			DSI.WWIStockItemID = SI.StockItemID 
	WHERE
		(
			SI.ValidFrom > '<< LastCutoffDate >>' OR
			SI.UnitPackageID IN
			(
				SELECT
					PTC.PackageTypeID
				FROM
					PackageTypesChanged PTC
			) OR
			SI.OuterPackageID IN
			(
				SELECT
					PTC.PackageTypeID
				FROM
					PackageTypesChanged PTC
			) OR
			SI.ColorID IN 
			(
				SELECT
					CC.ColorID
				FROM
					ColorsChanged CC
			)
		) AND
		'<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo

),

final AS (

	SELECT
		[StockItemKey] = 
			CASE
				WHEN SI.StockItemKey IS NULL THEN @MaxStockItemKey + (ROW_NUMBER() OVER(ORDER BY SI.StockItemKey, SI.StockItemID))
				ELSE SI.StockItemKey
			END,
		[WWIStockItemID] = SI.StockItemID,
		[StockItem] = SI.StockItemName,
		[Color] = 
			CASE 
				WHEN CA.ColorName IS NOT NULL THEN CA.ColorName
				ELSE 'N/A'
			END,
		[SellingPackage] = PTA.PackageTypeName,
		[BuyingPackage] = BPTA.PackageTypeName,
		[Brand] = ISNULL(SI.Brand, ''),
		[Size] = ISNULL(SI.Size, ''),
		SI.LeadTimeDays,
		SI.QuantityPerOuter,
		SI.IsChillerStock,
		SI.Barcode,
		SI.TaxRate,
		SI.UnitPrice,
		SI.RecommendedRetailPrice,
		SI.TypicalWeightPerUnit,
		SI.Photo,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN SI.StockItemKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM
		mergedStockItems SI LEFT JOIN
		packageTypesAvailable PTA ON
			SI.UnitPackageID = PTA.PackageTypeID LEFT JOIN
		packageTypesAvailable AS BPTA ON
			SI.OuterPackageID = BPTA.PackageTypeID LEFT JOIN
		colorsAvailable CA ON
			SI.ColorID = CA.ColorID 

	UNION ALL

	SELECT
		[StockItemKey] = 0,
		[WWIStockItemID] = 0,
		[StockItem] = 'Unknown',
		[Color] = 'N/A',
		[SellingPackage] = 'N/A',
		[BuyingPackage] = 'N/A',
		[Brand] = 'N/A',
		[Size] = 'N/A',
		[LeadTimeDays] = 0,
		[QuantityPerOuter] = 0,
		[IsChillerStock] = 0,
		[Barcode] = 'N/A',
		[TaxRate] = 0.00,
		[UnitPrice] = 0.00,
		[RecommendedRetailPrice] = 0.00,
		[TypicalWeightPerUnit] = 0.00,
		[Photo] = NULL,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = CAST(0 AS BIT)
	WHERE
		NOT EXISTS
		(
			SELECT
				1
			FROM
				{{ DimStockItems }}
			WHERE
				StockItemKey = 0
		)
	
)

SELECT 
	*
INTO
	#DimStockItems
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	SI2
SET
	SI2.StockItem = SI.StockItem,
	SI2.Color = SI.Color,
	SI2.SellingPackage = SI.SellingPackage,
	SI2.BuyingPackage = SI.BuyingPackage,
	SI2.Brand = SI.Brand,
	SI2.Size = SI.Size,
	SI2.LeadTimeDays = SI.LeadTimeDays,
	SI2.QuantityPerOuter = SI.QuantityPerOuter,
	SI2.IsChillerStock = SI.IsChillerStock,
	SI2.Barcode = SI.Barcode,
	SI2.TaxRate = SI.TaxRate,
	SI2.UnitPrice = SI.UnitPrice,
	SI2.RecommendedRetailPrice = SI.RecommendedRetailPrice,
	SI2.TypicalWeightPerUnit = SI.TypicalWeightPerUnit,
	SI2.Photo = SI.Photo,
	SI2.LoadDate = SI.LoadDate
FROM
	#DimStockItems SI JOIN
	{{ DimStockItems }} SI2 ON
		SI2.WWIStockItemID = SI.WWIStockItemID
WHERE
	SI.[Exists] = 1

-- Insert New
INSERT INTO {{ DimStockItems }}
(
	StockItemKey,
	WWIStockItemID,
	StockItem,
	Color,
	SellingPackage,
	BuyingPackage,
	Brand,
	Size,
	LeadTimeDays,
	QuantityPerOuter,
	IsChillerStock,
	Barcode,
	TaxRate,
	UnitPrice,
	RecommendedRetailPrice,
	TypicalWeightPerUnit,
	Photo,
	LoadDate
)
SELECT
	SI.StockItemKey,
	SI.WWIStockItemID,
	SI.StockItem,
	SI.Color,
	SI.SellingPackage,
	SI.BuyingPackage,
	SI.Brand,
	SI.Size,
	SI.LeadTimeDays,
	SI.QuantityPerOuter,
	SI.IsChillerStock,
	SI.Barcode,
	SI.TaxRate,
	SI.UnitPrice,
	SI.RecommendedRetailPrice,
	SI.TypicalWeightPerUnit,
	SI.Photo,
	SI.LoadDate
FROM
	#DimStockItems SI 
WHERE
	SI.[Exists] = 0
ORDER BY
	SI.StockItemKey

COMMIT TRAN