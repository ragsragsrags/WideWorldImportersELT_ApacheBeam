DECLARE MaxStockItemKey INT64;

SET MaxStockItemKey = 
(
    SELECT
        IFNULL(MAX(StockItemKey), 0)
    FROM
        {{ DimStockItems }}
);

CREATE TEMP TABLE TempDimStockItems AS
WITH packageTypesChanged AS 
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

	UNION ALL

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

	UNION ALL

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
		'<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo 

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
		CASE
			WHEN SI.StockItemKey IS NULL THEN CAST(MaxStockItemKey AS INTEGER) + (ROW_NUMBER() OVER(ORDER BY SI.StockItemKey, SI.StockItemID))
			ELSE SI.StockItemKey
		END AS StockItemKey,
		SI.StockItemID AS WWIStockItemID,
		SI.StockItemName AS StockItem,
		CASE 
			WHEN CA.ColorName IS NOT NULL THEN CA.ColorName
			ELSE 'N/A'
		END AS Color,
		PTA.PackageTypeName AS SellingPackage,
		BPTA.PackageTypeName AS BuyingPackage,
		IFNULL(SI.Brand, '') AS Brand,
		IFNULL(SI.Size, '') AS Size,
		SI.LeadTimeDays AS LeadTimeDays,
		SI.QuantityPerOuter AS QuantityPerOuter,
		SI.IsChillerStock AS IsChillerStock,
		SI.Barcode AS Barcode,
		SI.TaxRate AS TaxRate,
		SI.UnitPrice AS UnitPrice,
		SI.RecommendedRetailPrice AS RecommendedRetailPrice,
		SI.TypicalWeightPerUnit AS TypicalWeightPerUnit,
		SI.Photo AS Photo,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate, 
		CASE
			WHEN SI.StockItemKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
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
		0 AS StockItemKey,
		0 AS WWIStockItemID,
		'Unknown' AS StockItem,
		'N/A' AS Color,
		'N/A' AS SellingPackage,
		'N/A' AS BuyingPackage,
		'N/A' AS Brand,
		'N/A' AS Size,
		0 AS LeadTimeDays,
		0 AS QuantityPerOuter,
		FALSE AS IsChillerStock,
		'N/A' AS Barcode,
		0.00 AS TaxRate,
		0.00 AS UnitPrice,
		0.00 AS RecommendedRetailPrice,
		0.00 AS TypicalWeightPerUnit,
		NULL AS Photo,
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
				{{ DimStockItems }}
			WHERE
				StockItemKey = 0
		)
	
)

SELECT 
	*
FROM
	final;

-- Update Existing
UPDATE
	{{ DimStockItems }} SI2
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
	SI2.LoadDate = SI.LoadDate,
	SI2.LastLoadDate = SI2.LoadDate
FROM
	TempDimStockItems SI 
WHERE
	SI.Exist = TRUE AND
	SI2.WWIStockItemID = SI.WWIStockItemID;

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
	LoadDate,
	LastLoadDate
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
	SI.LoadDate,
	CAST(NULL AS DATETIME)
FROM
	TempDimStockItems SI 
WHERE
	SI.Exist = FALSE
ORDER BY
	SI.StockItemKey;