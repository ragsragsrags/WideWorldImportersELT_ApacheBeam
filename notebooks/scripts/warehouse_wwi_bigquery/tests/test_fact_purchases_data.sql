SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE(REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWIPurchaseOrderID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWIPurchaseOrderID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FP.DateKey AS Warehouse_DateKey,
                    FP.WWIPurchaseOrderID AS Warehouse_WWIPurchaseOrderID,
                    FP.WWIPurchaseOrderLineID AS Warehouse_WWIPurchaseOrderLineID,
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    FP.OrderedOuters AS Warehouse_OrderedOuters,
                    FP.OrderedQuantity AS Warehouse_OrderedQuantity,
                    FP.ReceivedOuters AS Warehouse_ReceivedOuters,
                    FP.Package AS Warehouse_Package,
                    FP.IsOrderFinalized AS Warehouse_IsOrderFinalized,
                    FP.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctPurchases }} FP LEFT JOIN
                    {{ DimSuppliers }} DS ON
                        FP.SupplierKey = DS.SupplierKey LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FP.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FP.LoadDate = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    PO.OrderDate AS Original_DateKey,
                    PO.PurchaseOrderID AS Original_WWIPurchaseOrderID,
                    POL.PurchaseOrderLineID AS Original_WWIPurchaseOrderLineID,
                    S.SupplierID AS Original_WWISupplierID,
                    SI.StockItemID AS Original_WWIStockItemID,
                    POL.OrderedOuters AS Original_OrderedOuters,
                    (POL.OrderedOuters * SI.QuantityPerOuter) AS Original_OrderedQuantity,
                    POL.ReceivedOuters AS Original_ReceivedOuters,
                    PT.PackageTypeName AS Original_Package,
                    PO.IsOrderFinalized AS Original_IsOrderFinalized,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ PurchasingPurchaseOrders }} PO LEFT JOIN
                    {{ PurchasingPurchaseOrderLines }} POL ON
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
                WD.Warehouse_WWIPurchaseOrderID = TD.Original_WWIPurchaseOrderID AND
                WD.Warehouse_WWIPurchaseOrderLineID = TD.Original_WWIPurchaseOrderLineID
        WHERE 
            WD.Warehouse_WWIPurchaseOrderID IS NULL OR 
            TD.Original_WWIPurchaseOrderID IS NULL OR 
            ( 
                WD.Warehouse_WWIPurchaseOrderID IS NOT NULL AND 
                TD.Original_WWIPurchaseOrderID IS NOT NULL AND 
                (
                    WD.Warehouse_DateKey != TD.Original_DateKey OR
                    WD.Warehouse_WWIPurchaseOrderID != TD.Original_WWIPurchaseOrderID OR
                    WD.Warehouse_WWIPurchaseOrderLineID != TD.Original_WWIPurchaseOrderLineID OR
                    WD.Warehouse_WWISupplierID != TD.Original_WWISupplierID OR
                    WD.Warehouse_WWIStockItemID != TD.Original_WWIStockItemID OR
                    WD.Warehouse_OrderedOuters != TD.Original_OrderedOuters OR
                    WD.Warehouse_OrderedQuantity != TD.Original_OrderedQuantity OR
                    WD.Warehouse_ReceivedOuters != TD.Original_ReceivedOuters OR
                    WD.Warehouse_Package != TD.Original_Package OR
                    WD.Warehouse_IsOrderFinalized != TD.Original_IsOrderFinalized OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate
                )
            )
    ''', CHR(10), ' '), CHR(9), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWIPurchaseOrderID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWIPurchaseOrderID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FP.DateKey AS Warehouse_DateKey,
                    FP.WWIPurchaseOrderID AS Warehouse_WWIPurchaseOrderID,
                    FP.WWIPurchaseOrderLineID AS Warehouse_WWIPurchaseOrderLineID,
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    FP.OrderedOuters AS Warehouse_OrderedOuters,
                    FP.OrderedQuantity AS Warehouse_OrderedQuantity,
                    FP.ReceivedOuters AS Warehouse_ReceivedOuters,
                    FP.Package AS Warehouse_Package,
                    FP.IsOrderFinalized AS Warehouse_IsOrderFinalized,
                    FP.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctPurchases }} FP LEFT JOIN
                    {{ DimSuppliers }} DS ON
                        FP.SupplierKey = DS.SupplierKey LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FP.StockItemKey = DSI.StockItemKey 
                WHERE 
                    FP.LoadDate = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    PO.OrderDate AS Original_DateKey,
                    PO.PurchaseOrderID AS Original_WWIPurchaseOrderID,
                    POL.PurchaseOrderLineID AS Original_WWIPurchaseOrderLineID,
                    S.SupplierID AS Original_WWISupplierID,
                    SI.StockItemID AS Original_WWIStockItemID,
                    POL.OrderedOuters AS Original_OrderedOuters,
                    (POL.OrderedOuters * SI.QuantityPerOuter) AS Original_OrderedQuantity,
                    POL.ReceivedOuters AS Original_ReceivedOuters,
                    PT.PackageTypeName AS Original_Package,
                    PO.IsOrderFinalized AS Original_IsOrderFinalized,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ PurchasingPurchaseOrders }} PO LEFT JOIN
                    {{ PurchasingPurchaseOrderLines }} POL ON
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
                WD.Warehouse_WWIPurchaseOrderID = TD.Original_WWIPurchaseOrderID AND
                WD.Warehouse_WWIPurchaseOrderLineID = TD.Original_WWIPurchaseOrderLineID
        WHERE 
            WD.Warehouse_WWIPurchaseOrderID IS NULL OR 
            TD.Original_WWIPurchaseOrderID IS NULL OR 
            ( 
                WD.Warehouse_WWIPurchaseOrderID IS NOT NULL AND 
                TD.Original_WWIPurchaseOrderID IS NOT NULL AND 
                (
                    WD.Warehouse_DateKey != TD.Original_DateKey OR
                    WD.Warehouse_WWIPurchaseOrderID != TD.Original_WWIPurchaseOrderID OR
                    WD.Warehouse_WWIPurchaseOrderLineID != TD.Original_WWIPurchaseOrderLineID OR
                    WD.Warehouse_WWISupplierID != TD.Original_WWISupplierID OR
                    WD.Warehouse_WWIStockItemID != TD.Original_WWIStockItemID OR
                    WD.Warehouse_OrderedOuters != TD.Original_OrderedOuters OR
                    WD.Warehouse_OrderedQuantity != TD.Original_OrderedQuantity OR
                    WD.Warehouse_ReceivedOuters != TD.Original_ReceivedOuters OR
                    WD.Warehouse_Package != TD.Original_Package OR
                    WD.Warehouse_IsOrderFinalized != TD.Original_IsOrderFinalized OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate
                )
            )
    ) R