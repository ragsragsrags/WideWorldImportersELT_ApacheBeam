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
                    WHEN WD.Warehouse_WWIInvoiceID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWIInvoiceID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_InvoiceDateKey] = FS.[InvoiceDateKey],
                    [Warehouse_DeliveryDateKey] = FS.[DeliveryDateKey],
                    [Warehouse_WWIInvoiceID] = FS.[WWIInvoiceID],
                    [Warehouse_WWIInvoiceLineID] = FS.[WWIInvoiceLineID],
                    [Warehouse_WWICityID] = DC.[WWICityID],
                    [Warehouse_WWICustomerID] = DCU.[WWICustomerID],
                    [Warehouse_WWIBillToCustomerID] = BDCU.[WWICustomerID],
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_WWISalesPersonID] = DE.[WWIEmployeeID],
                    [Warehouse_Description] = FS.[Description],
                    [Warehouse_Package] = FS.[Package],
                    [Warehouse_Quantity] = FS.[Quantity],
                    [Warehouse_UnitPrice] = FS.[UnitPrice],
                    [Warehouse_TaxRate] = FS.[TaxRate],
                    [Warehouse_TotalExcludingTax] = FS.[TotalExcludingTax],
                    [Warehouse_TaxAmount] = FS.[TaxAmount],
                    [Warehouse_Profit] = FS.[Profit],
                    [Warehouse_TotalIncludingTax] = FS.[TotalIncludingTax],
                    [Warehouse_TotalDryItems] = FS.[TotalDryItems],
                    [Warehouse_TotalChillerItems] = FS.[TotalChillerItems],
                    [Warehouse_LoadDate] = FS.[LoadDate]
                FROM 
                    {{ FctSales }} FS LEFT JOIN
                    {{ DimCities }} DC ON
                        FS.CityKey = DC.CityKey LEFT JOIN
                    {{ DimCustomers }} DCU ON
                        FS.CustomerKey = DCU.CustomerKey LEFT JOIN
                    {{ DimCustomers }} BDCU ON
                        FS.BillToCustomerKey = BDCU.CustomerKey LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FS.StockItemKey = DSI.StockItemKey LEFT JOIN
                    {{ DimEmployees }} DE ON
                        FS.SalesPersonKey = DE.EmployeeKey 
                WHERE 
                    FS.[LoadDate] = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_InvoiceDateKey] = CAST(I.InvoiceDate AS DATE),
                    [Original_DeliveryDateKey] = CAST(I.ConfirmedDeliveryTime AS DATE),
                    [Original_WWIInvoiceID] = I.InvoiceID,
                    [Original_WWIInvoiceLineID] = IL.InvoiceLineID,
                    [Original_WWICityID] = C.CityID,
                    [Original_WWICustomerID] = CU.CustomerID,
                    [Original_WWIBillToCustomerID] = BCU.CustomerID,
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_WWISalesPersonID] = I.SalespersonPersonID,
                    [Original_Description] = IL.Description,
                    [Original_Package] = PT.PackageTypeName,
                    [Original_Quantity] = IL.Quantity,
                    [Original_UnitPrice] = IL.UnitPrice,
                    [Original_TaxRate] = IL.TaxRate,
                    [Original_TotalExcludingTax] = IL.ExtendedPrice - IL.TaxAmount,
                    [Original_TaxAmount] = IL.TaxAmount,
                    [Original_Profit] = IL.LineProfit,
                    [Original_TotalIncludingTax] = IL.ExtendedPrice,
                    [Original_TotalDryItems] =
                        CASE 
                            WHEN SI.IsChillerStock = 0 THEN IL.Quantity 
                            ELSE 0 
                        END,
                    [Original_TotalChillerItems] = 
                        CASE 
                            WHEN SI.IsChillerStock <> 0 THEN IL.Quantity 
                            ELSE 0 
                        END,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    {{ SalesInvoices }} I LEFT JOIN
                    {{ SalesInvoiceLines }} IL ON
                        IL.InvoiceID = I.InvoiceID LEFT JOIN
                    (
                        SELECT
                            C.CustomerID,
                            C.CustomerName,
                            C.DeliveryCityID
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CustomerID,
                            CA.CustomerName,
                            CA.DeliveryCityID
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) CU ON
                        CU.CustomerID = I.CustomerID LEFT JOIN
                    (
                        SELECT
                            C.CityID,
                            C.CityName
                        FROM
                            {{ ApplicationCities }} C
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CityID,
                            CA.CityName
                        FROM
                            {{ ApplicationCitiesArchive }} CA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON
                        C.CityID = CU.DeliveryCityID LEFT JOIN
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
                    ) BCU ON
                        BCU.CustomerID = I.BillToCustomerID LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName,
                            SI.IsChillerStock
                        FROM
                            {{ WarehouseStockItems }} SI
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName,
                            SIA.IsChillerStock
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = IL.StockItemID LEFT JOIN
                    (
                        SELECT
                            P.PersonID,
                            P.FullName
                        FROM
                            {{ ApplicationPeople }} P
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN P.ValidFrom AND P.ValidTo

                        UNION ALL

                        SELECT
                            PA.PersonID,
                            PA.FullName
                        FROM
                            {{ ApplicationPeopleArchive }} PA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PA.ValidFrom AND PA.ValidTo
                    ) SP ON
                        SP.PersonID = I.SalespersonPersonID LEFT JOIN
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
                            {{ WarehousePackageTypesArchive }} PTA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom AND PTA.ValidTo
                    ) PT ON
                        PT.PackageTypeID = IL.PackageTypeID
                WHERE
                    (
			            I.LastEditedWhen > ''<< LastCutoffDate >>'' OR
			            IL.LastEditedWhen > ''<< LastCutoffDate >>'' OR
			            IL.PackageTypeID IN (
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
		                        ''<< NewCutoffDate >>'' BETWEEN PTA.ValidFrom  AND PTA.ValidTo
			            ) OR
			            IL.StockItemID IN (
				            SELECT
		                        ST.StockItemID
	                        FROM
		                        {{ WarehouseStockItems }} ST
	                        WHERE
		                        ST.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN ST.ValidFrom  AND ST.ValidTo

	                        UNION ALL

	                        SELECT
		                        SIA.StockItemID
	                        FROM
		                        {{ WarehouseStockItemsArchive }} SIA
	                        WHERE
		                        SIA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN SIA.ValidFrom AND SIA.ValidTo
			            ) 
		            ) AND
		            I.LastEditedWhen <= ''<< NewCutoffDate >>'' AND
		            IL.LastEditedWhen <= ''<< NewCutoffDate >>''
            ) TD ON 
                WD.[Warehouse_WWIInvoiceID] = TD.[Original_WWIInvoiceID] AND
                WD.[Warehouse_WWIInvoiceLineID] = TD.[Original_WWIInvoiceLineID]
        WHERE 
            WD.Warehouse_WWIInvoiceID IS NULL OR 
            TD.Original_WWIInvoiceID IS NULL OR 
            ( 
                WD.Warehouse_WWIInvoiceID IS NOT NULL AND 
                TD.Original_WWIInvoiceID IS NOT NULL AND 
                (
                    WD.[Warehouse_InvoiceDateKey] != TD.[Original_InvoiceDateKey] OR
                    WD.[Warehouse_DeliveryDateKey] != TD.[Original_DeliveryDateKey] OR
                    WD.[Warehouse_WWICityID] != TD.[Original_WWICityID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWIBillToCustomerID] != TD.[Original_WWIBillToCustomerID] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_WWISalesPersonID] != TD.[Original_WWISalesPersonID] OR
                    WD.[Warehouse_Description] != TD.[Original_Description] OR
                    WD.[Warehouse_Package] != TD.[Original_Package] OR
                    WD.[Warehouse_Quantity] != TD.[Original_Quantity] OR
                    WD.[Warehouse_UnitPrice] != TD.[Original_UnitPrice] OR
                    WD.[Warehouse_TaxRate] != TD.[Original_TaxRate] OR
                    WD.[Warehouse_TotalExcludingTax] != TD.[Original_TotalExcludingTax] OR
                    WD.[Warehouse_TaxAmount] != TD.[Original_TaxAmount] OR
                    WD.[Warehouse_Profit] != TD.[Original_Profit] OR
                    WD.[Warehouse_TotalIncludingTax] != TD.[Original_TotalIncludingTax] OR
                    WD.[Warehouse_TotalDryItems] != TD.[Original_TotalDryItems] OR
                    WD.[Warehouse_TotalChillerItems] != TD.[Original_TotalChillerItems] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                )
            )
    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIInvoiceID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWIInvoiceID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_InvoiceDateKey] = FS.[InvoiceDateKey],
                    [Warehouse_DeliveryDateKey] = FS.[DeliveryDateKey],
                    [Warehouse_WWIInvoiceID] = FS.[WWIInvoiceID],
                    [Warehouse_WWIInvoiceLineID] = FS.[WWIInvoiceLineID],
                    [Warehouse_WWICityID] = DC.[WWICityID],
                    [Warehouse_WWICustomerID] = DCU.[WWICustomerID],
                    [Warehouse_WWIBillToCustomerID] = BDCU.[WWICustomerID],
                    [Warehouse_WWIStockItemID] = DSI.[WWIStockItemID],
                    [Warehouse_WWISalesPersonID] = DE.[WWIEmployeeID],
                    [Warehouse_Description] = FS.[Description],
                    [Warehouse_Package] = FS.[Package],
                    [Warehouse_Quantity] = FS.[Quantity],
                    [Warehouse_UnitPrice] = FS.[UnitPrice],
                    [Warehouse_TaxRate] = FS.[TaxRate],
                    [Warehouse_TotalExcludingTax] = FS.[TotalExcludingTax],
                    [Warehouse_TaxAmount] = FS.[TaxAmount],
                    [Warehouse_Profit] = FS.[Profit],
                    [Warehouse_TotalIncludingTax] = FS.[TotalIncludingTax],
                    [Warehouse_TotalDryItems] = FS.[TotalDryItems],
                    [Warehouse_TotalChillerItems] = FS.[TotalChillerItems],
                    [Warehouse_LoadDate] = FS.[LoadDate]
                FROM 
                    {{ FctSales }} FS LEFT JOIN
                    {{ DimCities }} DC ON
                        FS.CityKey = DC.CityKey LEFT JOIN
                    {{ DimCustomers }} DCU ON
                        FS.CustomerKey = DCU.CustomerKey LEFT JOIN
                    {{ DimCustomers }} BDCU ON
                        FS.BillToCustomerKey = BDCU.CustomerKey LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FS.StockItemKey = DSI.StockItemKey LEFT JOIN
                    {{ DimEmployees }} DE ON
                        FS.SalesPersonKey = DE.EmployeeKey 
                WHERE 
                    FS.[LoadDate] = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_InvoiceDateKey] = CAST(I.InvoiceDate AS DATE),
                    [Original_DeliveryDateKey] = CAST(I.ConfirmedDeliveryTime AS DATE),
                    [Original_WWIInvoiceID] = I.InvoiceID,
                    [Original_WWIInvoiceLineID] = IL.InvoiceLineID,
                    [Original_WWICityID] = C.CityID,
                    [Original_WWICustomerID] = CU.CustomerID,
                    [Original_WWIBillToCustomerID] = BCU.CustomerID,
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_WWISalesPersonID] = I.SalespersonPersonID,
                    [Original_Description] = IL.Description,
                    [Original_Package] = PT.PackageTypeName,
                    [Original_Quantity] = IL.Quantity,
                    [Original_UnitPrice] = IL.UnitPrice,
                    [Original_TaxRate] = IL.TaxRate,
                    [Original_TotalExcludingTax] = IL.ExtendedPrice - IL.TaxAmount,
                    [Original_TaxAmount] = IL.TaxAmount,
                    [Original_Profit] = IL.LineProfit,
                    [Original_TotalIncludingTax] = IL.ExtendedPrice,
                    [Original_TotalDryItems] =
                        CASE 
                            WHEN SI.IsChillerStock = 0 THEN IL.Quantity 
                            ELSE 0 
                        END,
                    [Original_TotalChillerItems] = 
                        CASE 
                            WHEN SI.IsChillerStock <> 0 THEN IL.Quantity 
                            ELSE 0 
                        END,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    {{ SalesInvoices }} I LEFT JOIN
                    {{ SalesInvoiceLines }} IL ON
                        IL.InvoiceID = I.InvoiceID LEFT JOIN
                    (
                        SELECT
                            C.CustomerID,
                            C.CustomerName,
                            C.DeliveryCityID
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CustomerID,
                            CA.CustomerName,
                            CA.DeliveryCityID
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) CU ON
                        CU.CustomerID = I.CustomerID LEFT JOIN
                    (
                        SELECT
                            C.CityID,
                            C.CityName
                        FROM
                            {{ ApplicationCities }} C
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CityID,
                            CA.CityName
                        FROM
                            {{ ApplicationCitiesArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON
                        C.CityID = CU.DeliveryCityID LEFT JOIN
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
                    ) BCU ON
                        BCU.CustomerID = I.BillToCustomerID LEFT JOIN
                    (
                        SELECT
                            SI.StockItemID,
                            SI.StockItemName,
                            SI.IsChillerStock
                        FROM
                            {{ WarehouseStockItems }} SI
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SI.ValidFrom AND SI.ValidTo

                        UNION ALL

                        SELECT
                            SIA.StockItemID,
                            SIA.StockItemName,
                            SIA.IsChillerStock
                        FROM
                            {{ WarehouseStockItemsArchive }} SIA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
                    ) SI ON
                        SI.StockItemID = IL.StockItemID LEFT JOIN
                    (
                        SELECT
                            P.PersonID,
                            P.FullName
                        FROM
                            {{ ApplicationPeople }} P
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo

                        UNION ALL

                        SELECT
                            PA.PersonID,
                            PA.FullName
                        FROM
                            {{ ApplicationPeopleArchive }} PA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo
                    ) SP ON
                        SP.PersonID = I.SalespersonPersonID LEFT JOIN
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
                            {{ WarehousePackageTypesArchive }} PTA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo
                    ) PT ON
                        PT.PackageTypeID = IL.PackageTypeID
                WHERE
                    (
			            I.LastEditedWhen > '<< LastCutoffDate >>' OR
			            IL.LastEditedWhen > '<< LastCutoffDate >>' OR
			            IL.PackageTypeID IN (
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
		                        '<< NewCutoffDate >>' BETWEEN PTA.ValidFrom  AND PTA.ValidTo
			            ) OR
			            IL.StockItemID IN (
				            SELECT
		                        ST.StockItemID
	                        FROM
		                        {{ WarehouseStockItems }} ST
	                        WHERE
		                        ST.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN ST.ValidFrom  AND ST.ValidTo

	                        UNION ALL

	                        SELECT
		                        SIA.StockItemID
	                        FROM
		                        {{ WarehouseStockItemsArchive }} SIA
	                        WHERE
		                        SIA.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN SIA.ValidFrom AND SIA.ValidTo
			            ) 
		            ) AND
		            I.LastEditedWhen <= '<< NewCutoffDate >>' AND
		            IL.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                WD.[Warehouse_WWIInvoiceID] = TD.[Original_WWIInvoiceID] AND
                WD.[Warehouse_WWIInvoiceLineID] = TD.[Original_WWIInvoiceLineID]
        WHERE 
            WD.Warehouse_WWIInvoiceID IS NULL OR 
            TD.Original_WWIInvoiceID IS NULL OR 
            ( 
                WD.Warehouse_WWIInvoiceID IS NOT NULL AND 
                TD.Original_WWIInvoiceID IS NOT NULL AND 
                (
                    WD.[Warehouse_InvoiceDateKey] != TD.[Original_InvoiceDateKey] OR
                    WD.[Warehouse_DeliveryDateKey] != TD.[Original_DeliveryDateKey] OR
                    WD.[Warehouse_WWICityID] != TD.[Original_WWICityID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWIBillToCustomerID] != TD.[Original_WWIBillToCustomerID] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_WWISalesPersonID] != TD.[Original_WWISalesPersonID] OR
                    WD.[Warehouse_Description] != TD.[Original_Description] OR
                    WD.[Warehouse_Package] != TD.[Original_Package] OR
                    WD.[Warehouse_Quantity] != TD.[Original_Quantity] OR
                    WD.[Warehouse_UnitPrice] != TD.[Original_UnitPrice] OR
                    WD.[Warehouse_TaxRate] != TD.[Original_TaxRate] OR
                    WD.[Warehouse_TotalExcludingTax] != TD.[Original_TotalExcludingTax] OR
                    WD.[Warehouse_TaxAmount] != TD.[Original_TaxAmount] OR
                    WD.[Warehouse_Profit] != TD.[Original_Profit] OR
                    WD.[Warehouse_TotalIncludingTax] != TD.[Original_TotalIncludingTax] OR
                    WD.[Warehouse_TotalDryItems] != TD.[Original_TotalDryItems] OR
                    WD.[Warehouse_TotalChillerItems] != TD.[Original_TotalChillerItems] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                )
            )
    ) R