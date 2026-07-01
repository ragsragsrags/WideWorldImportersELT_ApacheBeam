SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE(REPLACE('''
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
                    FSH.QuantityOnHand AS Warehouse_QuantityOnHand,
                    FSH.BinLocation AS Warehouse_BinLocation,
                    FSH.LastStocktakeQuantity AS Warehouse_LastStocktakeQuantity,
                    FSH.LastCostPrice AS Warehouse_LastCostPrice,
                    FSH.ReorderLevel AS Warehouse_ReorderLevel,
                    FSH.TargetStockLevel AS Warehouse_TargetStockLevel,
                    FSH.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctStockHoldings }} FSH LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FSH.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FSH.LoadDate = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    SI.StockItemID AS Original_WWIStockItemID,
                    SIH.QuantityOnHand AS Original_QuantityOnHand,
                    SIH.BinLocation AS Original_BinLocation,
                    SIH.LastStocktakeQuantity AS Original_LastStocktakeQuantity,
                    SIH.LastCostPrice AS Original_LastCostPrice,
                    SIH.ReorderLevel AS Original_ReorderLevel,
                    SIH.TargetStockLevel AS Original_TargetStockLevel,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
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
                WD.Warehouse_WWIStockItemID = TD.Original_WWIStockItemID
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                (
                    WD.Warehouse_QuantityOnHand != TD.Original_QuantityOnHand OR
                    WD.Warehouse_BinLocation != TD.Original_BinLocation OR
                    WD.Warehouse_LastStocktakeQuantity != TD.Original_LastStocktakeQuantity OR
                    WD.Warehouse_LastCostPrice != TD.Original_LastCostPrice OR
                    WD.Warehouse_ReorderLevel != TD.Original_ReorderLevel OR
                    WD.Warehouse_TargetStockLevel != TD.Original_TargetStockLevel OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate 
                )
            )
    ''', CHR(10), ' '), CHR(9), ' ') AS Sql
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
                    FSH.QuantityOnHand AS Warehouse_QuantityOnHand,
                    FSH.BinLocation AS Warehouse_BinLocation,
                    FSH.LastStocktakeQuantity AS Warehouse_LastStocktakeQuantity,
                    FSH.LastCostPrice AS Warehouse_LastCostPrice,
                    FSH.ReorderLevel AS Warehouse_ReorderLevel,
                    FSH.TargetStockLevel AS Warehouse_TargetStockLevel,
                    FSH.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctStockHoldings }} FSH LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FSH.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FSH.LoadDate = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT 
                    SI.StockItemID AS Original_WWIStockItemID,
                    SIH.QuantityOnHand AS Original_QuantityOnHand,
                    SIH.BinLocation AS Original_BinLocation,
                    SIH.LastStocktakeQuantity AS Original_LastStocktakeQuantity,
                    SIH.LastCostPrice AS Original_LastCostPrice,
                    SIH.ReorderLevel AS Original_ReorderLevel,
                    SIH.TargetStockLevel AS Original_TargetStockLevel,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
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
                WD.Warehouse_WWIStockItemID = TD.Original_WWIStockItemID
        WHERE 
            WD.Warehouse_WWIStockItemID IS NULL OR 
            TD.Original_WWIStockItemID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemID IS NOT NULL AND 
                TD.Original_WWIStockItemID IS NOT NULL AND 
                (
                    WD.Warehouse_QuantityOnHand != TD.Original_QuantityOnHand OR
                    WD.Warehouse_BinLocation != TD.Original_BinLocation OR
                    WD.Warehouse_LastStocktakeQuantity != TD.Original_LastStocktakeQuantity OR
                    WD.Warehouse_LastCostPrice != TD.Original_LastCostPrice OR
                    WD.Warehouse_ReorderLevel != TD.Original_ReorderLevel OR
                    WD.Warehouse_TargetStockLevel != TD.Original_TargetStockLevel OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate 
                )
            )
    ) R