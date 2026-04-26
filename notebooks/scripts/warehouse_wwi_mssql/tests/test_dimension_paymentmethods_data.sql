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
                    WHEN WD.Warehouse_WWIPaymentMethodID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWIPaymentMethodID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWIPaymentMethodID] = DPM.[WWIPaymentMethodID], 
                    [Warehouse_PaymentMethod] = DPM.[PaymentMethod],
                    [Warehouse_LoadDate] = DPM.[LoadDate]
                FROM 
                    {{ DimPaymentMethods }} DPM
                WHERE 
                    DPM.[LoadDate] = ''<< NewCutoffDate >>'' AND 
                    DPM.[PaymentMethodKey] != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_WWIPaymentMethodID] = PM.PaymentMethodID,
                    [Original_PaymentMethod] = PM.PaymentMethodName,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    {{ ApplicationPaymentMethods }} AS PM
                WHERE
                    PM.ValidFrom > ''<< LastCutoffDate >>'' AND
                    ''<< NewCutoffDate >>'' BETWEEN PM.ValidFrom AND PM.ValidTo

                UNION ALL

                SELECT
                    PMA.PaymentMethodID,
                    PMA.PaymentMethodName,
                    [Original_LoadDate] = ''<< NewCutoffDate >>''
                FROM
                    {{ ApplicationPaymentMethodsArchive }} AS PMA
                WHERE
                    PMA.ValidFrom > ''<< LastCutoffDate >>'' AND
                    ''<< NewCutoffDate >>'' BETWEEN PMA.ValidFrom AND PMA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWIPaymentMethodID] = TD.[Original_WWIPaymentMethodID] 
        WHERE 
            WD.Warehouse_WWIPaymentMethodID IS NULL OR 
            TD.Original_WWIPaymentMethodID IS NULL OR 
            ( 
                WD.Warehouse_WWIPaymentMethodID IS NOT NULL AND 
                TD.Original_WWIPaymentMethodID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_PaymentMethod] != TD.[Original_PaymentMethod] OR 
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
                    WHEN WD.Warehouse_WWIPaymentMethodID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWIPaymentMethodID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWIPaymentMethodID] = DPM.[WWIPaymentMethodID], 
                    [Warehouse_PaymentMethod] = DPM.[PaymentMethod],
                    [Warehouse_LoadDate] = DPM.[LoadDate]
                FROM 
                    {{ DimPaymentMethods }} DPM
                WHERE 
                    DPM.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DPM.[PaymentMethodKey] != 0 
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
                    [Original_WWIPaymentMethodID] = PM.PaymentMethodID,
                    [Original_PaymentMethod] = PM.PaymentMethodName,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    {{ ApplicationPaymentMethods }} AS PM
                WHERE
                    PM.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN PM.ValidFrom AND PM.ValidTo

                UNION ALL

                SELECT
                    PMA.PaymentMethodID,
                    PMA.PaymentMethodName,
                    [Original_LoadDate] = '<< NewCutoffDate >>'
                FROM
                    {{ ApplicationPaymentMethodsArchive }} AS PMA
                WHERE
                    PMA.ValidFrom > '<< LastCutoffDate >>' AND
                    '<< NewCutoffDate >>' BETWEEN PMA.ValidFrom AND PMA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWIPaymentMethodID] = TD.[Original_WWIPaymentMethodID] 
        WHERE 
            WD.Warehouse_WWIPaymentMethodID IS NULL OR 
            TD.Original_WWIPaymentMethodID IS NULL OR 
            ( 
                WD.Warehouse_WWIPaymentMethodID IS NOT NULL AND 
                TD.Original_WWIPaymentMethodID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_PaymentMethod] != TD.[Original_PaymentMethod] OR 
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                    ) 
                )
            )
    ) R