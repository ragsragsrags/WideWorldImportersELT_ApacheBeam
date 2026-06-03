SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE(REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWIInvoiceID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWIInvoiceID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FS.InvoiceDateKey AS Warehouse_InvoiceDateKey,
                    FS.DeliveryDateKey AS Warehouse_DeliveryDateKey,
                    FS.WWIInvoiceID AS Warehouse_WWIInvoiceID,
                    FS.WWIInvoiceLineID AS Warehouse_WWIInvoiceLineID,
                    DC.WWICityID AS Warehouse_WWICityID,
                    DCU.WWICustomerID AS Warehouse_WWICustomerID,
                    BDCU.WWICustomerID AS Warehouse_WWIBillToCustomerID,
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    DE.WWIEmployeeID AS Warehouse_WWISalesPersonID,
                    FS.Description AS Warehouse_Description,
                    FS.Package AS Warehouse_Package,
                    FS.Quantity AS Warehouse_Quantity,
                    FS.UnitPrice AS Warehouse_UnitPrice,
                    FS.TaxRate AS Warehouse_TaxRate,
                    FS.TotalExcludingTax AS Warehouse_TotalExcludingTax,
                    FS.TaxAmount AS Warehouse_TaxAmount,
                    FS.Profit AS Warehouse_Profit,
                    FS.TotalIncludingTax AS Warehouse_TotalIncludingTax,
                    FS.TotalDryItems AS Warehouse_TotalDryItems,
                    FS.TotalChillerItems AS Warehouse_TotalChillerItems,
                    FS.LoadDate AS Warehouse_LoadDate
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
                    FS.LoadDate = ''<< NewCutoffDate >>''
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    CAST(I.InvoiceDate AS DATE) AS Original_InvoiceDateKey,
                    CAST(I.ConfirmedDeliveryTime AS DATE) AS Original_DeliveryDateKey,
                    I.InvoiceID AS Original_WWIInvoiceID,
                    IL.InvoiceLineID AS Original_WWIInvoiceLineID,
                    C.CityID AS Original_WWICityID,
                    CU.CustomerID AS Original_WWICustomerID,
                    BCU.CustomerID AS Original_WWIBillToCustomerID,
                    SI.StockItemID AS Original_WWIStockItemID,
                    I.SalespersonPersonID AS Original_WWISalesPersonID,
                    IL.Description AS Original_Description,
                    PT.PackageTypeName AS Original_Package,
                    IL.Quantity AS Original_Quantity,
                    IL.UnitPrice AS Original_UnitPrice,
                    IL.TaxRate AS Original_TaxRate,
                    (IL.ExtendedPrice - IL.TaxAmount) AS Original_TotalExcludingTax,
                    IL.TaxAmount AS Original_TaxAmount,
                    IL.LineProfit AS Original_Profit,
                    IL.ExtendedPrice AS Original_TotalIncludingTax,
                    CASE 
                        WHEN SI.IsChillerStock = FALSE THEN IL.Quantity 
                        ELSE 0 
                    END AS Original_TotalDryItems,
                    CASE 
                        WHEN SI.IsChillerStock <> FALSE THEN IL.Quantity 
                        ELSE 0 
                    END AS Original_TotalChillerItems,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
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
                WD.Warehouse_WWIInvoiceID = TD.Original_WWIInvoiceID AND
                WD.Warehouse_WWIInvoiceLineID = TD.Original_WWIInvoiceLineID
        WHERE 
            WD.Warehouse_WWIInvoiceID IS NULL OR 
            TD.Original_WWIInvoiceID IS NULL OR 
            ( 
                WD.Warehouse_WWIInvoiceID IS NOT NULL AND 
                TD.Original_WWIInvoiceID IS NOT NULL AND 
                (
                    WD.Warehouse_InvoiceDateKey != TD.Original_InvoiceDateKey OR
                    WD.Warehouse_DeliveryDateKey != TD.Original_DeliveryDateKey OR
                    WD.Warehouse_WWICityID != TD.Original_WWICityID OR
                    WD.Warehouse_WWICustomerID != TD.Original_WWICustomerID OR
                    WD.Warehouse_WWIBillToCustomerID != TD.Original_WWIBillToCustomerID OR
                    WD.Warehouse_WWIStockItemID != TD.Original_WWIStockItemID OR
                    WD.Warehouse_WWISalesPersonID != TD.Original_WWISalesPersonID OR
                    WD.Warehouse_Description != TD.Original_Description OR
                    WD.Warehouse_Package != TD.Original_Package OR
                    WD.Warehouse_Quantity != TD.Original_Quantity OR
                    WD.Warehouse_UnitPrice != TD.Original_UnitPrice OR
                    WD.Warehouse_TaxRate != TD.Original_TaxRate OR
                    WD.Warehouse_TotalExcludingTax != TD.Original_TotalExcludingTax OR
                    WD.Warehouse_TaxAmount != TD.Original_TaxAmount OR
                    WD.Warehouse_Profit != TD.Original_Profit OR
                    WD.Warehouse_TotalIncludingTax != TD.Original_TotalIncludingTax OR
                    WD.Warehouse_TotalDryItems != TD.Original_TotalDryItems OR
                    WD.Warehouse_TotalChillerItems != TD.Original_TotalChillerItems OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate 
                )
            )
    ''', CHR(10), ' '), CHR(9), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWIInvoiceID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWIInvoiceID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    FS.InvoiceDateKey AS Warehouse_InvoiceDateKey,
                    FS.DeliveryDateKey AS Warehouse_DeliveryDateKey,
                    FS.WWIInvoiceID AS Warehouse_WWIInvoiceID,
                    FS.WWIInvoiceLineID AS Warehouse_WWIInvoiceLineID,
                    DC.WWICityID AS Warehouse_WWICityID,
                    DCU.WWICustomerID AS Warehouse_WWICustomerID,
                    BDCU.WWICustomerID AS Warehouse_WWIBillToCustomerID,
                    DSI.WWIStockItemID AS Warehouse_WWIStockItemID,
                    DE.WWIEmployeeID AS Warehouse_WWISalesPersonID,
                    FS.Description AS Warehouse_Description,
                    FS.Package AS Warehouse_Package,
                    FS.Quantity AS Warehouse_Quantity,
                    FS.UnitPrice AS Warehouse_UnitPrice,
                    FS.TaxRate AS Warehouse_TaxRate,
                    FS.TotalExcludingTax AS Warehouse_TotalExcludingTax,
                    FS.TaxAmount AS Warehouse_TaxAmount,
                    FS.Profit AS Warehouse_Profit,
                    FS.TotalIncludingTax AS Warehouse_TotalIncludingTax,
                    FS.TotalDryItems AS Warehouse_TotalDryItems,
                    FS.TotalChillerItems AS Warehouse_TotalChillerItems,
                    FS.LoadDate AS Warehouse_LoadDate
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
                    FS.LoadDate = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    CAST(I.InvoiceDate AS DATE) AS Original_InvoiceDateKey,
                    CAST(I.ConfirmedDeliveryTime AS DATE) AS Original_DeliveryDateKey,
                    I.InvoiceID AS Original_WWIInvoiceID,
                    IL.InvoiceLineID AS Original_WWIInvoiceLineID,
                    C.CityID AS Original_WWICityID,
                    CU.CustomerID AS Original_WWICustomerID,
                    BCU.CustomerID AS Original_WWIBillToCustomerID,
                    SI.StockItemID AS Original_WWIStockItemID,
                    I.SalespersonPersonID AS Original_WWISalesPersonID,
                    IL.Description AS Original_Description,
                    PT.PackageTypeName AS Original_Package,
                    IL.Quantity AS Original_Quantity,
                    IL.UnitPrice AS Original_UnitPrice,
                    IL.TaxRate AS Original_TaxRate,
                    (IL.ExtendedPrice - IL.TaxAmount) AS Original_TotalExcludingTax,
                    IL.TaxAmount AS Original_TaxAmount,
                    IL.LineProfit AS Original_Profit,
                    IL.ExtendedPrice AS Original_TotalIncludingTax,
                    CASE 
                        WHEN SI.IsChillerStock = FALSE THEN IL.Quantity 
                        ELSE 0 
                    END AS Original_TotalDryItems,
                    CASE 
                        WHEN SI.IsChillerStock <> FALSE THEN IL.Quantity 
                        ELSE 0 
                    END AS Original_TotalChillerItems,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
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
                WD.Warehouse_WWIInvoiceID = TD.Original_WWIInvoiceID AND
                WD.Warehouse_WWIInvoiceLineID = TD.Original_WWIInvoiceLineID
        WHERE 
            WD.Warehouse_WWIInvoiceID IS NULL OR 
            TD.Original_WWIInvoiceID IS NULL OR 
            ( 
                WD.Warehouse_WWIInvoiceID IS NOT NULL AND 
                TD.Original_WWIInvoiceID IS NOT NULL AND 
                (
                    WD.Warehouse_InvoiceDateKey != TD.Original_InvoiceDateKey OR
                    WD.Warehouse_DeliveryDateKey != TD.Original_DeliveryDateKey OR
                    WD.Warehouse_WWICityID != TD.Original_WWICityID OR
                    WD.Warehouse_WWICustomerID != TD.Original_WWICustomerID OR
                    WD.Warehouse_WWIBillToCustomerID != TD.Original_WWIBillToCustomerID OR
                    WD.Warehouse_WWIStockItemID != TD.Original_WWIStockItemID OR
                    WD.Warehouse_WWISalesPersonID != TD.Original_WWISalesPersonID OR
                    WD.Warehouse_Description != TD.Original_Description OR
                    WD.Warehouse_Package != TD.Original_Package OR
                    WD.Warehouse_Quantity != TD.Original_Quantity OR
                    WD.Warehouse_UnitPrice != TD.Original_UnitPrice OR
                    WD.Warehouse_TaxRate != TD.Original_TaxRate OR
                    WD.Warehouse_TotalExcludingTax != TD.Original_TotalExcludingTax OR
                    WD.Warehouse_TaxAmount != TD.Original_TaxAmount OR
                    WD.Warehouse_Profit != TD.Original_Profit OR
                    WD.Warehouse_TotalIncludingTax != TD.Original_TotalIncludingTax OR
                    WD.Warehouse_TotalDryItems != TD.Original_TotalDryItems OR
                    WD.Warehouse_TotalChillerItems != TD.Original_TotalChillerItems OR
                    WD.Warehouse_LoadDate != TD.Original_LoadDate 
                )
            )
    ) R