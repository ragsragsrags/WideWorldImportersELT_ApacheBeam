SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = REPLACE('
    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWIOrderID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWIOrderID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_OrderDateKey] = FO.[OrderDateKey],
                    [Warehouse_PickedDateKey] = FO.[PickedDateKey],
                    [Warehouse_WWIOrderID] = FO.[WWIOrderID],
                    [Warehouse_WWIOrderLineID] = FO.[WWIOrderLineID],
                    [Warehouse_WWIBackorderID] = FO.[WWIBackorderID],
                    [Warehouse_WWICustomerID] = DC.[WWICustomerID],
                    [Warehouse_WWIStockItemID] = DSI.[StockItemKey],
                    [Warehouse_WWISalesPersonID] = DE2.[WWIEmployeeID],
                    [Warehouse_WWICityID] = DCT.[WWICityID],
                    [Warehouse_WWIPickerID] = DE.[WWIEmployeeID],
                    [Warehouse_Description] = FO.[Description],
                    [Warehouse_Package] = FO.[Package],
                    [Warehouse_Quantity] = FO.[Quantity],
                    [Warehouse_UnitPrice] = FO.[UnitPrice],
                    [Warehouse_TaxRate] = FO.[TaxRate],
                    [Warehouse_TotalExcludingTax] = FO.[TotalExcludingTax],
                    [Warehouse_TaxAmount] = FO.[TaxAmount],
                    [Warehouse_TotalIncludingTax] = FO.[TotalIncludingTax],
                    [Warehouse_LoadDate] = FO.[LoadDate]
                FROM 
                    {{ FctOrders }} FO LEFT JOIN
                    {{ DimCustomers }} DC ON
                        FO.CustomerKey = DC.CustomerKey LEFT JOIN
                    {{ DimStockItems }} DSI ON
                        FO.StockItemKey = DSI.StockItemKey LEFT JOIN
                    {{ DimEmployees }} DE ON
                        FO.PickerKey = DE.EmployeeKey LEFT JOIN
                    {{ DimEmployees }} DE2 ON
                        FO.SalesPersonKey = DE2.EmployeeKey LEFT JOIN
                    {{ DimCities }} DCT ON
                        FO.CityKey = DCT.CityKey 
                WHERE 
                    FO.[LoadDate] = '<< NewCutoffDate >>'
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_OrderDateKey] = CAST(O.OrderDate AS DATE),
                    [Original_PickedDateKey] = CAST(O.PickingCompletedWhen AS DATE),
                    [Original_WWIOrderID] = O.OrderID,
                    [Original_WWIOrderLineID] = OL.OrderLineID,
                    [Original_WWIBackorderID] = O.BackorderOrderID,
                    [Original_WWICustomerID] = C.CustomerID,
                    [Original_WWIStockItemID] = SI.StockItemID,
                    [Original_WWISalesPersonID] = O.SalespersonPersonID,
                    [Original_WWICityID] = C.DeliveryCityID,
                    [Original_WWIPickerID] = O.PickedByPersonID,
                    [Original_Description] = OL.Description,
                    [Original_Package] = PT.PackageTypeName,
                    [Original_Quantity] = OL.Quantity,
                    [Original_UnitPrice] = OL.UnitPrice,
                    [Original_TaxRate] = OL.TaxRate,
                    [Original_TotalExcludingTax] = ROUND(OL.Quantity * OL.UnitPrice, 2),
                    [Original_TaxAmount] = ROUND(OL.Quantity * OL.UnitPrice * OL.TaxRate / 100.0, 2),
                    [Original_TotalIncludingTax] = ROUND(OL.Quantity * OL.UnitPrice, 2) + ROUND(OL.Quantity * OL.UnitPrice * OL.TaxRate / 100.0, 2),
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    {{ SalesOrders }} O LEFT JOIN
                    {{ SalesOrderLines }} OL ON
                        OL.OrderID = O.OrderID LEFT JOIN 
                    (
                        SELECT
                            C.CustomerID,
                            C.DeliveryCityID,
                            C.CustomerName
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT
                            CA.CustomerID,
                            CA.DeliveryCityID,
                            CA.CustomerName
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C ON
                        C.CustomerID = O.CustomerID LEFT JOIN
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
                    ) CI ON
                        CI.CityID = C.DeliveryCityID LEFT JOIN
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
                        SI.StockItemID = OL.StockItemID LEFT JOIN
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
                    ) P ON
                        P.PersonID = O.SalespersonPersonID LEFT JOIN
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
                    ) P2 ON
                        P2.PersonID = O.PickedByPersonID LEFT JOIN
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
                        PT.PackageTypeID = OL.PackageTypeID
                WHERE
                    (
			            O.LastEditedWhen > '<< LastCutoffDate >>' OR
			            OL.LastEditedWhen > '<< LastCutoffDate >>' OR
			            OL.PackageTypeID IN (
				            SELECT
		                        PT.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypes }} PT
	                        WHERE
                                PT.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN PT.ValidFrom AND PT.ValidTo

	                        UNION

	                        SELECT
		                        PTA.PackageTypeID
	                        FROM
		                        {{ WarehousePackageTypesArchive }} PTA
	                        WHERE
                                PTA.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN PTA.ValidFrom AND PTA.ValidTo
			            )
		            ) AND
		            O.LastEditedWhen <= '<< NewCutoffDate >>' AND
		            OL.LastEditedWhen <= '<< NewCutoffDate >>'
            ) TD ON 
                WD.[Warehouse_WWIOrderID] = TD.[Original_WWIOrderID] AND
                WD.[Warehouse_WWIOrderLineID] = TD.[Original_WWIOrderLineID]
        WHERE 
            WD.Warehouse_WWIOrderID IS NULL OR 
            TD.Original_WWIOrderID IS NULL OR 
            ( 
                WD.Warehouse_WWIOrderID IS NOT NULL AND 
                TD.Original_WWIOrderID IS NOT NULL AND 
                (
                    WD.[Warehouse_OrderDateKey] != TD.[Original_OrderDateKey] OR
                    WD.[Warehouse_PickedDateKey] != TD.[Original_PickedDateKey] OR
                    WD.[Warehouse_WWIBackorderID] != TD.[Original_WWIBackorderID] OR
                    WD.[Warehouse_WWICustomerID] != TD.[Original_WWICustomerID] OR
                    WD.[Warehouse_WWIStockItemID] != TD.[Original_WWIStockItemID] OR
                    WD.[Warehouse_WWISalesPersonID] != TD.[Original_WWISalesPersonID] OR
                    WD.[Warehouse_WWICityID] != TD.[Original_WWICityID] OR
                    WD.[Warehouse_WWIPickerID] != TD.[Original_WWIPickerID] OR
                    WD.[Warehouse_Description] != TD.[Original_Description] OR
                    WD.[Warehouse_Package] != TD.[Original_Package] OR
                    WD.[Warehouse_Quantity] != TD.[Original_Quantity] OR
                    WD.[Warehouse_UnitPrice] != TD.[Original_UnitPrice] OR
                    WD.[Warehouse_TaxRate] != TD.[Original_TaxRate] OR
                    WD.[Warehouse_TotalExcludingTax] != TD.[Original_TotalExcludingTax] OR
                    WD.[Warehouse_TaxAmount] != TD.[Original_TaxAmount] OR
                    WD.[Warehouse_TotalIncludingTax] != TD.[Original_TotalIncludingTax] OR
                    WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                )
            )
    ) R