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
                    WHEN WD.Warehouse_WWISupplierID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWISupplierID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_Supplier] = DS.[Supplier],
                    [Warehouse_Category] = DS.[Category],
                    [Warehouse_PrimaryContact] = DS.[PrimaryContact],
                    [Warehouse_SupplierReference] = DS.[SupplierReference],
                    [Warehouse_PaymentDays] = DS.[PaymentDays],
                    [Warehouse_PostalCode] = DS.[PostalCode],
                    [Warehouse_LoadDate] = DS.[LoadDate]
                FROM 
                    {{ DimSuppliers }} DS
                WHERE 
                    DS.[LoadDate] = ''<< NewCutoffDate >>'' AND 
                    DS.[SupplierKey] != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_WWISupplierID] = S.SupplierID,
                    [Original_Supplier] = S.SupplierName,
                    [Original_Category] = SC.SupplierCategoryName,
                    [Original_PrimaryContact] = P.FullName,
                    [Original_SupplierReference] = S.SupplierReference,
                    [Original_PaymentDays] = S.PaymentDays,
                    [Original_PostalCode] = S.DeliveryPostalCode,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    (
                        SELECT 
                            S.SupplierID,
                            S.SupplierCategoryID,
                            S.PrimaryContactPersonID,
                            S.SupplierName,
                            S.SupplierReference,
                            S.PaymentDays,
                            S.DeliveryPostalCode,
                            S.ValidFrom,
                            S.ValidTo
                        FROM 
                            {{ PurchasingSuppliers }} S
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN S.ValidFrom AND S.ValidTo

                        UNION ALL

                        SELECT
                            SA.SupplierID,
                            SA.SupplierCategoryID,
                            SA.PrimaryContactPersonID,
                            SA.SupplierName,
                            SA.SupplierReference,
                            SA.PaymentDays,
                            SA.DeliveryPostalCode,
                            SA.ValidFrom,
                            SA.ValidTo
                        FROM
                            {{ PurchasingSuppliersArchive }} SA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S LEFT JOIN
                    (
                        SELECT 
                            SC.SupplierCategoryID,
                            SC.SupplierCategoryName
                        FROM
                            {{ PurchasingSupplierCategories }} SC 
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SC.ValidFrom AND SC.ValidTo

                        UNION ALL

                        SELECT
                            SCA.SupplierCategoryID,
                            SCA.SupplierCategoryName
                        FROM
                            {{ PurchasingSupplierCategoriesArchive }} SCA
                        WHERE
                            ''<< NewCutoffDate >>'' BETWEEN SCA.ValidFrom AND SCA.ValidTo
                    ) SC ON
                        SC.SupplierCategoryID = S.SupplierCategoryID LEFT JOIN
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
                    ) P ON
                        P.PersonID = S.PrimaryContactPersonID
                WHERE
                    (
			            S.ValidFrom > ''<< LastCutoffDate >>'' OR
			            S.SupplierCategoryID IN
			            (
                            SELECT
		                        SC.SupplierCategoryID
	                        FROM
		                        {{ PurchasingSupplierCategories }} SC
	                        WHERE
		                        SC.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN SC.ValidFrom AND SC.ValidTo 

	                        UNION ALL

	                        SELECT
		                        SCA.SupplierCategoryID
	                        FROM
		                        {{ PurchasingSupplierCategoriesArchive }} SCA
	                        WHERE
		                        SCA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN SCA.ValidFrom AND SCA.ValidTo
			            ) OR
			            S.PrimaryContactPersonID IN
			            (
				            SELECT
		                        P.PersonID
	                        FROM
		                        {{ ApplicationPeople }} P
	                        WHERE
		                        P.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN P.ValidFrom AND P.ValidTo 

	                        UNION ALL

	                        SELECT
		                        PA.PersonID
	                        FROM
		                        {{ ApplicationPeopleArchive }} PA
	                        WHERE
		                        PA.ValidFrom > ''<< LastCutoffDate >>'' AND
		                        ''<< NewCutoffDate >>'' BETWEEN PA.ValidFrom AND PA.ValidTo
			            )
		            ) AND
		            ''<< NewCutoffDate >>'' BETWEEN S.ValidFrom AND S.ValidTo
            ) TD ON 
                WD.[Warehouse_WWISupplierID] = TD.[Original_WWISupplierID] 
        WHERE 
            WD.Warehouse_WWISupplierID IS NULL OR 
            TD.Original_WWISupplierID IS NULL OR 
            ( 
                WD.Warehouse_WWISupplierID IS NOT NULL AND 
                TD.Original_WWISupplierID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_Supplier] != TD.[Original_Supplier] OR
                        WD.[Warehouse_Category] != TD.[Original_Category] OR
                        WD.[Warehouse_PrimaryContact] != TD.[Original_PrimaryContact] OR
                        WD.[Warehouse_SupplierReference] != TD.[Original_SupplierReference] OR
                        WD.[Warehouse_PaymentDays] != TD.[Original_PaymentDays] OR
                        WD.[Warehouse_PostalCode] != TD.[Original_PostalCode] OR
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                    ) 
                )
            )
    ', CHAR(10), '')
FROM
    (
        SELECT 
            [Error] =	
                CASE 
                    WHEN WD.Warehouse_WWISupplierID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWISupplierID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWISupplierID] = DS.[WWISupplierID],
                    [Warehouse_Supplier] = DS.[Supplier],
                    [Warehouse_Category] = DS.[Category],
                    [Warehouse_PrimaryContact] = DS.[PrimaryContact],
                    [Warehouse_SupplierReference] = DS.[SupplierReference],
                    [Warehouse_PaymentDays] = DS.[PaymentDays],
                    [Warehouse_PostalCode] = DS.[PostalCode],
                    [Warehouse_LoadDate] = DS.[LoadDate]
                FROM 
                    {{ DimSuppliers }} DS
                WHERE 
                    DS.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DS.[SupplierKey] != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_WWISupplierID] = S.SupplierID,
                    [Original_Supplier] = S.SupplierName,
                    [Original_Category] = SC.SupplierCategoryName,
                    [Original_PrimaryContact] = P.FullName,
                    [Original_SupplierReference] = S.SupplierReference,
                    [Original_PaymentDays] = S.PaymentDays,
                    [Original_PostalCode] = S.DeliveryPostalCode,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    (
                        SELECT 
                            S.SupplierID,
                            S.SupplierCategoryID,
                            S.PrimaryContactPersonID,
                            S.SupplierName,
                            S.SupplierReference,
                            S.PaymentDays,
                            S.DeliveryPostalCode,
                            S.ValidFrom,
                            S.ValidTo
                        FROM 
                            {{ PurchasingSuppliers }} S
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN S.ValidFrom AND S.ValidTo

                        UNION ALL

                        SELECT
                            SA.SupplierID,
                            SA.SupplierCategoryID,
                            SA.PrimaryContactPersonID,
                            SA.SupplierName,
                            SA.SupplierReference,
                            SA.PaymentDays,
                            SA.DeliveryPostalCode,
                            SA.ValidFrom,
                            SA.ValidTo
                        FROM
                            {{ PurchasingSuppliersArchive }} SA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SA.ValidFrom AND SA.ValidTo
                    ) S LEFT JOIN
                    (
                        SELECT 
                            SC.SupplierCategoryID,
                            SC.SupplierCategoryName
                        FROM
                            {{ PurchasingSupplierCategories }} SC 
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SC.ValidFrom AND SC.ValidTo

                        UNION ALL

                        SELECT
                            SCA.SupplierCategoryID,
                            SCA.SupplierCategoryName
                        FROM
                            {{ PurchasingSupplierCategoriesArchive }} SCA
                        WHERE
                            '<< NewCutoffDate >>' BETWEEN SCA.ValidFrom AND SCA.ValidTo
                    ) SC ON
                        SC.SupplierCategoryID = S.SupplierCategoryID LEFT JOIN
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
                        P.PersonID = S.PrimaryContactPersonID
                WHERE
                    (
			            S.ValidFrom > '<< LastCutoffDate >>' OR
			            S.SupplierCategoryID IN
			            (
                            SELECT
		                        SC.SupplierCategoryID
	                        FROM
		                        {{ PurchasingSupplierCategories }} SC
	                        WHERE
		                        SC.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN SC.ValidFrom AND SC.ValidTo 

	                        UNION ALL

	                        SELECT
		                        SCA.SupplierCategoryID
	                        FROM
		                        {{ PurchasingSupplierCategoriesArchive }} SCA
	                        WHERE
		                        SCA.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN SCA.ValidFrom AND SCA.ValidTo
			            ) OR
			            S.PrimaryContactPersonID IN
			            (
				            SELECT
		                        P.PersonID
	                        FROM
		                        {{ ApplicationPeople }} P
	                        WHERE
		                        P.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN P.ValidFrom AND P.ValidTo 

	                        UNION ALL

	                        SELECT
		                        PA.PersonID
	                        FROM
		                        {{ ApplicationPeopleArchive }} PA
	                        WHERE
		                        PA.ValidFrom > '<< LastCutoffDate >>' AND
		                        '<< NewCutoffDate >>' BETWEEN PA.ValidFrom AND PA.ValidTo
			            )
		            ) AND
		            '<< NewCutoffDate >>' BETWEEN S.ValidFrom AND S.ValidTo
            ) TD ON 
                WD.[Warehouse_WWISupplierID] = TD.[Original_WWISupplierID] 
        WHERE 
            WD.Warehouse_WWISupplierID IS NULL OR 
            TD.Original_WWISupplierID IS NULL OR 
            ( 
                WD.Warehouse_WWISupplierID IS NOT NULL AND 
                TD.Original_WWISupplierID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_Supplier] != TD.[Original_Supplier] OR
                        WD.[Warehouse_Category] != TD.[Original_Category] OR
                        WD.[Warehouse_PrimaryContact] != TD.[Original_PrimaryContact] OR
                        WD.[Warehouse_SupplierReference] != TD.[Original_SupplierReference] OR
                        WD.[Warehouse_PaymentDays] != TD.[Original_PaymentDays] OR
                        WD.[Warehouse_PostalCode] != TD.[Original_PostalCode] OR
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate]
                    ) 
                )
            )
    ) R