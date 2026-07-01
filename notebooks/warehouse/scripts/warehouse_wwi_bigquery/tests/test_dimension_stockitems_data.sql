SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWIStockItemID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWIStockItemID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    DSI.StockItem AS Warehouse_StockItem,
                    DSI.Color AS Warehouse_Color,
                    DSI.SellingPackage AS Warehouse_SellingPackage,
                    DSI.BuyingPackage AS Warehouse_BuyingPackage,
                    DSI.Brand AS Warehouse_Brand,
                    DSI.Size AS Warehouse_Size,
                    DSI.LeadTimeDays AS Warehouse_LeadTimeDays,
                    DSI.QuantityPerOuter AS Warehouse_QuantityPerOuter,
                    DSI.IsChillerStock AS Warehouse_IsChillerStock,
                    DSI.Barcode AS Warehouse_Barcode,
                    DSI.TaxRate AS Warehouse_TaxRate,
                    DSI.UnitPrice AS Warehouse_UnitPrice,
                    DSI.RecommendedRetailPrice AS Warehouse_RecommendedRetailPrice,
                    DSI.TypicalWeightPerUnit AS Warehouse_TypicalWeightPerUnit,
                    DSI.Photo AS Warehouse_Photo,
                    DSI.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimStockItems }} DSI
                WHERE 
                    DSI.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DSI.StockItemKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    SI.StockItemID AS Original_WWIStockItemID,
                    SI.StockItemName AS Original_StockItem,
                    CASE 
                        WHEN ColorName IS NOT NULL THEN ColorName
                        ELSE 'N/A'
                    END AS Original_Color,
                    SP.PackageTypeName AS Original_SellingPackage,
                    BP.PackageTypeName AS Original_BuyingPackage,
                    SI.Brand AS Original_Brand,
                    SI.Size AS Original_Size,
                    SI.LeadTimeDays AS Original_LeadTimeDays,
                    SI.QuantityPerOuter AS Original_QuantityPerOuter,
                    SI.IsChillerStock AS Original_IsChillerStock,
                    SI.Barcode AS Original_Barcode,
                    SI.TaxRate AS Original_TaxRate,
                    SI.UnitPrice AS Original_UnitPrice,
                    SI.RecommendedRetailPrice AS Original_RecommendedRetailPrice,
                    SI.TypicalWeightPerUnit AS Original_TypicalWeightPerUnit,
                    SI.Photo AS Original_Photo,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName,
                            SI.ColorID,
                            SI.OuterPackageID,
                            SI.UnitPackageID,
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
                            SI.ValidFrom,
                            SI.ValidTo
                        FROM
                            {{ WarehouseStockItems }} SI
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName,
                            SIA.ColorID,
                            SIA.OuterPackageID,
                            SIA.UnitPackageID,
                            SIA.Brand,
                            SIA.Size,
                            SIA.LeadTimeDays,
                            SIA.QuantityPerOuter,
                            SIA.IsChillerStock,
                            SIA.Barcode,
                            SIA.TaxRate,
                            SIA.UnitPrice,
                            SIA.RecommendedRetailPrice,
                            SIA.TypicalWeightPerUnit,
                            SIA.Photo,
                            SIA.ValidFrom,
                            SIA.ValidTo
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI LEFT JOIN
                    (
                        SELECT
                            C.ColorID,
                            C.ColorName
                        FROM
                            {{ WarehouseColors }} C
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.ColorID,
                            CA.ColorName
                        FROM
                            {{ WarehouseColorsArchive }} CA 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON
                        C.ColorID = SI.ColorID LEFT JOIN
                    (
                        SELECT
                            PT.PackageTypeID,
                            PT.PackageTypeName
                        FROM
                            {{ WarehousePackageTypes }} AS PT 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PT.ValidFrom AND PT.ValidTo

                        UNION ALL

                        SELECT
                            PTA.PackageTypeID,
                            PTA.PackageTypeName
                        FROM
                            {{ WarehousePackageTypesArchive }} AS PTA 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom AND PTA.ValidTo
                    ) SP ON
                        SP.PackageTypeID = SI.UnitPackageID LEFT JOIN
                    (
                        SELECT
                            PT.PackageTypeID,
                            PT.PackageTypeName
                        FROM
                            {{ WarehousePackageTypes }} PT 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PT.ValidFrom AND PT.ValidTo

                        UNION ALL

                        SELECT
                            PTA.PackageTypeID,
                            PTA.PackageTypeName
                        FROM
                            {{ WarehousePackageTypesArchive }} AS PTA 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom AND PTA.ValidTo
                    ) BP ON
                        BP.PackageTypeID = SI.OuterPackageID
                WHERE
                    (
			            SI.ValidFrom > ''<< LastCutoffDate >>'' OR
			            SI.UnitPackageID IN
			            (
                            SELECT
		                        PT.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypes }} PT
	                        WHERE
		                        PT.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PT.ValidFrom AND PT.ValidTo 

	                        UNION ALL

	                        SELECT
		                        PTA.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypesArchive }} PTA
	                        WHERE
		                        PTA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom AND PTA.ValidTo
			            ) OR
			            SI.OuterPackageID IN
			            (
				            SELECT
		                        PT.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypes }} PT
	                        WHERE
		                        PT.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PT.ValidFrom AND PT.ValidTo 

	                        UNION ALL

	                        SELECT
		                        PTA.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypesArchive }} PTA
	                        WHERE
		                        PTA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom AND PTA.ValidTo
			            ) OR
			            SI.ColorID IN 
			            (
				            SELECT
		                        C.ColorID
	                        FROM
		                        {{ WarehouseColors }} C
	                        WHERE
		                        C.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo 

	                        UNION ALL

	                        SELECT
		                        CA.ColorID
	                        FROM
		                        {{ WarehouseColorsArchive }} CA
	                        WHERE
		                        CA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
			            )
		            ) AND
		            ''<< NewCutoffDate >>'' BETWEEN SI.ValidFrom AND SI.ValidTo
            ) TD ON 
                WD.Warehouse_WWIStockItemID = TD.Original_WWIStockItemID 
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_StockItem != TD.Original_StockItem OR
                        WD.Warehouse_Color != TD.Original_Color OR
                        WD.Warehouse_SellingPackage != TD.Original_SellingPackage OR
                        WD.Warehouse_BuyingPackage != TD.Original_BuyingPackage OR
                        WD.Warehouse_Brand != TD.Original_Brand OR
                        WD.Warehouse_Size != TD.Original_Size OR
                        WD.Warehouse_LeadTimeDays != TD.Original_LeadTimeDays OR
                        WD.Warehouse_QuantityPerOuter != TD.Original_QuantityPerOuter OR
                        WD.Warehouse_IsChillerStock != TD.Original_IsChillerStock OR
                        WD.Warehouse_Barcode != TD.Original_Barcode OR
                        WD.Warehouse_TaxRate != TD.Original_TaxRate OR
                        WD.Warehouse_UnitPrice != TD.Original_UnitPrice OR
                        WD.Warehouse_RecommendedRetailPrice != TD.Original_RecommendedRetailPrice OR
                        WD.Warehouse_TypicalWeightPerUnit != TD.Original_TypicalWeightPerUnit OR
                        WD.Warehouse_Photo != TD.Original_Photo OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate
                    ) 
                )
            )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWIStockItemID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWIStockItemID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    DSI.StockItem AS Warehouse_StockItem,
                    DSI.Color AS Warehouse_Color,
                    DSI.SellingPackage AS Warehouse_SellingPackage,
                    DSI.BuyingPackage AS Warehouse_BuyingPackage,
                    DSI.Brand AS Warehouse_Brand,
                    DSI.Size AS Warehouse_Size,
                    DSI.LeadTimeDays AS Warehouse_LeadTimeDays,
                    DSI.QuantityPerOuter AS Warehouse_QuantityPerOuter,
                    DSI.IsChillerStock AS Warehouse_IsChillerStock,
                    DSI.Barcode AS Warehouse_Barcode,
                    DSI.TaxRate AS Warehouse_TaxRate,
                    DSI.UnitPrice AS Warehouse_UnitPrice,
                    DSI.RecommendedRetailPrice AS Warehouse_RecommendedRetailPrice,
                    DSI.TypicalWeightPerUnit AS Warehouse_TypicalWeightPerUnit,
                    DSI.Photo AS Warehouse_Photo,
                    DSI.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimStockItems }} DSI
                WHERE 
                    DSI.LoadDate = '<< NewCutoffDate >>' AND 
                    DSI.StockItemKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    SI.StockItemID AS Original_WWIStockItemID,
                    SI.StockItemName AS Original_StockItem,
                    CASE 
                        WHEN ColorName IS NOT NULL THEN ColorName
                        ELSE 'N/A'
                    END AS Original_Color,
                    SP.PackageTypeName AS Original_SellingPackage,
                    BP.PackageTypeName AS Original_BuyingPackage,
                    SI.Brand AS Original_Brand,
                    SI.Size AS Original_Size,
                    SI.LeadTimeDays AS Original_LeadTimeDays,
                    SI.QuantityPerOuter AS Original_QuantityPerOuter,
                    SI.IsChillerStock AS Original_IsChillerStock,
                    SI.Barcode AS Original_Barcode,
                    SI.TaxRate AS Original_TaxRate,
                    SI.UnitPrice AS Original_UnitPrice,
                    SI.RecommendedRetailPrice AS Original_RecommendedRetailPrice,
                    SI.TypicalWeightPerUnit AS Original_TypicalWeightPerUnit,
                    SI.Photo AS Original_Photo,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName,
                            SI.ColorID,
                            SI.OuterPackageID,
                            SI.UnitPackageID,
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
                            SI.ValidFrom,
                            SI.ValidTo
                        FROM
                            {{ WarehouseStockItems }} SI
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName,
                            SIA.ColorID,
                            SIA.OuterPackageID,
                            SIA.UnitPackageID,
                            SIA.Brand,
                            SIA.Size,
                            SIA.LeadTimeDays,
                            SIA.QuantityPerOuter,
                            SIA.IsChillerStock,
                            SIA.Barcode,
                            SIA.TaxRate,
                            SIA.UnitPrice,
                            SIA.RecommendedRetailPrice,
                            SIA.TypicalWeightPerUnit,
                            SIA.Photo,
                            SIA.ValidFrom,
                            SIA.ValidTo
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI LEFT JOIN
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
                    ) C ON
                        C.ColorID = SI.ColorID LEFT JOIN
                    (
                        SELECT
                            PT.PackageTypeID,
                            PT.PackageTypeName
                        FROM
                            {{ WarehousePackageTypes }} AS PT 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PT.ValidFrom AND PT.ValidTo

                        UNION ALL

                        SELECT
                            PTA.PackageTypeID,
                            PTA.PackageTypeName
                        FROM
                            {{ WarehousePackageTypesArchive }} AS PTA 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo
                    ) SP ON
                        SP.PackageTypeID = SI.UnitPackageID LEFT JOIN
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
                            {{ WarehousePackageTypesArchive }} AS PTA 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo
                    ) BP ON
                        BP.PackageTypeID = SI.OuterPackageID
                WHERE
                    (
			            SI.ValidFrom > '<< LastCutoffDate >>' OR
			            SI.UnitPackageID IN
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
			            ) OR
			            SI.OuterPackageID IN
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
			            ) OR
			            SI.ColorID IN 
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
			            )
		            ) AND
		            '<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo
            ) TD ON 
                WD.Warehouse_WWIStockItemID = TD.Original_WWIStockItemID 
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_StockItem != TD.Original_StockItem OR
                        WD.Warehouse_Color != TD.Original_Color OR
                        WD.Warehouse_SellingPackage != TD.Original_SellingPackage OR
                        WD.Warehouse_BuyingPackage != TD.Original_BuyingPackage OR
                        WD.Warehouse_Brand != TD.Original_Brand OR
                        WD.Warehouse_Size != TD.Original_Size OR
                        WD.Warehouse_LeadTimeDays != TD.Original_LeadTimeDays OR
                        WD.Warehouse_QuantityPerOuter != TD.Original_QuantityPerOuter OR
                        WD.Warehouse_IsChillerStock != TD.Original_IsChillerStock OR
                        WD.Warehouse_Barcode != TD.Original_Barcode OR
                        WD.Warehouse_TaxRate != TD.Original_TaxRate OR
                        WD.Warehouse_UnitPrice != TD.Original_UnitPrice OR
                        WD.Warehouse_RecommendedRetailPrice != TD.Original_RecommendedRetailPrice OR
                        WD.Warehouse_TypicalWeightPerUnit != TD.Original_TypicalWeightPerUnit OR
                        WD.Warehouse_Photo != TD.Original_Photo OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate
                    ) 
                )
            )
    ) R