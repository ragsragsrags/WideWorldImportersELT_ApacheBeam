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
                    [Warehouse_QuantityOnHand] = FSH.[QuantityOnHand],
                    [Warehouse_BinLocation] = FSH.[BinLocation],
                    [Warehouse_LastStocktakeQuantity] = FSH.[LastStocktakeQuantity],
                    [Warehouse_LastCostPrice] = FSH.[LastCostPrice],
                    [Warehouse_ReorderLevel] = FSH.[ReorderLevel],
                    [Warehouse_TargetStockLevel] = FSH.[TargetStockLevel],
                    [Warehouse_LoadDate] = FSH.[LoadDate]
                FROM 
                    {{ FctStockHoldings }} FSH LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FSH.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FSH.[LoadDate] = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_QuantityOnHand] = SIH.QuantityOnHand,
                    [Original_BinLocation] = SIH.BinLocation,
                    [Original_LastStocktakeQuantity] = SIH.LastStocktakeQuantity,
                    [Original_LastCostPrice] = SIH.LastCostPrice,
                    [Original_ReorderLevel] = SIH.ReorderLevel,
                    [Original_TargetStockLevel] = SIH.TargetStockLevel,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    {{ WarehouseStockItemHoldings }} SIH JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName
                        FROM
                            {{ WarehouseStockItems }} SI
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = SIH.StockItemID
                WHERE 
		            SIH.LastEditedWhen > ''<< LastCutoffDate >>'' AND
		            SIH.LastEditedWhen <= ''<< NewCutoffDate >>''
            ) TD ON 
                WD.[Warehouse_WWIStockItemID] = TD.[Original_WWIStockItemID]
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                (
                    WD.[Warehouse_QuantityOnHand] != TD.[Original_QuantityOnHand] OR
                    WD.[Warehouse_BinLocation] != TD.[Original_BinLocation] OR
                    WD.[Warehouse_LastStocktakeQuantity] != TD.[Original_LastStocktakeQuantity] OR
                    WD.[Warehouse_LastCostPrice] != TD.[Original_LastCostPrice] OR
                    WD.[Warehouse_ReorderLevel] != TD.[Original_ReorderLevel] OR
                    WD.[Warehouse_TargetStockLevel] != TD.[Original_TargetStockLevel] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
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
                    [Warehouse_QuantityOnHand] = FSH.[QuantityOnHand],
                    [Warehouse_BinLocation] = FSH.[BinLocation],
                    [Warehouse_LastStocktakeQuantity] = FSH.[LastStocktakeQuantity],
                    [Warehouse_LastCostPrice] = FSH.[LastCostPrice],
                    [Warehouse_ReorderLevel] = FSH.[ReorderLevel],
                    [Warehouse_TargetStockLevel] = FSH.[TargetStockLevel],
                    [Warehouse_LoadDate] = FSH.[LoadDate]
                FROM 
                    {{ FctStockHoldings }} FSH LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FSH.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FSH.[LoadDate] = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_QuantityOnHand] = SIH.QuantityOnHand,
                    [Original_BinLocation] = SIH.BinLocation,
                    [Original_LastStocktakeQuantity] = SIH.LastStocktakeQuantity,
                    [Original_LastCostPrice] = SIH.LastCostPrice,
                    [Original_ReorderLevel] = SIH.ReorderLevel,
                    [Original_TargetStockLevel] = SIH.TargetStockLevel,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    {{ WarehouseStockItemHoldings }} SIH JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName
                        FROM
                            {{ WarehouseStockItems }} SI
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = SIH.StockItemID
                WHERE 
		            SIH.LastEditedWhen > '<< LastCutoffDate >>' AND
		            SIH.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                WD.[Warehouse_WWIStockItemID] = TD.[Original_WWIStockItemID]
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                (
                    WD.[Warehouse_QuantityOnHand] != TD.[Original_QuantityOnHand] OR
                    WD.[Warehouse_BinLocation] != TD.[Original_BinLocation] OR
                    WD.[Warehouse_LastStocktakeQuantity] != TD.[Original_LastStocktakeQuantity] OR
                    WD.[Warehouse_LastCostPrice] != TD.[Original_LastCostPrice] OR
                    WD.[Warehouse_ReorderLevel] != TD.[Original_ReorderLevel] OR
                    WD.[Warehouse_TargetStockLevel] != TD.[Original_TargetStockLevel] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                )
            )
    ) R