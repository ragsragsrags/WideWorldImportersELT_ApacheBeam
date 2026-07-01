SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE(REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWITransactionTypeID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FM.DateKey AS Warehouse_DateKey,
                    FM.WWIStockItemTransactionID AS Warehouse_WWIStockItemTransactionID,
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    DC.WWICustomerID AS Warehouse_WWICustomerID,
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DTT.WWITransactionTypeID AS Warehouse_WWITransactionTypeID,
                    FM.WWIInvoiceID AS Warehouse_WWIInvoiceID,
                    FM.WWIPurchaseOrderID AS Warehouse_WWIPurchaseOrderID,
                    FM.Quantity AS Warehouse_Quantity,
                    FM.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctMovements }} FM LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FM.StockItemKey = DSI.StockItemKey LEFT JOIN
                    {{ DimCustomers }} DC ON
                        FM.CustomerKey = DC.CustomerKey LEFT JOIN
                    {{ DimSuppliers }} DS ON
                        FM.SupplierKey = DS.SupplierKey LEFT JOIN
                    {{ DimTransactionTypes }} DTT ON
                        FM.TransactionTypeKey = DTT.TransactionTypeKey
                WHERE 
                    FM.LoadDate = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    CAST(SIT.TransactionOccurredWhen AS DATE) AS Original_DateKey,
                    SIT.StockItemTransactionID AS Original_WWIStockItemTransactionID,
                    IFNULL(SI.StockItemID, 0) AS Original_WWIStockItemID,
                    IFNULL(C.CustomerID, 0) AS Original_WWICustomerID,
                    IFNULL(S.SupplierID, 0) AS Original_WWISupplierID,
                    IFNULL(TT.TransactionTypeID, 0) AS Original_WWITransactionTypeID,
                    IFNULL(SIT.InvoiceID, 0) AS Original_WWIInvoiceID,
                    IFNULL(SIT.PurchaseOrderID, 0) AS Original_WWIPurchaseOrderID,
                    SIT.Quantity AS Original_Quantity,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ WarehouseStockItemTransactions }} SIT LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName
                        FROM
                            {{ WarehouseStockItems }} SI 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN Si.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = SIT.StockItemID LEFT JOIN
                    (
                        SELECT
                            C.CustomerID,
                            C.CustomerName
                        FROM
                            {{ SalesCustomers }} C 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CustomerID,
                            CA.CustomerName
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON 
                        C.CustomerID = SIT.CustomerID LEFT JOIN
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
                            {{ PurchasingSuppliersArchive }} SA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S ON 
                        S.SupplierID = SIT.SupplierID LEFT JOIN
                    (
                        SELECT
                            TT.TransactionTypeID,
                            TT.TransactionTypeName
                        FROM
                            {{ ApplicationTransactionTypes }} TT 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN TT.ValidFrom AND TT.ValidTo

                        UNION ALL

                        SELECT
                            TTA.TransactionTypeID,
                            TTA.TransactionTypeName
                        FROM
                            {{ ApplicationTransactionTypesArchive }} TTA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN TTA.ValidFrom AND TTA.ValidTo
                    ) TT ON 
                        TT.TransactionTypeID = SIT.TransactionTypeID
                WHERE
                    SIT.LastEditedWhen > '<< LastCutoffDate >>' AND
                    SIT.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                WD.Warehouse_WWIStockItemTransactionID = TD.Original_WWIStockItemTransactionID 
        WHERE 
            WD.Warehouse_WWIStockItemTransactionID IS NULL OR 
            TD.Original_WWIStockItemTransactionID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemTransactionID IS NOT NULL AND 
                TD.Original_WWIStockItemTransactionID IS NOT NULL AND 
                (
                    WD.Warehouse_DateKey != TD.Original_DateKey OR
                    WD.Warehouse_WWIStockItemID != TD.Original_WWIStockItemID OR
                    WD.Warehouse_WWICustomerID != TD.Original_WWICustomerID OR
                    WD.Warehouse_WWISupplierID != TD.Original_WWISupplierID OR
                    WD.Warehouse_WWITransactionTypeID != TD.Original_WWITransactionTypeID OR
                    WD.Warehouse_WWIInvoiceID != TD.Original_WWIInvoiceID OR
                    WD.Warehouse_WWIPurchaseOrderID != TD.Original_WWIPurchaseOrderID OR
                    WD.Warehouse_Quantity != TD.Original_Quantity OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate
                )
            )
    ''', CHR(10), ' '), CHR(9), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWITransactionTypeID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FM.DateKey AS Warehouse_DateKey,
                    FM.WWIStockItemTransactionID AS Warehouse_WWIStockItemTransactionID,
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    DC.WWICustomerID AS Warehouse_WWICustomerID,
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DTT.WWITransactionTypeID AS Warehouse_WWITransactionTypeID,
                    FM.WWIInvoiceID AS Warehouse_WWIInvoiceID,
                    FM.WWIPurchaseOrderID AS Warehouse_WWIPurchaseOrderID,
                    FM.Quantity AS Warehouse_Quantity,
                    FM.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctMovements }} FM LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FM.StockItemKey = DSI.StockItemKey LEFT JOIN
                    {{ DimCustomers }} DC ON
                        FM.CustomerKey = DC.CustomerKey LEFT JOIN
                    {{ DimSuppliers }} DS ON
                        FM.SupplierKey = DS.SupplierKey LEFT JOIN
                    {{ DimTransactionTypes }} DTT ON
                        FM.TransactionTypeKey = DTT.TransactionTypeKey
                WHERE 
                    FM.LoadDate = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    CAST(SIT.TransactionOccurredWhen AS DATE) AS Original_DateKey,
                    SIT.StockItemTransactionID AS Original_WWIStockItemTransactionID,
                    IFNULL(SI.StockItemID, 0) AS Original_WWIStockItemID,
                    IFNULL(C.CustomerID, 0) AS Original_WWICustomerID,
                    IFNULL(S.SupplierID, 0) AS Original_WWISupplierID,
                    IFNULL(TT.TransactionTypeID, 0) AS Original_WWITransactionTypeID,
                    IFNULL(SIT.InvoiceID, 0) AS Original_WWIInvoiceID,
                    IFNULL(SIT.PurchaseOrderID, 0) AS Original_WWIPurchaseOrderID,
                    SIT.Quantity AS Original_Quantity,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ WarehouseStockItemTransactions }} SIT LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName
                        FROM
                            {{ WarehouseStockItems }} SI 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN Si.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = SIT.StockItemID LEFT JOIN
                    (
                        SELECT
                            C.CustomerID,
                            C.CustomerName
                        FROM
                            {{ SalesCustomers }} C 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CustomerID,
                            CA.CustomerName
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON 
                        C.CustomerID = SIT.CustomerID LEFT JOIN
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
                            {{ PurchasingSuppliersArchive }} SA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S ON 
                        S.SupplierID = SIT.SupplierID LEFT JOIN
                    (
                        SELECT
                            TT.TransactionTypeID,
                            TT.TransactionTypeName
                        FROM
                            {{ ApplicationTransactionTypes }} TT 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN TT.ValidFrom AND TT.ValidTo

                        UNION ALL

                        SELECT
                            TTA.TransactionTypeID,
                            TTA.TransactionTypeName
                        FROM
                            {{ ApplicationTransactionTypesArchive }} TTA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN TTA.ValidFrom AND TTA.ValidTo
                    ) TT ON 
                        TT.TransactionTypeID = SIT.TransactionTypeID
                WHERE
                    SIT.LastEditedWhen > '<< LastCutoffDate >>' AND
                    SIT.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                WD.Warehouse_WWIStockItemTransactionID = TD.Original_WWIStockItemTransactionID 
        WHERE 
            WD.Warehouse_WWIStockItemTransactionID IS NULL OR 
            TD.Original_WWIStockItemTransactionID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemTransactionID IS NOT NULL AND 
                TD.Original_WWIStockItemTransactionID IS NOT NULL AND 
                (
                    WD.Warehouse_DateKey != TD.Original_DateKey OR
                    WD.Warehouse_WWIStockItemID != TD.Original_WWIStockItemID OR
                    WD.Warehouse_WWICustomerID != TD.Original_WWICustomerID OR
                    WD.Warehouse_WWISupplierID != TD.Original_WWISupplierID OR
                    WD.Warehouse_WWITransactionTypeID != TD.Original_WWITransactionTypeID OR
                    WD.Warehouse_WWIInvoiceID != TD.Original_WWIInvoiceID OR
                    WD.Warehouse_WWIPurchaseOrderID != TD.Original_WWIPurchaseOrderID OR
                    WD.Warehouse_Quantity != TD.Original_Quantity OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate
                )
            )
    ) R