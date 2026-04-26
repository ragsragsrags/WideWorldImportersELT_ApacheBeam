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
                    WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWITransactionTypeID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_DateKey] = FM.[DateKey],
                    [Warehouse_WWIStockItemTransactionID] = FM.[WWIStockItemTransactionID],
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_WWICustomerID] = DC.[WWICustomerID],
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_WWITransactionTypeID] = DTT.[WWITransactionTypeID],
                    [Warehouse_WWIInvoiceID] = FM.[WWIInvoiceID],
                    [Warehouse_WWIPurchaseOrderID] = FM.[WWIPurchaseOrderID],
                    [Warehouse_Quantity] = FM.[Quantity],
                    [Warehouse_LoadDate] = FM.[LoadDate]
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
                    FM.[LoadDate] = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_DateKey] = CAST(SIT.TransactionOccurredWhen AS DATE),
                    [Original_WWIStockItemTransactionID] = SIT.StockItemTransactionID,
                    [Original_WWIStockItemID] = ISNULL(SI.StockItemID, 0),
                    [Original_WWICustomerID] = ISNULL(C.CustomerID, 0),
                    [Original_WWISupplierID] = ISNULL(S.SupplierID, 0),
                    [Original_WWITransactionTypeID] = ISNULL(TT.TransactionTypeID, 0),
                    [Original_WWIInvoiceID] = ISNULL(SIT.InvoiceID, 0),
                    [Original_WWIPurchaseOrderID] = ISNULL(SIT.PurchaseOrderID, 0),
                    [Original_Quantity] = SIT.Quantity,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    {{ WarehouseStockItemTransactions }} SIT LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName
                        FROM
                            {{ WarehouseStockItems }} SI 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN Si.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = SIT.StockItemID LEFT JOIN
                    (
                        SELECT
                            C.CustomerID,
                            C.CustomerName
                        FROM
                            {{ SalesCustomers }} C 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CustomerID,
                            CA.CustomerName
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON 
                        C.CustomerID = SIT.CustomerID LEFT JOIN
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
                            {{ PurchasingSuppliersArchive }} SA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S ON 
                        S.SupplierID = SIT.SupplierID LEFT JOIN
                    (
                        SELECT
                            TT.TransactionTypeID,
                            TT.TransactionTypeName
                        FROM
                            {{ ApplicationTransactionTypes }} TT 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN TT.ValidFrom AND TT.ValidTo

                        UNION ALL

                        SELECT
                            TTA.TransactionTypeID,
                            TTA.TransactionTypeName
                        FROM
                            {{ ApplicationTransactionTypesArchive }} TTA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN TTA.ValidFrom AND TTA.ValidTo
                    ) TT ON 
                        TT.TransactionTypeID = SIT.TransactionTypeID
                WHERE
                    SIT.LastEditedWhen > ''<< LastCutoffDate >>'' AND
                    SIT.LastEditedWhen <= ''<< NewCutoffDate >>''
            ) TD ON 
                WD.[Warehouse_WWIStockItemTransactionID] = TD.[Original_WWIStockItemTransactionID] 
        WHERE 
            WD.Warehouse_WWIStockItemTransactionID IS NULL OR 
            TD.Original_WWIStockItemTransactionID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemTransactionID IS NOT NULL AND 
                TD.Original_WWIStockItemTransactionID IS NOT NULL AND 
                (
                    WD.[Warehouse_DateKey] != TD.[Original_DateKey] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWISupplierID] != TD.[Original_WWISupplierID] OR
                    WD.[Warehouse_WWITransactionTypeID] != TD.[Original_WWITransactionTypeID] OR
                    WD.[Warehouse_WWIInvoiceID] != TD.[Original_WWIInvoiceID] OR
                    WD.[Warehouse_WWIPurchaseOrderID] != TD.[Original_WWIPurchaseOrderID] OR
                    WD.[Warehouse_Quantity] != TD.[Original_Quantity] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                )
            )
    ', CHAR(10), ' '), CHAR(9), ' ')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWITransactionTypeID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_DateKey] = FM.[DateKey],
                    [Warehouse_WWIStockItemTransactionID] = FM.[WWIStockItemTransactionID],
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_WWICustomerID] = DC.[WWICustomerID],
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_WWITransactionTypeID] = DTT.[WWITransactionTypeID],
                    [Warehouse_WWIInvoiceID] = FM.[WWIInvoiceID],
                    [Warehouse_WWIPurchaseOrderID] = FM.[WWIPurchaseOrderID],
                    [Warehouse_Quantity] = FM.[Quantity],
                    [Warehouse_LoadDate] = FM.[LoadDate]
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
                    FM.[LoadDate] = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_DateKey] = CAST(SIT.TransactionOccurredWhen AS DATE),
                    [Original_WWIStockItemTransactionID] = SIT.StockItemTransactionID,
                    [Original_WWIStockItemID] = ISNULL(SI.StockItemID, 0),
                    [Original_WWICustomerID] = ISNULL(C.CustomerID, 0),
                    [Original_WWISupplierID] = ISNULL(S.SupplierID, 0),
                    [Original_WWITransactionTypeID] = ISNULL(TT.TransactionTypeID, 0),
                    [Original_WWIInvoiceID] = ISNULL(SIT.InvoiceID, 0),
                    [Original_WWIPurchaseOrderID] = ISNULL(SIT.PurchaseOrderID, 0),
                    [Original_Quantity] = SIT.Quantity,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
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
                WD.[Warehouse_WWIStockItemTransactionID] = TD.[Original_WWIStockItemTransactionID] 
        WHERE 
            WD.Warehouse_WWIStockItemTransactionID IS NULL OR 
            TD.Original_WWIStockItemTransactionID IS NULL OR 
            ( 
                WD.Warehouse_WWIStockItemTransactionID IS NOT NULL AND 
                TD.Original_WWIStockItemTransactionID IS NOT NULL AND 
                (
                    WD.[Warehouse_DateKey] != TD.[Original_DateKey] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWISupplierID] != TD.[Original_WWISupplierID] OR
                    WD.[Warehouse_WWITransactionTypeID] != TD.[Original_WWITransactionTypeID] OR
                    WD.[Warehouse_WWIInvoiceID] != TD.[Original_WWIInvoiceID] OR
                    WD.[Warehouse_WWIPurchaseOrderID] != TD.[Original_WWIPurchaseOrderID] OR
                    WD.[Warehouse_Quantity] != TD.[Original_Quantity] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                )
            )
    ) R