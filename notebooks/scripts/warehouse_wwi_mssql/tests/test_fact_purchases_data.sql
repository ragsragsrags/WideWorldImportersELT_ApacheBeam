SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = REPLACE(REPLACE('
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIPurchaseOrderID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWIPurchaseOrderID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_DateKey] = FP.[DateKey],
                    [Warehouse_WWIPurchaseOrderID] = FP.[WWIPurchaseOrderID],
                    [Warehouse_WWIPurchaseOrderLineID] = FP.[WWIPurchaseOrderLineID],
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_OrderedOuters] = FP.[OrderedOuters],
                    [Warehouse_OrderedQuantity] = FP.[OrderedQuantity],
                    [Warehouse_ReceivedOuters] = FP.[ReceivedOuters],
                    [Warehouse_Package] = FP.[Package],
                    [Warehouse_IsOrderFinalized] = FP.[IsOrderFinalized],
                    [Warehouse_LoadDate] = FP.[LoadDate]
                FROM 
                    [dbo].[FctPurchases] FP LEFT JOIN
                    [dbo].[DimSuppliers] DS ON
                        FP.SupplierKey = DS.SupplierKey LEFT JOIN
                    [dbo].[DimStockItems] DSI ON
                        FP.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FP.[LoadDate] = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_DateKey] = PO.OrderDate,
                    [Original_WWIPurchaseOrderID] = PO.PurchaseOrderID,
                    [Original_WWIPurchaseOrderLineID] = POL.PurchaseOrderLineID,
                    [Original_WWISupplierID] = S.SupplierID,
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_OrderedOuters] = POL.OrderedOuters,
                    [Original_OrderedQuantity] = POL.OrderedOuters * SI.QuantityPerOuter,
                    [Original_ReceivedOuters] = POL.ReceivedOuters,
                    [Original_Package] = PT.PackageTypeName,
                    [Original_IsOrderFinalized] = PO.IsOrderFinalized,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    [dbo].[Purchasing_PurchaseOrders] PO LEFT JOIN
                    [dbo].[Purchasing_PurchaseOrderLines] POL ON
                        POL.PurchaseOrderID = PO.PurchaseOrderID LEFT JOIN
                    (
                        SELECT 
                            S.SupplierID,
                            S.SupplierName
                        FROM
                            {{ PurchasingSuppliers }} S
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN S.ValidFrom AND S.ValidTo

                        UNION ALL

                        SELECT 
                            SA.SupplierID,
                            SA.SupplierName
                        FROM
                            {{ PurchasingSuppliersArchive }} AS SA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S ON
                        S.SupplierID = PO.SupplierID LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName,
                            SI.QuantityPerOuter
                        FROM
                            {{ WarehouseStockItems }} AS SI 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName,
                            SIA.QuantityPerOuter
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = POL.StockItemID LEFT JOIN
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
                    ) PT ON
                        PT.PackageTypeID = POL.PackageTypeID
                WHERE
                    (
			            PO.LastEditedWhen > ''<< LastCutoffDate >>'' OR
			            POL.LastEditedWhen > ''<< LastCutoffDate >>'' OR
			            POL.PackageTypeID IN 
			            (
				            SELECT
		                        PT.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypes }} PT
	                        WHERE
		                        PT.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PT.ValidFrom  AND PT.ValidTo

	                        UNION ALL

	                        SELECT
		                        PTA.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypesArchive }} PTA
	                        WHERE
		                        PTA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom AND PTA.ValidTo
			            ) OR
			            POL.StockItemID IN 
			            (
				            SELECT
		                        SI.StockItemID
	                        FROM
		                        {{ WarehouseStockItems }} SI
	                        WHERE
		                        SI.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN SI.ValidFrom  AND SI.ValidTo

	                        UNION ALL

	                        SELECT
		                        SIA.StockItemID
	                        FROM
		                        {{ WarehouseStockItemsArchive }} SIA
	                        WHERE
		                        SIA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom  AND SIA.ValidTo
			            )
		            ) AND
		            PO.LastEditedWhen <= ''<< NewCutoffDate >>'' AND
		            POL.LastEditedWhen <= ''<< NewCutoffDate >>''
            ) TD ON 
                WD.[Warehouse_WWIPurchaseOrderID] = TD.[Original_WWIPurchaseOrderID] AND
                WD.[Warehouse_WWIPurchaseOrderLineID] = TD.[Original_WWIPurchaseOrderLineID]
        WHERE 
            WD.Warehouse_WWIPurchaseOrderID IS NULL OR 
            TD.Original_WWIPurchaseOrderID IS NULL OR 
            ( 
                WD.Warehouse_WWIPurchaseOrderID IS NOT NULL AND 
                TD.Original_WWIPurchaseOrderID IS NOT NULL AND 
                (
                    WD.[Warehouse_DateKey] != TD.[Original_DateKey] OR
                    WD.[Warehouse_WWIPurchaseOrderID] != TD.[Original_WWIPurchaseOrderID] OR
                    WD.[Warehouse_WWIPurchaseOrderLineID] != TD.[Original_WWIPurchaseOrderLineID] OR
                    WD.[Warehouse_WWISupplierID] != TD.[Original_WWISupplierID] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_OrderedOuters] != TD.[Original_OrderedOuters] OR
                    WD.[Warehouse_OrderedQuantity] != TD.[Original_OrderedQuantity] OR
                    WD.[Warehouse_ReceivedOuters] != TD.[Original_ReceivedOuters] OR
                    WD.[Warehouse_Package] != TD.[Original_Package] OR
                    WD.[Warehouse_IsOrderFinalized] != TD.[Original_IsOrderFinalized] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                )
            )
    ', CHAR(10), ' '), CHAR(9), ' ')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIPurchaseOrderID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWIPurchaseOrderID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_DateKey] = FP.[DateKey],
                    [Warehouse_WWIPurchaseOrderID] = FP.[WWIPurchaseOrderID],
                    [Warehouse_WWIPurchaseOrderLineID] = FP.[WWIPurchaseOrderLineID],
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_OrderedOuters] = FP.[OrderedOuters],
                    [Warehouse_OrderedQuantity] = FP.[OrderedQuantity],
                    [Warehouse_ReceivedOuters] = FP.[ReceivedOuters],
                    [Warehouse_Package] = FP.[Package],
                    [Warehouse_IsOrderFinalized] = FP.[IsOrderFinalized],
                    [Warehouse_LoadDate] = FP.[LoadDate]
                FROM 
                    [dbo].[FctPurchases] FP LEFT JOIN
                    [dbo].[DimSuppliers] DS ON
                        FP.SupplierKey = DS.SupplierKey LEFT JOIN
                    [dbo].[DimStockItems] DSI ON
                        FP.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FP.[LoadDate] = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_DateKey] = PO.OrderDate,
                    [Original_WWIPurchaseOrderID] = PO.PurchaseOrderID,
                    [Original_WWIPurchaseOrderLineID] = POL.PurchaseOrderLineID,
                    [Original_WWISupplierID] = S.SupplierID,
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_OrderedOuters] = POL.OrderedOuters,
                    [Original_OrderedQuantity] = POL.OrderedOuters * SI.QuantityPerOuter,
                    [Original_ReceivedOuters] = POL.ReceivedOuters,
                    [Original_Package] = PT.PackageTypeName,
                    [Original_IsOrderFinalized] = PO.IsOrderFinalized,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    [dbo].[Purchasing_PurchaseOrders] PO LEFT JOIN
                    [dbo].[Purchasing_PurchaseOrderLines] POL ON
                        POL.PurchaseOrderID = PO.PurchaseOrderID LEFT JOIN
                    (
                        SELECT 
                            S.SupplierID,
                            S.SupplierName
                        FROM
                            {{ PurchasingSuppliers }} S
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN S.ValidFrom AND S.ValidTo

                        UNION ALL

                        SELECT 
                            SA.SupplierID,
                            SA.SupplierName
                        FROM
                            {{ PurchasingSuppliersArchive }} AS SA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S ON
                        S.SupplierID = PO.SupplierID LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName,
                            SI.QuantityPerOuter
                        FROM
                            {{ WarehouseStockItems }} AS SI 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName,
                            SIA.QuantityPerOuter
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = POL.StockItemID LEFT JOIN
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
                    ) PT ON
                        PT.PackageTypeID = POL.PackageTypeID
                WHERE
                    (
			            PO.LastEditedWhen > '<< LastCutoffDate >>' OR
			            POL.LastEditedWhen > '<< LastCutoffDate >>' OR
			            POL.PackageTypeID IN 
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
			            ) OR
			            POL.StockItemID IN 
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
			            )
		            ) AND
		            PO.LastEditedWhen <= '<< NewCutoffDate >>' AND
		            POL.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                WD.[Warehouse_WWIPurchaseOrderID] = TD.[Original_WWIPurchaseOrderID] AND
                WD.[Warehouse_WWIPurchaseOrderLineID] = TD.[Original_WWIPurchaseOrderLineID]
        WHERE 
            WD.Warehouse_WWIPurchaseOrderID IS NULL OR 
            TD.Original_WWIPurchaseOrderID IS NULL OR 
            ( 
                WD.Warehouse_WWIPurchaseOrderID IS NOT NULL AND 
                TD.Original_WWIPurchaseOrderID IS NOT NULL AND 
                (
                    WD.[Warehouse_DateKey] != TD.[Original_DateKey] OR
                    WD.[Warehouse_WWIPurchaseOrderID] != TD.[Original_WWIPurchaseOrderID] OR
                    WD.[Warehouse_WWIPurchaseOrderLineID] != TD.[Original_WWIPurchaseOrderLineID] OR
                    WD.[Warehouse_WWISupplierID] != TD.[Original_WWISupplierID] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_OrderedOuters] != TD.[Original_OrderedOuters] OR
                    WD.[Warehouse_OrderedQuantity] != TD.[Original_OrderedQuantity] OR
                    WD.[Warehouse_ReceivedOuters] != TD.[Original_ReceivedOuters] OR
                    WD.[Warehouse_Package] != TD.[Original_Package] OR
                    WD.[Warehouse_IsOrderFinalized] != TD.[Original_IsOrderFinalized] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                )
            )
    ) R