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
                    WHEN (
                        WD.Warehouse_WWICustomerTransactionID IS NULL AND
                        WD.[Warehouse_WWISupplierTransactionID] IS NULL
                    ) THEN ''Missing in warehouse data'' 
                    WHEN (
                        TD.Original_WWICustomerTransactionID IS NULL AND
                        TD.Original_WWISupplierTransactionID IS NULL
                    ) THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_DateKey] = FT.[DateKey],
                    [Warehouse_WWICustomerTransactionID] = FT.[WWICustomerTransactionID],
                    [Warehouse_WWISupplierTransactionID] = FT.[WWISupplierTransactionID],
                    [Warehouse_WWIInvoiceID] = FT.[WWIInvoiceID],
                    [Warehouse_WWIPurchaseOrderID] = FT.[WWIPurchaseOrderID],
                    [Warehouse_WWICustomerID] = DC.[WWICustomerID],
                    [Warehouse_WWIBillToCustomerID] = BDC.[WWICustomerID],
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_WWITransactionTypeID] = DTS.[WWITransactionTypeID],
                    [Warehouse_WWIPaymentMethodID] = DPM.[WWIPaymentMethodID],
                    [Warehouse_SupplierInvoiceNumber] = FT.[SupplierInvoiceNumber],
                    [Warehouse_TotalExcludingTax] = FT.[TotalExcludingTax],
                    [Warehouse_TaxAmount] = FT.[TaxAmount],
                    [Warehouse_TotalIncludingTax] = FT.[TotalIncludingTax],
                    [Warehouse_OutstandingBalance] = FT.[OutstandingBalance],
                    [Warehouse_IsFinalized] = FT.[IsFinalized],
                    [Warehouse_LoadDate] = FT.[LoadDate]
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
                    FT.[LoadDate] = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_DateKey] = CT.TransactionDate,
                    [Original_WWICustomerTransactionID] = CT.CustomerTransactionID,
                    [Original_WWISupplierTransactionID] = CAST(NULL AS INTEGER),
                    [Original_WWIInvoiceID] = CT.InvoiceID,
                    [Original_WWIPurchaseOrderID] = CAST(NULL AS INTEGER),
                    [Original_WWICustomerID] = C.CustomerID,
                    [Original_WWIBillToCustomerID] = BC.CustomerID,
                    [Original_WWISupplierID] = CAST(NULL AS INTEGER),
                    [Original_WWITransactionTypeID] = TT.TransactionTypeID,
                    [Original_WWIPaymentMethodID] = PM.PaymentMethodID,
                    [Original_SupplierInvoiceNumber] = CAST(NULL AS NVARCHAR(50)),
                    [Original_TotalExcludingTax] = CT.AmountExcludingTax,
                    [Original_TaxAmount] = CT.TaxAmount,
                    [Original_TotalIncludingTax] = CT.TransactionAmount,
                    [Original_OutstandingBalance] = CT.OutstandingBalance,
                    [Original_IsFinalized] = CT.IsFinalized,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
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
                        BC.CustomerID = CT.CustomerID LEFT JOIN
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
                    [Original_DateKey] = ST.TransactionDate,
                    [Original_WWICustomerTransactionID] = CAST(NULL AS INTEGER),
                    [Original_WWISupplierTransactionID] = ST.SupplierTransactionID,
                    [Original_WWIInvoiceID] = CAST(NULL AS INTEGER),
                    [Original_WWIPurchaseOrderID] = ST.PurchaseOrderID,
                    [Original_WWICustomerID] = CAST(NULL AS INTEGER),
                    [Original_WWIBillToCustomerID] = CAST(NULL AS INTEGER),
                    [Original_WWISupplierID] = S.SupplierID,
                    [Original_WWITransactionTypeID] = TT.TransactionTypeID,
                    [Original_WWIPaymentMethodID] = PM.PaymentMethodID,
                    [Original_SupplierInvoiceNumber] =ST.SupplierInvoiceNumber,
                    [Original_TotalExcludingTax] = ST.AmountExcludingTax,
                    [Original_TaxAmount] = ST.TaxAmount,
                    [Original_TotalIncludingTax] = ST.TransactionAmount,
                    [Original_OutstandingBalance] = ST.OutstandingBalance,
                    [Original_IsFinalized] = ST.IsFinalized,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
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
                ISNULL(WD.[Warehouse_WWICustomerTransactionID], 0) = ISNULL(TD.[Original_WWICustomerTransactionID], 0) AND
                ISNULL(WD.[Warehouse_WWISupplierTransactionID], 0) = ISNULL(TD.[Original_WWISupplierTransactionID], 0)
        WHERE 
            (
                WD.Warehouse_WWICustomerTransactionID IS NULL AND
                WD.[Warehouse_WWISupplierTransactionID] IS NULL
            ) OR 
            (
                TD.Original_WWICustomerTransactionID IS NULL AND
                TD.Original_WWISupplierTransactionID IS NULL
            ) OR 
            ( 
                (
                    WD.Warehouse_WWICustomerTransactionID IS NOT NULL OR
                    WD.[Warehouse_WWISupplierTransactionID] IS NOT NULL
                ) AND 
                (
                    TD.Original_WWICustomerTransactionID IS NOT NULL OR
                    TD.Original_WWISupplierTransactionID IS NOT NULL
                ) AND 
                (
                    WD.[Warehouse_DateKey] != TD.[Original_DateKey] OR
                    WD.[Warehouse_WWIInvoiceID] != TD.[Original_WWIInvoiceID] OR
                    WD.[Warehouse_WWIPurchaseOrderID] != TD.[Original_WWIPurchaseOrderID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWIBillToCustomerID] != TD.[Original_WWIBillToCustomerID] OR
                    WD.[Warehouse_WWISupplierID] != TD.[Original_WWISupplierID] OR
                    WD.[Warehouse_WWITransactionTypeID] != TD.[Original_WWITransactionTypeID] OR
                    WD.[Warehouse_WWIPaymentMethodID] != TD.[Original_WWIPaymentMethodID] OR
                    WD.[Warehouse_SupplierInvoiceNumber] != TD.[Original_SupplierInvoiceNumber] OR
                    WD.[Warehouse_TotalExcludingTax] != TD.[Original_TotalExcludingTax] OR
                    WD.[Warehouse_TaxAmount] != TD.[Original_TaxAmount] OR
                    WD.[Warehouse_TotalIncludingTax] != TD.[Original_TotalIncludingTax] OR
                    WD.[Warehouse_OutstandingBalance] != TD.[Original_OutstandingBalance] OR
                    WD.[Warehouse_IsFinalized] != TD.[Original_IsFinalized] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                )
            )
    ', CHAR(10), ''), CHAR(9), ' ')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN (
                        WD.Warehouse_WWICustomerTransactionID IS NULL AND
                        WD.[Warehouse_WWISupplierTransactionID] IS NULL
                    ) THEN 'Missing in warehouse data' 
                    WHEN (
                        TD.Original_WWICustomerTransactionID IS NULL AND
                        TD.Original_WWISupplierTransactionID IS NULL
                    ) THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_DateKey] = FT.[DateKey],
                    [Warehouse_WWICustomerTransactionID] = FT.[WWICustomerTransactionID],
                    [Warehouse_WWISupplierTransactionID] = FT.[WWISupplierTransactionID],
                    [Warehouse_WWIInvoiceID] = FT.[WWIInvoiceID],
                    [Warehouse_WWIPurchaseOrderID] = FT.[WWIPurchaseOrderID],
                    [Warehouse_WWICustomerID] = DC.[WWICustomerID],
                    [Warehouse_WWIBillToCustomerID] = BDC.[WWICustomerID],
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_WWITransactionTypeID] = DTS.[WWITransactionTypeID],
                    [Warehouse_WWIPaymentMethodID] = DPM.[WWIPaymentMethodID],
                    [Warehouse_SupplierInvoiceNumber] = FT.[SupplierInvoiceNumber],
                    [Warehouse_TotalExcludingTax] = FT.[TotalExcludingTax],
                    [Warehouse_TaxAmount] = FT.[TaxAmount],
                    [Warehouse_TotalIncludingTax] = FT.[TotalIncludingTax],
                    [Warehouse_OutstandingBalance] = FT.[OutstandingBalance],
                    [Warehouse_IsFinalized] = FT.[IsFinalized],
                    [Warehouse_LoadDate] = FT.[LoadDate]
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
                    FT.[LoadDate] = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_DateKey] = CT.TransactionDate,
                    [Original_WWICustomerTransactionID] = CT.CustomerTransactionID,
                    [Original_WWISupplierTransactionID] = CAST(NULL AS INTEGER),
                    [Original_WWIInvoiceID] = CT.InvoiceID,
                    [Original_WWIPurchaseOrderID] = CAST(NULL AS INTEGER),
                    [Original_WWICustomerID] = C.CustomerID,
                    [Original_WWIBillToCustomerID] = BC.CustomerID,
                    [Original_WWISupplierID] = CAST(NULL AS INTEGER),
                    [Original_WWITransactionTypeID] = TT.TransactionTypeID,
                    [Original_WWIPaymentMethodID] = PM.PaymentMethodID,
                    [Original_SupplierInvoiceNumber] = CAST(NULL AS NVARCHAR(50)),
                    [Original_TotalExcludingTax] = CT.AmountExcludingTax,
                    [Original_TaxAmount] = CT.TaxAmount,
                    [Original_TotalIncludingTax] = CT.TransactionAmount,
                    [Original_OutstandingBalance] = CT.OutstandingBalance,
                    [Original_IsFinalized] = CT.IsFinalized,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
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
                    [Original_DateKey] = ST.TransactionDate,
                    [Original_WWICustomerTransactionID] = CAST(NULL AS INTEGER),
                    [Original_WWISupplierTransactionID] = ST.SupplierTransactionID,
                    [Original_WWIInvoiceID] = CAST(NULL AS INTEGER),
                    [Original_WWIPurchaseOrderID] = ST.PurchaseOrderID,
                    [Original_WWICustomerID] = CAST(NULL AS INTEGER),
                    [Original_WWIBillToCustomerID] = CAST(NULL AS INTEGER),
                    [Original_WWISupplierID] = S.SupplierID,
                    [Original_WWITransactionTypeID] = TT.TransactionTypeID,
                    [Original_WWIPaymentMethodID] = PM.PaymentMethodID,
                    [Original_SupplierInvoiceNumber] =ST.SupplierInvoiceNumber,
                    [Original_TotalExcludingTax] = ST.AmountExcludingTax,
                    [Original_TaxAmount] = ST.TaxAmount,
                    [Original_TotalIncludingTax] = ST.TransactionAmount,
                    [Original_OutstandingBalance] = ST.OutstandingBalance,
                    [Original_IsFinalized] = ST.IsFinalized,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
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
                ISNULL(WD.[Warehouse_WWICustomerTransactionID], 0) = ISNULL(TD.[Original_WWICustomerTransactionID], 0) AND
                ISNULL(WD.[Warehouse_WWISupplierTransactionID], 0) = ISNULL(TD.[Original_WWISupplierTransactionID], 0)
        WHERE 
            (
                WD.Warehouse_WWICustomerTransactionID IS NULL AND
                WD.[Warehouse_WWISupplierTransactionID] IS NULL
            ) OR 
            (
                TD.Original_WWICustomerTransactionID IS NULL AND
                TD.Original_WWISupplierTransactionID IS NULL
            ) OR 
            ( 
                (
                    WD.Warehouse_WWICustomerTransactionID IS NOT NULL OR
                    WD.[Warehouse_WWISupplierTransactionID] IS NOT NULL
                ) AND 
                (
                    TD.Original_WWICustomerTransactionID IS NOT NULL OR
                    TD.Original_WWISupplierTransactionID IS NOT NULL
                ) AND 
                (
                    WD.[Warehouse_DateKey] != TD.[Original_DateKey] OR
                    WD.[Warehouse_WWIInvoiceID] != TD.[Original_WWIInvoiceID] OR
                    WD.[Warehouse_WWIPurchaseOrderID] != TD.[Original_WWIPurchaseOrderID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWIBillToCustomerID] != TD.[Original_WWIBillToCustomerID] OR
                    WD.[Warehouse_WWISupplierID] != TD.[Original_WWISupplierID] OR
                    WD.[Warehouse_WWITransactionTypeID] != TD.[Original_WWITransactionTypeID] OR
                    WD.[Warehouse_WWIPaymentMethodID] != TD.[Original_WWIPaymentMethodID] OR
                    WD.[Warehouse_SupplierInvoiceNumber] != TD.[Original_SupplierInvoiceNumber] OR
                    WD.[Warehouse_TotalExcludingTax] != TD.[Original_TotalExcludingTax] OR
                    WD.[Warehouse_TaxAmount] != TD.[Original_TaxAmount] OR
                    WD.[Warehouse_TotalIncludingTax] != TD.[Original_TotalIncludingTax] OR
                    WD.[Warehouse_OutstandingBalance] != TD.[Original_OutstandingBalance] OR
                    WD.[Warehouse_IsFinalized] != TD.[Original_IsFinalized] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                )
            )
    ) R