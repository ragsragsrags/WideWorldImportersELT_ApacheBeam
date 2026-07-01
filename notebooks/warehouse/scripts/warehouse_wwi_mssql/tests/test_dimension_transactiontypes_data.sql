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
                    WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN ''Missing in warehouse data'' 
                    WHEN TD.Original_WWITransactionTypeID IS NULL THEN ''Missing in original data'' 
                    ELSE ''Mismatch data'' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWITransactionTypeID] = DTT.[WWITransactionTypeID],
                    [Warehouse_TransactionType] = DTT.[TransactionType],
                    [Warehouse_LoadDate] = DTT.[LoadDate]
                FROM 
                    {{ DimTransactionTypes }} DTT
                WHERE 
                    DTT.[LoadDate] = ''<< NewCutoffDate >>'' AND 
                    DTT.[TransactionTypeKey] != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            [Original_WWITransactionTypeID] = TT.TransactionTypeID,		            
		            [Original_TransactionType] = TT.TransactionTypeName,
                    [Original_LoadDate] = CAST(''<< NewCutoffDate >>'' AS DATETIME2(7))
	            FROM
		            {{ ApplicationTransactionTypes }} TT 
	            WHERE
		            TT.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN TT.ValidFrom AND TT.ValidTo

	            UNION ALL

	            SELECT
		            [Original_WWITransactionTypeID] = TTA.TransactionTypeID,
		            [Original_TransactionType] = TTA.TransactionTypeName,
                    [Original_LoadDate] = CAST(''<< NewCutoffDate >>'' AS DATETIME2(7))
	            FROM
		            {{ ApplicationTransactionTypesArchive }} TTA 
	            WHERE
		            TTA.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN TTA.ValidFrom AND TTA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWITransactionTypeID] = TD.[Original_WWITransactionTypeID] 
        WHERE 
            WD.Warehouse_WWITransactionTypeID IS NULL OR 
            TD.Original_WWITransactionTypeID IS NULL OR 
            ( 
                WD.Warehouse_WWITransactionTypeID IS NOT NULL AND 
                TD.Original_WWITransactionTypeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_TransactionType] != TD.[Original_TransactionType] OR
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
                    WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN 'Missing in warehouse data' 
                    WHEN TD.Original_WWITransactionTypeID IS NULL THEN 'Missing in original data' 
                    ELSE 'Mismatch data' 
                END, 
            * 
        FROM 
            ( 
                SELECT 
                    [Warehouse_WWITransactionTypeID] = DTT.[WWITransactionTypeID],
                    [Warehouse_TransactionType] = DTT.[TransactionType],
                    [Warehouse_LoadDate] = DTT.[LoadDate]
                FROM 
                    {{ DimTransactionTypes }} DTT
                WHERE 
                    DTT.[LoadDate] = '<< NewCutoffDate >>' AND 
                    DTT.[TransactionTypeKey] != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            [Original_WWITransactionTypeID] = TT.TransactionTypeID,		            
		            [Original_TransactionType] = TT.TransactionTypeName,
                    [Original_LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
	            FROM
		            {{ ApplicationTransactionTypes }} TT 
	            WHERE
		            TT.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN TT.ValidFrom AND TT.ValidTo

	            UNION ALL

	            SELECT
		            [Original_WWITransactionTypeID] = TTA.TransactionTypeID,
		            [Original_TransactionType] = TTA.TransactionTypeName,
                    [Original_LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(7))
	            FROM
		            {{ ApplicationTransactionTypesArchive }} TTA 
	            WHERE
		            TTA.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN TTA.ValidFrom AND TTA.ValidTo
            ) TD ON 
                WD.[Warehouse_WWITransactionTypeID] = TD.[Original_WWITransactionTypeID] 
        WHERE 
            WD.Warehouse_WWITransactionTypeID IS NULL OR 
            TD.Original_WWITransactionTypeID IS NULL OR 
            ( 
                WD.Warehouse_WWITransactionTypeID IS NOT NULL AND 
                TD.Original_WWITransactionTypeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.[Warehouse_TransactionType] != TD.[Original_TransactionType] OR
                        WD.[Warehouse_LoadDate] != TD.[Original_LoadDate] 
                    ) 
                )
            )
    ) R