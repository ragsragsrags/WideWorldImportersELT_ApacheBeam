SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = REPLACE('
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIStockItemID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWIStockItemID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_StockItem] = DSI.[StockItem],
                    [Warehouse_Color] = DSI.[Color],
                    [Warehouse_SellingPackage] = DSI.[SellingPackage],
                    [Warehouse_BuyingPackage] = DSI.[BuyingPackage],
                    [Warehouse_Brand] = DSI.[Brand],
                    [Warehouse_Size] = DSI.[Size],
                    [Warehouse_LeadTimeDays] = DSI.[LeadTimeDays],
                    [Warehouse_QuantityPerOuter] = DSI.[QuantityPerOuter],
                    [Warehouse_IsChillerStock] = DSI.[IsChillerStock],
                    [Warehouse_Barcode] = DSI.[Barcode],
                    [Warehouse_TaxRate] = DSI.[TaxRate],
                    [Warehouse_UnitPrice] = DSI.[UnitPrice],
                    [Warehouse_RecommendedRetailPrice] = DSI.[RecommendedRetailPrice],
                    [Warehouse_TypicalWeightPerUnit] = DSI.[TypicalWeightPerUnit],
                    [Warehouse_Photo] = DSI.[Photo],
                    [Warehouse_LoadDate] = DSI.[LoadDate]
                FROM 
                    [dbo].[DimStockItems] DSI
                WHERE 
                    DSI.[LoadDate] = ''<< NewCutoffDate >>'' AND 
                    DSI.[StockItemKey] != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_StockItem] = SI.StockItemName,
                    [Original_Color] = 
                        CASE 
                            WHEN ColorName IS NOT NULL THEN ColorName
                            ELSE ''N/A''
                        END,
                    [Original_SellingPackage] = SP.PackageTypeName,
                    [Original_BuyingPackage] = BP.PackageTypeName,
                    [Original_Brand] = SI.Brand,
                    [Original_Size] = SI.Size,
                    [Original_LeadTimeDays] = SI.LeadTimeDays,
                    [Original_QuantityPerOuter] = SI.QuantityPerOuter,
                    [Original_IsChillerStock] = SI.IsChillerStock,
                    [Original_Barcode] = SI.Barcode,
                    [Original_TaxRate] = SI.TaxRate,
                    [Original_UnitPrice] = SI.UnitPrice,
                    [Original_RecommendedRetailPrice] = SI.RecommendedRetailPrice,
                    [Original_TypicalWeightPerUnit] = SI.TypicalWeightPerUnit,
                    [Original_Photo] = SI.Photo,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
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
                WD.[Warehouse_WWIStockItemID] = TD.[Original_WWIStockItemID] 
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_StockItem] = TD.[Original_StockItem] OR
                        WD.[Warehouse_Color] = TD.[Original_Color] OR
                        WD.[Warehouse_SellingPackage] = TD.[Original_SellingPackage] OR
                        WD.[Warehouse_BuyingPackage] = TD.[Original_BuyingPackage] OR
                        WD.[Warehouse_Brand] = TD.[Original_Brand] OR
                        WD.[Warehouse_Size] = TD.[Original_Size] OR
                        WD.[Warehouse_LeadTimeDays] = TD.[Original_LeadTimeDays] OR
                        WD.[Warehouse_QuantityPerOuter] = TD.[Original_QuantityPerOuter] OR
                        WD.[Warehouse_IsChillerStock] = TD.[Original_IsChillerStock] OR
                        WD.[Warehouse_Barcode] = TD.[Original_Barcode] OR
                        WD.[Warehouse_TaxRate] = TD.[Original_TaxRate] OR
                        WD.[Warehouse_UnitPrice] = TD.[Original_UnitPrice] OR
                        WD.[Warehouse_RecommendedRetailPrice] = TD.[Original_RecommendedRetailPrice] OR
                        WD.[Warehouse_TypicalWeightPerUnit] = TD.[Original_TypicalWeightPerUnit] OR
                        WD.[Warehouse_Photo] = TD.[Original_Photo] OR
                        WD.[Warehouse_LoadDate] = TD.[Original_LoadDate]
                    ) 
                )
            )
    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIStockItemID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWIStockItemID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_StockItem] = DSI.[StockItem],
                    [Warehouse_Color] = DSI.[Color],
                    [Warehouse_SellingPackage] = DSI.[SellingPackage],
                    [Warehouse_BuyingPackage] = DSI.[BuyingPackage],
                    [Warehouse_Brand] = DSI.[Brand],
                    [Warehouse_Size] = DSI.[Size],
                    [Warehouse_LeadTimeDays] = DSI.[LeadTimeDays],
                    [Warehouse_QuantityPerOuter] = DSI.[QuantityPerOuter],
                    [Warehouse_IsChillerStock] = DSI.[IsChillerStock],
                    [Warehouse_Barcode] = DSI.[Barcode],
                    [Warehouse_TaxRate] = DSI.[TaxRate],
                    [Warehouse_UnitPrice] = DSI.[UnitPrice],
                    [Warehouse_RecommendedRetailPrice] = DSI.[RecommendedRetailPrice],
                    [Warehouse_TypicalWeightPerUnit] = DSI.[TypicalWeightPerUnit],
                    [Warehouse_Photo] = DSI.[Photo],
                    [Warehouse_LoadDate] = DSI.[LoadDate]
                FROM 
                    [dbo].[DimStockItems] DSI
                WHERE 
                    DSI.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DSI.[StockItemKey] != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_StockItem] = SI.StockItemName,
                    [Original_Color] = 
                        CASE 
                            WHEN ColorName IS NOT NULL THEN ColorName
                            ELSE 'N/A'
                        END,
                    [Original_SellingPackage] = SP.PackageTypeName,
                    [Original_BuyingPackage] = BP.PackageTypeName,
                    [Original_Brand] = SI.Brand,
                    [Original_Size] = SI.Size,
                    [Original_LeadTimeDays] = SI.LeadTimeDays,
                    [Original_QuantityPerOuter] = SI.QuantityPerOuter,
                    [Original_IsChillerStock] = SI.IsChillerStock,
                    [Original_Barcode] = SI.Barcode,
                    [Original_TaxRate] = SI.TaxRate,
                    [Original_UnitPrice] = SI.UnitPrice,
                    [Original_RecommendedRetailPrice] = SI.RecommendedRetailPrice,
                    [Original_TypicalWeightPerUnit] = SI.TypicalWeightPerUnit,
                    [Original_Photo] = SI.Photo,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
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
                WD.[Warehouse_WWIStockItemID] = TD.[Original_WWIStockItemID] 
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_StockItem] != TD.[Original_StockItem] OR
                        WD.[Warehouse_Color] != TD.[Original_Color] OR
                        WD.[Warehouse_SellingPackage] != TD.[Original_SellingPackage] OR
                        WD.[Warehouse_BuyingPackage] != TD.[Original_BuyingPackage] OR
                        WD.[Warehouse_Brand] != TD.[Original_Brand] OR
                        WD.[Warehouse_Size] != TD.[Original_Size] OR
                        WD.[Warehouse_LeadTimeDays] != TD.[Original_LeadTimeDays] OR
                        WD.[Warehouse_QuantityPerOuter] != TD.[Original_QuantityPerOuter] OR
                        WD.[Warehouse_IsChillerStock] != TD.[Original_IsChillerStock] OR
                        WD.[Warehouse_Barcode] != TD.[Original_Barcode] OR
                        WD.[Warehouse_TaxRate] != TD.[Original_TaxRate] OR
                        WD.[Warehouse_UnitPrice] != TD.[Original_UnitPrice] OR
                        WD.[Warehouse_RecommendedRetailPrice] != TD.[Original_RecommendedRetailPrice] OR
                        WD.[Warehouse_TypicalWeightPerUnit] != TD.[Original_TypicalWeightPerUnit] OR
                        WD.[Warehouse_Photo] != TD.[Original_Photo] OR
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                    ) 
                )
            )
    ) R