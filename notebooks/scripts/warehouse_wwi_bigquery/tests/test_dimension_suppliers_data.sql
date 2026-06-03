SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 	
            CASE 
                WHEN WD.Warehouse_WWISupplierID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWISupplierID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DS.Supplier AS Warehouse_Supplier,
                    DS.Category AS Warehouse_Category,
                    DS.PrimaryContact AS Warehouse_PrimaryContact,
                    DS.SupplierReference AS Warehouse_SupplierReference,
                    DS.PaymentDays AS Warehouse_PaymentDays,
                    DS.PostalCode AS Warehouse_PostalCode,
                    DS.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimSuppliers }} DS
                WHERE 
                    DS.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DS.SupplierKey != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    S.SupplierID AS Original_WWISupplierID,
                    S.SupplierName AS Original_Supplier,
                    SC.SupplierCategoryName AS Original_Category,
                    P.FullName AS Original_PrimaryContact,
                    S.SupplierReference AS Original_SupplierReference,
                    S.PaymentDays AS Original_PaymentDays,
                    S.DeliveryPostalCode AS Original_PostalCode,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
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
                WD.Warehouse_WWISupplierID = TD.Original_WWISupplierID 
        WHERE 
            WD.Warehouse_WWISupplierID IS NULL OR 
            TD.Original_WWISupplierID IS NULL OR 
            ( 
                WD.Warehouse_WWISupplierID IS NOT NULL AND 
                TD.Original_WWISupplierID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_Supplier != TD.Original_Supplier OR
                        WD.Warehouse_Category != TD.Original_Category OR
                        WD.Warehouse_PrimaryContact != TD.Original_PrimaryContact OR
                        WD.Warehouse_SupplierReference != TD.Original_SupplierReference OR
                        WD.Warehouse_PaymentDays != TD.Original_PaymentDays OR
                        WD.Warehouse_PostalCode != TD.Original_PostalCode OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate
                    ) 
                )
            )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 	
            CASE 
                WHEN WD.Warehouse_WWISupplierID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWISupplierID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DS.WWISupplierID AS Warehouse_WWISupplierID,
                    DS.Supplier AS Warehouse_Supplier,
                    DS.Category AS Warehouse_Category,
                    DS.PrimaryContact AS Warehouse_PrimaryContact,
                    DS.SupplierReference AS Warehouse_SupplierReference,
                    DS.PaymentDays AS Warehouse_PaymentDays,
                    DS.PostalCode AS Warehouse_PostalCode,
                    DS.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimSuppliers }} DS
                WHERE 
                    DS.LoadDate = '<< NewCutoffDate >>' AND 
                    DS.SupplierKey != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    S.SupplierID AS Original_WWISupplierID,
                    S.SupplierName AS Original_Supplier,
                    SC.SupplierCategoryName AS Original_Category,
                    P.FullName AS Original_PrimaryContact,
                    S.SupplierReference AS Original_SupplierReference,
                    S.PaymentDays AS Original_PaymentDays,
                    S.DeliveryPostalCode AS Original_PostalCode,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
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
                WD.Warehouse_WWISupplierID = TD.Original_WWISupplierID 
        WHERE 
            WD.Warehouse_WWISupplierID IS NULL OR 
            TD.Original_WWISupplierID IS NULL OR 
            ( 
                WD.Warehouse_WWISupplierID IS NOT NULL AND 
                TD.Original_WWISupplierID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_Supplier != TD.Original_Supplier OR
                        WD.Warehouse_Category != TD.Original_Category OR
                        WD.Warehouse_PrimaryContact != TD.Original_PrimaryContact OR
                        WD.Warehouse_SupplierReference != TD.Original_SupplierReference OR
                        WD.Warehouse_PaymentDays != TD.Original_PaymentDays OR
                        WD.Warehouse_PostalCode != TD.Original_PostalCode OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate
                    ) 
                )
            )
    ) R