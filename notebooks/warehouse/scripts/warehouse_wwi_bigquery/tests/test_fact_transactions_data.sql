SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE(REPLACE('''
        SELECT 
            CASE 
                WHEN (
                    WD.Warehouse_WWICustomerTransactionID IS NULL AND
                    WD.Warehouse_WWISupplierTransactionID IS NULL
                ) THEN ''Missing in warehouse data'' 
                WHEN (
                    TD.Original_WWICustomerTransactionID IS NULL AND
                    TD.Original_WWISupplierTransactionID IS NULL
                ) THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FT.DateKey AS Warehouse_DateKey,
                    FT.WWICustomerTransactionID AS Warehouse_WWICustomerTransactionID,
                    FT.WWISupplierTransactionID AS Warehouse_WWISupplierTransactionID,
                    FT.WWIInvoiceID AS Warehouse_WWIInvoiceID,
                    FT.WWIPurchaseOrderID AS Warehouse_WWIPurchaseOrderID,
                    DC.WWICustomerID AS Warehouse_WWICustomerID,
                    BDC.WWICustomerID AS Warehouse_WWIBillToCustomerID,
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DTS.WWITransactionTypeID AS Warehouse_WWITransactionTypeID,
                    DPM.WWIPaymentMethodID AS Warehouse_WWIPaymentMethodID,
                    FT.SupplierInvoiceNumber AS Warehouse_SupplierInvoiceNumber,
                    FT.TotalExcludingTax AS Warehouse_TotalExcludingTax,
                    FT.TaxAmount AS Warehouse_TaxAmount,
                    FT.TotalIncludingTax AS Warehouse_TotalIncludingTax,
                    FT.OutstandingBalance AS Warehouse_OutstandingBalance,
                    FT.IsFinalized AS Warehouse_IsFinalized,
                    FT.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctTransactions }} FT LEFT JOIN
                    {{ DimCustomers }} DC ON
                        FT.CustomerKey = DC.CustomerKey LEFT JOIN
                    {{ DimCustomers }} BDC ON
                        FT.BillToCustomerKey = BDC.CustomerKey LEFT JOIN
                    {{ DimSuppliers }} DS ON
                        FT.SupplierKey = DS.SupplierKey LEFT JOIN
                    {{ DimTransactionTypes }} DTS ON
                        FT.TransactionTypeKey = DTS.TransactionTypeKey LEFT JOIN
                    {{ DimPaymentMethods }} DPM ON
                        FT.PaymentMethodKey = DPM.PaymentMethodKey
                WHERE 
                    FT.LoadDate = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    CT.TransactionDate AS Original_DateKey,
                    CT.CustomerTransactionID AS Original_WWICustomerTransactionID,
                    CAST(NULL AS INTEGER) AS Original_WWISupplierTransactionID,
                    CT.InvoiceID AS Original_WWIInvoiceID,
                    CAST(NULL AS INTEGER) AS Original_WWIPurchaseOrderID,
                    C.CustomerID AS Original_WWICustomerID,
                    BC.CustomerID AS Original_WWIBillToCustomerID,
                    CAST(NULL AS INTEGER) AS Original_WWISupplierID,
                    TT.TransactionTypeID AS Original_WWITransactionTypeID,
                    PM.PaymentMethodID AS Original_WWIPaymentMethodID,
                    CAST(NULL AS STRING) AS Original_SupplierInvoiceNumber,
                    CT.AmountExcludingTax AS Original_TotalExcludingTax,
                    CT.TaxAmount AS Original_TaxAmount,
                    CT.TransactionAmount AS Original_TotalIncludingTax,
                    CT.OutstandingBalance AS Original_OutstandingBalance,
                    CT.IsFinalized AS Original_IsFinalized,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ SalesCustomerTransactions }} CT LEFT JOIN
                    {{ SalesInvoices }} I ON
                        I.InvoiceID = CT.InvoiceID LEFT JOIN
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
                        C.CustomerID = COALESCE(I.CustomerID, CT.CustomerID) LEFT JOIN
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
                    ) BC ON
                        BC.CustomerID = COALESCE(I.CustomerID, CT.CustomerID) LEFT JOIN
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
                        TT.TransactionTypeID = CT.TransactionTypeID LEFT JOIN
                    (
                        SELECT
                            PM.PaymentMethodID,
                            PM.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethods }} PM 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PM.ValidFrom AND PM.ValidTo

                        UNION ALL

                        SELECT
                            PMA.PaymentMethodID,
                            PMA.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethodsArchive }} PMA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PMA.ValidFrom AND PMA.ValidTo
                    ) PM ON
                        PM.PaymentMethodID = CT.PaymentMethodID
                WHERE
                    CT.LastEditedWhen > ''<< LastCutoffDate >>'' AND
                    CT.LastEditedWhen <= ''<< NewCutoffDate >>''

                UNION ALL

                SELECT
                    ST.TransactionDate AS Original_DateKey,
                    CAST(NULL AS INTEGER) AS Original_WWICustomerTransactionID,
                    ST.SupplierTransactionID AS Original_WWISupplierTransactionID,
                    CAST(NULL AS INTEGER) AS Original_WWIInvoiceID,
                    ST.PurchaseOrderID AS Original_WWIPurchaseOrderID,
                    CAST(NULL AS INTEGER) AS Original_WWICustomerID,
                    CAST(NULL AS INTEGER) AS Original_WWIBillToCustomerID,
                    S.SupplierID AS Original_WWISupplierID,
                    TT.TransactionTypeID AS Original_WWITransactionTypeID,
                    PM.PaymentMethodID AS Original_WWIPaymentMethodID,
                    ST.SupplierInvoiceNumber AS Original_SupplierInvoiceNumber,
                    ST.AmountExcludingTax AS Original_TotalExcludingTax,
                    ST.TaxAmount AS Original_TaxAmount,
                    ST.TransactionAmount AS Original_TotalIncludingTax,
                    ST.OutstandingBalance AS Original_OutstandingBalance,
                    ST.IsFinalized AS Original_IsFinalized,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ PurchasingSupplierTransactions }} ST LEFT JOIN
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
                        S.SupplierID = ST.SupplierID LEFT JOIN
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
                        TT.TransactionTypeID = ST.TransactionTypeID LEFT JOIN
                    (
                        SELECT
                            PM.PaymentMethodID,
                            PM.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethods }} PM 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PM.ValidFrom AND PM.ValidTo

                        UNION ALL

                        SELECT
                            PMA.PaymentMethodID,
                            PMA.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethodsArchive }} PMA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PMA.ValidFrom AND PMA.ValidTo
                    ) PM ON
                        PM.PaymentMethodID = ST.PaymentMethodID
                WHERE
                    ST.LastEditedWhen > ''<< LastCutoffDate >>'' AND
                    ST.LastEditedWhen <= ''<< NewCutoffDate >>''
            ) TD ON 
                IFNULL(WD.Warehouse_WWICustomerTransactionID, 0) = IFNULL(TD.Original_WWICustomerTransactionID, 0) AND
                IFNULL(WD.Warehouse_WWISupplierTransactionID, 0) = IFNULL(TD.Original_WWISupplierTransactionID, 0)
        WHERE 
            (
                WD.Warehouse_WWICustomerTransactionID IS NULL AND
                WD.Warehouse_WWISupplierTransactionID IS NULL
            ) OR 
            (
                TD.Original_WWICustomerTransactionID IS NULL AND
                TD.Original_WWISupplierTransactionID IS NULL
            ) OR 
            ( 
                (
                    WD.Warehouse_WWICustomerTransactionID IS NOT NULL OR
                    WD.Warehouse_WWISupplierTransactionID IS NOT NULL
                ) AND 
                (
                    TD.Original_WWICustomerTransactionID IS NOT NULL OR
                    TD.Original_WWISupplierTransactionID IS NOT NULL
                ) AND 
                (
                    WD.Warehouse_DateKey != TD.Original_DateKey OR
                    WD.Warehouse_WWIInvoiceID != TD.Original_WWIInvoiceID OR
                    WD.Warehouse_WWIPurchaseOrderID != TD.Original_WWIPurchaseOrderID OR
                    WD.Warehouse_WWICustomerID != TD.Original_WWICustomerID OR
                    WD.Warehouse_WWIBillToCustomerID != TD.Original_WWIBillToCustomerID OR
                    WD.Warehouse_WWISupplierID != TD.Original_WWISupplierID OR
                    WD.Warehouse_WWITransactionTypeID != TD.Original_WWITransactionTypeID OR
                    WD.Warehouse_WWIPaymentMethodID != TD.Original_WWIPaymentMethodID OR
                    WD.Warehouse_SupplierInvoiceNumber != TD.Original_SupplierInvoiceNumber OR
                    WD.Warehouse_TotalExcludingTax != TD.Original_TotalExcludingTax OR
                    WD.Warehouse_TaxAmount != TD.Original_TaxAmount OR
                    WD.Warehouse_TotalIncludingTax != TD.Original_TotalIncludingTax OR
                    WD.Warehouse_OutstandingBalance != TD.Original_OutstandingBalance OR
                    WD.Warehouse_IsFinalized != TD.Original_IsFinalized OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate
                )
            )
    ''', CHR(10), ' '), CHR(9), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN (
                    WD.Warehouse_WWICustomerTransactionID IS NULL AND
                    WD.Warehouse_WWISupplierTransactionID IS NULL
                ) THEN 'Missing in warehouse data' 
                WHEN (
                    TD.Original_WWICustomerTransactionID IS NULL AND
                    TD.Original_WWISupplierTransactionID IS NULL
                ) THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FT.DateKey AS Warehouse_DateKey,
                    FT.WWICustomerTransactionID AS Warehouse_WWICustomerTransactionID,
                    FT.WWISupplierTransactionID AS Warehouse_WWISupplierTransactionID,
                    FT.WWIInvoiceID AS Warehouse_WWIInvoiceID,
                    FT.WWIPurchaseOrderID AS Warehouse_WWIPurchaseOrderID,
                    DC.WWICustomerID AS Warehouse_WWICustomerID,
                    BDC.WWICustomerID AS Warehouse_WWIBillToCustomerID,
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DTS.WWITransactionTypeID AS Warehouse_WWITransactionTypeID,
                    DPM.WWIPaymentMethodID AS Warehouse_WWIPaymentMethodID,
                    FT.SupplierInvoiceNumber AS Warehouse_SupplierInvoiceNumber,
                    FT.TotalExcludingTax AS Warehouse_TotalExcludingTax,
                    FT.TaxAmount AS Warehouse_TaxAmount,
                    FT.TotalIncludingTax AS Warehouse_TotalIncludingTax,
                    FT.OutstandingBalance AS Warehouse_OutstandingBalance,
                    FT.IsFinalized AS Warehouse_IsFinalized,
                    FT.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ FctTransactions }} FT LEFT JOIN
                    {{ DimCustomers }} DC ON
                        FT.CustomerKey = DC.CustomerKey LEFT JOIN
                    {{ DimCustomers }} BDC ON
                        FT.BillToCustomerKey = BDC.CustomerKey LEFT JOIN
                    {{ DimSuppliers }} DS ON
                        FT.SupplierKey = DS.SupplierKey LEFT JOIN
                    {{ DimTransactionTypes }} DTS ON
                        FT.TransactionTypeKey = DTS.TransactionTypeKey LEFT JOIN
                    {{ DimPaymentMethods }} DPM ON
                        FT.PaymentMethodKey = DPM.PaymentMethodKey
                WHERE 
                    FT.LoadDate = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    CT.TransactionDate AS Original_DateKey,
                    CT.CustomerTransactionID AS Original_WWICustomerTransactionID,
                    CAST(NULL AS INTEGER) AS Original_WWISupplierTransactionID,
                    CT.InvoiceID AS Original_WWIInvoiceID,
                    CAST(NULL AS INTEGER) AS Original_WWIPurchaseOrderID,
                    C.CustomerID AS Original_WWICustomerID,
                    BC.CustomerID AS Original_WWIBillToCustomerID,
                    CAST(NULL AS INTEGER) AS Original_WWISupplierID,
                    TT.TransactionTypeID AS Original_WWITransactionTypeID,
                    PM.PaymentMethodID AS Original_WWIPaymentMethodID,
                    CAST(NULL AS STRING) AS Original_SupplierInvoiceNumber,
                    CT.AmountExcludingTax AS Original_TotalExcludingTax,
                    CT.TaxAmount AS Original_TaxAmount,
                    CT.TransactionAmount AS Original_TotalIncludingTax,
                    CT.OutstandingBalance AS Original_OutstandingBalance,
                    CT.IsFinalized AS Original_IsFinalized,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ SalesCustomerTransactions }} CT LEFT JOIN
                    {{ SalesInvoices }} I ON
                        I.InvoiceID = CT.InvoiceID LEFT JOIN
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
                        C.CustomerID = COALESCE(I.CustomerID, CT.CustomerID) LEFT JOIN
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
                    ) BC ON
                        BC.CustomerID = COALESCE(I.CustomerID, CT.CustomerID) LEFT JOIN
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
                        TT.TransactionTypeID = CT.TransactionTypeID LEFT JOIN
                    (
                        SELECT
                            PM.PaymentMethodID,
                            PM.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethods }} PM 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PM.ValidFrom AND PM.ValidTo

                        UNION ALL

                        SELECT
                            PMA.PaymentMethodID,
                            PMA.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethodsArchive }} PMA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PMA.ValidFrom AND PMA.ValidTo
                    ) PM ON
                        PM.PaymentMethodID = CT.PaymentMethodID
                WHERE
                    CT.LastEditedWhen > '<< LastCutoffDate >>' AND
                    CT.LastEditedWhen <= '<< NewCutoffDate >>'

                UNION ALL

                SELECT
                    ST.TransactionDate AS Original_DateKey,
                    CAST(NULL AS INTEGER) AS Original_WWICustomerTransactionID,
                    ST.SupplierTransactionID AS Original_WWISupplierTransactionID,
                    CAST(NULL AS INTEGER) AS Original_WWIInvoiceID,
                    ST.PurchaseOrderID AS Original_WWIPurchaseOrderID,
                    CAST(NULL AS INTEGER) AS Original_WWICustomerID,
                    CAST(NULL AS INTEGER) AS Original_WWIBillToCustomerID,
                    S.SupplierID AS Original_WWISupplierID,
                    TT.TransactionTypeID AS Original_WWITransactionTypeID,
                    PM.PaymentMethodID AS Original_WWIPaymentMethodID,
                    ST.SupplierInvoiceNumber AS Original_SupplierInvoiceNumber,
                    ST.AmountExcludingTax AS Original_TotalExcludingTax,
                    ST.TaxAmount AS Original_TaxAmount,
                    ST.TransactionAmount AS Original_TotalIncludingTax,
                    ST.OutstandingBalance AS Original_OutstandingBalance,
                    ST.IsFinalized AS Original_IsFinalized,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ PurchasingSupplierTransactions }} ST LEFT JOIN
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
                        S.SupplierID = ST.SupplierID LEFT JOIN
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
                        TT.TransactionTypeID = ST.TransactionTypeID LEFT JOIN
                    (
                        SELECT
                            PM.PaymentMethodID,
                            PM.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethods }} PM 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PM.ValidFrom AND PM.ValidTo

                        UNION ALL

                        SELECT
                            PMA.PaymentMethodID,
                            PMA.PaymentMethodName
                        FROM
                            {{ ApplicationPaymentMethodsArchive }} PMA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PMA.ValidFrom AND PMA.ValidTo
                    ) PM ON
                        PM.PaymentMethodID = ST.PaymentMethodID
                WHERE
                    ST.LastEditedWhen > '<< LastCutoffDate >>' AND
                    ST.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                IFNULL(WD.Warehouse_WWICustomerTransactionID, 0) = IFNULL(TD.Original_WWICustomerTransactionID, 0) AND
                IFNULL(WD.Warehouse_WWISupplierTransactionID, 0) = IFNULL(TD.Original_WWISupplierTransactionID, 0)
        WHERE 
            (
                WD.Warehouse_WWICustomerTransactionID IS NULL AND
                WD.Warehouse_WWISupplierTransactionID IS NULL
            ) OR 
            (
                TD.Original_WWICustomerTransactionID IS NULL AND
                TD.Original_WWISupplierTransactionID IS NULL
            ) OR 
            ( 
                (
                    WD.Warehouse_WWICustomerTransactionID IS NOT NULL OR
                    WD.Warehouse_WWISupplierTransactionID IS NOT NULL
                ) AND 
                (
                    TD.Original_WWICustomerTransactionID IS NOT NULL OR
                    TD.Original_WWISupplierTransactionID IS NOT NULL
                ) AND 
                (
                    WD.Warehouse_DateKey != TD.Original_DateKey OR
                    WD.Warehouse_WWIInvoiceID != TD.Original_WWIInvoiceID OR
                    WD.Warehouse_WWIPurchaseOrderID != TD.Original_WWIPurchaseOrderID OR
                    WD.Warehouse_WWICustomerID != TD.Original_WWICustomerID OR
                    WD.Warehouse_WWIBillToCustomerID != TD.Original_WWIBillToCustomerID OR
                    WD.Warehouse_WWISupplierID != TD.Original_WWISupplierID OR
                    WD.Warehouse_WWITransactionTypeID != TD.Original_WWITransactionTypeID OR
                    WD.Warehouse_WWIPaymentMethodID != TD.Original_WWIPaymentMethodID OR
                    WD.Warehouse_SupplierInvoiceNumber != TD.Original_SupplierInvoiceNumber OR
                    WD.Warehouse_TotalExcludingTax != TD.Original_TotalExcludingTax OR
                    WD.Warehouse_TaxAmount != TD.Original_TaxAmount OR
                    WD.Warehouse_TotalIncludingTax != TD.Original_TotalIncludingTax OR
                    WD.Warehouse_OutstandingBalance != TD.Original_OutstandingBalance OR
                    WD.Warehouse_IsFinalized != TD.Original_IsFinalized OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate
                )
            )
    ) R