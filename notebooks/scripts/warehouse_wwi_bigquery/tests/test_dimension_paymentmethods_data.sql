SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 	
            CASE 
                WHEN WD.Warehouse_WWIPaymentMethodID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWIPaymentMethodID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DPM.WWIPaymentMethodID AS Warehouse_WWIPaymentMethodID, 
                    DPM.PaymentMethod AS Warehouse_PaymentMethod,
                    DPM.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimPaymentMethods }} DPM
                WHERE 
                    DPM.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DPM.PaymentMethodKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    PM.PaymentMethodID AS Original_WWIPaymentMethodID,
                    PM.PaymentMethodName AS Original_PaymentMethod,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ ApplicationPaymentMethods }} AS PM
                WHERE
                    PM.ValidFrom > ''<< LastCutoffDate >>'' AND
                    ''<< NewCutoffDate >>'' BETWEEN PM.ValidFrom AND PM.ValidTo

                UNION ALL

                SELECT
                    PMA.PaymentMethodID,
                    PMA.PaymentMethodName,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ ApplicationPaymentMethodsArchive }} AS PMA
                WHERE
                    PMA.ValidFrom > ''<< LastCutoffDate >>'' AND
                    ''<< NewCutoffDate >>'' BETWEEN PMA.ValidFrom AND PMA.ValidTo
            ) TD ON 
                WD.Warehouse_WWIPaymentMethodID = TD.Original_WWIPaymentMethodID 
        WHERE 
            WD.Warehouse_WWIPaymentMethodID IS NULL OR 
            TD.Original_WWIPaymentMethodID IS NULL OR 
            ( 
                WD.Warehouse_WWIPaymentMethodID IS NOT NULL AND 
                TD.Original_WWIPaymentMethodID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_PaymentMethod != TD.Original_PaymentMethod OR 
                        WD.Warehouse_LoadDate != TD.Original_LoadDate 
                    ) 
                )
            )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 	
            CASE 
                WHEN WD.Warehouse_WWIPaymentMethodID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWIPaymentMethodID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DPM.WWIPaymentMethodID AS Warehouse_WWIPaymentMethodID, 
                    DPM.PaymentMethod AS Warehouse_PaymentMethod,
                    DPM.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimPaymentMethods }} DPM
                WHERE 
                    DPM.LoadDate = '<< NewCutoffDate >>' AND 
                    DPM.PaymentMethodKey != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    PM.PaymentMethodID AS Original_WWIPaymentMethodID,
                    PM.PaymentMethodName AS Original_PaymentMethod,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ ApplicationPaymentMethods }} AS PM
                WHERE
                    PM.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN PM.ValidFrom AND PM.ValidTo

                UNION ALL

                SELECT
                    PMA.PaymentMethodID,
                    PMA.PaymentMethodName,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
                FROM
                    {{ ApplicationPaymentMethodsArchive }} AS PMA
                WHERE
                    PMA.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN PMA.ValidFrom AND PMA.ValidTo
            ) TD ON 
                WD.Warehouse_WWIPaymentMethodID = TD.Original_WWIPaymentMethodID 
        WHERE 
            WD.Warehouse_WWIPaymentMethodID IS NULL OR 
            TD.Original_WWIPaymentMethodID IS NULL OR 
            ( 
                WD.Warehouse_WWIPaymentMethodID IS NOT NULL AND 
                TD.Original_WWIPaymentMethodID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_PaymentMethod != TD.Original_PaymentMethod OR 
                        WD.Warehouse_LoadDate != TD.Original_LoadDate 
                    ) 
                )
            )
    ) R