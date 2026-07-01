SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWICustomerID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWICustomerID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DC.WWICustomerID AS Warehouse_WWICustomerID, 
                    DC.WWIDeliveryCityID AS Warehouse_WWIDeliveryCityID, 
                    DC.Customer AS Warehouse_Customer, 
                    DC.BillToCustomer AS Warehouse_BillToCustomer, 
                    DC.Category AS Warehouse_Category, 
                    DC.BuyingGroup AS Warehouse_BuyingGroup, 
                    DC.PrimaryContact AS Warehouse_PrimaryContact, 
                    DC.PostalCode AS Warehouse_PostalCode, 
                    DC.IsOnCreditHold AS Warehouse_IsOnCreditHold,
                    DC.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimCustomers }} DC 
                WHERE 
                    DC.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DC.CustomerKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    C.CustomerID AS Original_WWICustomerID,
                    C.DeliveryCityID AS Original_WWIDeliveryCityID,
                    C.CustomerName AS Original_Customer,
                    BC.CustomerName AS Original_BillToCustomer,
                    CC.CustomerCategoryName AS Original_Category,
                    BG.BuyingGroupName AS Original_BuyingGroup,
                    PA.FullName AS Original_PrimaryContact,
                    C.DeliveryPostalCode AS Original_PostalCode,
                    C.IsOnCreditHold AS Original_IsOnCreditHold,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    (
                        SELECT 
                            C.CustomerID,
                            C.BillToCustomerID,
                            C.CustomerCategoryID,
                            C.PrimaryContactPersonID,
                            C.BuyingGroupID,
                            C.CustomerName,
                            C.DeliveryPostalCode,
                            C.IsOnCreditHold,
                            C.DeliveryCityID,
                            C.ValidFrom,
                            C.ValidTo
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT 
                            CA.CustomerID,
                            CA.BillToCustomerID,
                            CA.CustomerCategoryID,
                            CA.PrimaryContactPersonID,
                            CA.BuyingGroupID,
                            CA.CustomerName,
                            CA.DeliveryPostalCode,
                            CA.IsOnCreditHold,
                            CA.DeliveryCityID,
                            CA.ValidFrom,
                            CA.ValidTo
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C LEFT JOIN
                    (
                        SELECT 
                            C.CustomerID,
                            C.CustomerName,
                            C.DeliveryPostalCode
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT 
                            CA.CustomerID,
                            CA.CustomerName,
                            CA.DeliveryPostalCode
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) BC ON
                        BC.CustomerID = C.BillToCustomerID LEFT JOIN
                    (
                        SELECT
                            CC.CustomerCategoryID,
                            CC.CustomerCategoryName
                        FROM
                            {{ SalesCustomerCategories }} CC 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CC.ValidFrom AND CC.ValidTo

                        UNION ALL

                        SELECT
                            CCA.CustomerCategoryID,
                            CCA.CustomerCategoryName
                        FROM
                            {{ SalesCustomerCategoriesArchive }} CCA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN CCA.ValidFrom AND CCA.ValidTo
                    ) CC ON
                        CC.CustomerCategoryID = C.CustomerCategoryID LEFT JOIN
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
                    ) PA ON
                        PA.PersonID = C.PrimaryContactPersonID LEFT JOIN
                    (
                        SELECT
                            BG.BuyingGroupID,
                            BG.BuyingGroupName
                        FROM
                            {{ SalesBuyingGroups }} BG 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN BG.ValidFrom AND BG.ValidTo

                        UNION ALL

                        SELECT
                            BGA.BuyingGroupID,
                            BGA.BuyingGroupName
                        FROM
                            {{ SalesBuyingGroupsArchive }} BGA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN BGA.ValidFrom AND BGA.ValidTo
                    ) BG ON
                        BG.BuyingGroupID = C.BuyingGroupID
                WHERE
                    (
                        C.ValidFrom > ''<< LastCutoffDate >>'' OR
                        C.BuyingGroupID IN
                        (
                            SELECT 
                                BG.BuyingGroupID
                            FROM 
                                {{ SalesBuyingGroups }} AS BG 
                            WHERE 
                                BG.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN BG.ValidFrom AND BG.ValidTo 
                            
                            UNION ALL 
                        
                            SELECT 
                                BGA.BuyingGroupID
                            FROM 
                                {{ SalesBuyingGroupsArchive }} AS BGA
                            WHERE
                                BGA.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN BGA.ValidFrom AND BGA.ValidTo
                        ) OR
                        C.CustomerCategoryID IN
                        (
                            SELECT 
                                CC.CustomerCategoryID
                            FROM 
                                {{ SalesCustomerCategories }} AS CC 
                            WHERE 
                                CC.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN CC.ValidFrom AND CC.ValidTo 
                            
                            UNION ALL 
                        
                            SELECT 
                                CCA.CustomerCategoryID
                            FROM 
                                {{ SalesCustomerCategoriesArchive }} AS CCA
                            WHERE 
                                CCA.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN CCA.ValidFrom AND CCA.ValidTo 
                        ) OR
                        C.PrimaryContactPersonID IN
                        (
                            SELECT 
                                P.PersonID
                            FROM 
                                {{ ApplicationPeople }} AS P 
                            WHERE 
                                P.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN P.ValidFrom AND P.ValidTo 
                            
                            UNION ALL 
                        
                            SELECT 
                                PA.PersonID
                            FROM 
                                {{ ApplicationPeopleArchive }} AS PA 
                            WHERE
                                PA.ValidFrom > ''<< LastCutoffDate >>'' AND
                                ''<< NewCutoffDate >>'' BETWEEN PA.ValidFrom AND PA.ValidTo
                        )
                    ) AND
                    ''<< NewCutoffDate >>'' BETWEEN C.ValidFrom AND C.ValidTo
            ) TD ON 
                    WD.Warehouse_WWICustomerID = TD.Original_WWICustomerID 
            WHERE 
                WD.Warehouse_WWICustomerID IS NULL OR 
                TD.Original_WWICustomerID IS NULL OR 
                ( 
                    WD.Warehouse_WWICustomerID IS NOT NULL AND 
                    TD.Original_WWICustomerID IS NOT NULL AND 
                    ( 
                        ( 
                            WD.Warehouse_WWIDeliveryCityID != TD.Original_WWIDeliveryCityID OR 
                            WD.Warehouse_Customer != TD.Original_Customer OR 
                            WD.Warehouse_BillToCustomer != TD.Original_BillToCustomer OR 
                            WD.Warehouse_Category != TD.Original_Category OR 
                            WD.Warehouse_BuyingGroup != TD.Original_BuyingGroup OR 
                            WD.Warehouse_PrimaryContact != TD.Original_PrimaryContact OR 
                            WD.Warehouse_PostalCode != TD.Original_PostalCode OR
                            WD.Warehouse_IsOnCreditHold != TD.Original_IsOnCreditHold OR 
                            WD.Warehouse_LoadDate != TD.Original_LoadDate
                        ) 
                    )
                )
    ''', CHR(10), '') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWICustomerID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWICustomerID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DC.WWICustomerID AS Warehouse_WWICustomerID, 
                    DC.WWIDeliveryCityID AS Warehouse_WWIDeliveryCityID, 
                    DC.Customer AS Warehouse_Customer, 
                    DC.BillToCustomer AS Warehouse_BillToCustomer, 
                    DC.Category AS Warehouse_Category, 
                    DC.BuyingGroup AS Warehouse_BuyingGroup, 
                    DC.PrimaryContact AS Warehouse_PrimaryContact, 
                    DC.PostalCode AS Warehouse_PostalCode, 
                    DC.IsOnCreditHold AS Warehouse_IsOnCreditHold,
                    DC.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimCustomers }} DC 
                WHERE 
                    DC.LoadDate = '<< NewCutoffDate >>' AND 
                    DC.CustomerKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    C.CustomerID AS Original_WWICustomerID,
                    C.DeliveryCityID AS Original_WWIDeliveryCityID,
                    C.CustomerName AS Original_Customer,
                    BC.CustomerName AS Original_BillToCustomer,
                    CC.CustomerCategoryName AS Original_Category,
                    BG.BuyingGroupName AS Original_BuyingGroup,
                    PA.FullName AS Original_PrimaryContact,
                    C.DeliveryPostalCode AS Original_PostalCode,
                    C.IsOnCreditHold AS Original_IsOnCreditHold,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    (
                        SELECT 
                            C.CustomerID,
                            C.BillToCustomerID,
                            C.CustomerCategoryID,
                            C.PrimaryContactPersonID,
                            C.BuyingGroupID,
                            C.CustomerName,
                            C.DeliveryPostalCode,
                            C.IsOnCreditHold,
                            C.DeliveryCityID,
                            C.ValidFrom,
                            C.ValidTo
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT 
                            CA.CustomerID,
                            CA.BillToCustomerID,
                            CA.CustomerCategoryID,
                            CA.PrimaryContactPersonID,
                            CA.BuyingGroupID,
                            CA.CustomerName,
                            CA.DeliveryPostalCode,
                            CA.IsOnCreditHold,
                            CA.DeliveryCityID,
                            CA.ValidFrom,
                            CA.ValidTo
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) C LEFT JOIN
                    (
                        SELECT 
                            C.CustomerID,
                            C.CustomerName,
                            C.DeliveryPostalCode
                        FROM
                            {{ SalesCustomers }} C
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo

                        UNION ALL

                        SELECT 
                            CA.CustomerID,
                            CA.CustomerName,
                            CA.DeliveryPostalCode
                        FROM
                            {{ SalesCustomersArchive }} CA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CA.ValidFrom AND CA.ValidTo
                    ) BC ON
                        BC.CustomerID = C.BillToCustomerID LEFT JOIN
                    (
                        SELECT
                            CC.CustomerCategoryID,
                            CC.CustomerCategoryName
                        FROM
                            {{ SalesCustomerCategories }} CC 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CC.ValidFrom AND CC.ValidTo

                        UNION ALL

                        SELECT
                            CCA.CustomerCategoryID,
                            CCA.CustomerCategoryName
                        FROM
                            {{ SalesCustomerCategoriesArchive }} CCA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN CCA.ValidFrom AND CCA.ValidTo
                    ) CC ON
                        CC.CustomerCategoryID = C.CustomerCategoryID LEFT JOIN
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
                    ) PA ON
                        PA.PersonID = C.PrimaryContactPersonID LEFT JOIN
                    (
                        SELECT
                            BG.BuyingGroupID,
                            BG.BuyingGroupName
                        FROM
                            {{ SalesBuyingGroups }} BG 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN BG.ValidFrom AND BG.ValidTo

                        UNION ALL

                        SELECT
                            BGA.BuyingGroupID,
                            BGA.BuyingGroupName
                        FROM
                            {{ SalesBuyingGroupsArchive }} BGA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN BGA.ValidFrom AND BGA.ValidTo
                    ) BG ON
                        BG.BuyingGroupID = C.BuyingGroupID
                WHERE
                    (
                        C.ValidFrom > '<< LastCutoffDate >>' OR
                        C.BuyingGroupID IN
                        (
                            SELECT 
                                BG.BuyingGroupID
                            FROM 
                                {{ SalesBuyingGroups }} AS BG 
                            WHERE 
                                BG.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN BG.ValidFrom AND BG.ValidTo 
                            
                            UNION ALL 
                        
                            SELECT 
                                BGA.BuyingGroupID
                            FROM 
                                {{ SalesBuyingGroupsArchive }} AS BGA
                            WHERE
                                BGA.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN BGA.ValidFrom AND BGA.ValidTo
                        ) OR
                        C.CustomerCategoryID IN
                        (
                            SELECT 
                                CC.CustomerCategoryID
                            FROM 
                                {{ SalesCustomerCategories }} AS CC 
                            WHERE 
                                CC.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN CC.ValidFrom AND CC.ValidTo 
                            
                            UNION ALL 
                        
                            SELECT 
                                CCA.CustomerCategoryID
                            FROM 
                                {{ SalesCustomerCategoriesArchive }} AS CCA
                            WHERE 
                                CCA.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN CCA.ValidFrom AND CCA.ValidTo 
                        ) OR
                        C.PrimaryContactPersonID IN
                        (
                            SELECT 
                                P.PersonID
                            FROM 
                                {{ ApplicationPeople }} AS P 
                            WHERE 
                                P.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo 
                            
                            UNION ALL 
                        
                            SELECT 
                                PA.PersonID
                            FROM 
                                {{ ApplicationPeopleArchive }} AS PA 
                            WHERE
                                PA.ValidFrom > '<< LastCutoffDate >>' AND
                                '<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo
                        )
                    ) AND
                    '<< NewCutoffDate >>' BETWEEN C.ValidFrom AND C.ValidTo
            ) TD ON 
                    WD.Warehouse_WWICustomerID = TD.Original_WWICustomerID 
            WHERE 
                WD.Warehouse_WWICustomerID IS NULL OR 
                TD.Original_WWICustomerID IS NULL OR 
                ( 
                    WD.Warehouse_WWICustomerID IS NOT NULL AND 
                    TD.Original_WWICustomerID IS NOT NULL AND 
                    ( 
                        ( 
                            WD.Warehouse_WWIDeliveryCityID != TD.Original_WWIDeliveryCityID OR 
                            WD.Warehouse_Customer != TD.Original_Customer OR 
                            WD.Warehouse_BillToCustomer != TD.Original_BillToCustomer OR 
                            WD.Warehouse_Category != TD.Original_Category OR 
                            WD.Warehouse_BuyingGroup != TD.Original_BuyingGroup OR 
                            WD.Warehouse_PrimaryContact != TD.Original_PrimaryContact OR 
                            WD.Warehouse_PostalCode != TD.Original_PostalCode OR
                            WD.Warehouse_IsOnCreditHold != TD.Original_IsOnCreditHold OR 
                            WD.Warehouse_LoadDate != TD.Original_LoadDate
                        ) 
                    )
                )
    ) R