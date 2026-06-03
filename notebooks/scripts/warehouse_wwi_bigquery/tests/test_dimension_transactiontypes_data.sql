SELECT
    '<< Name >>' AS Name,
    '<< Type >>' AS Type,
    '<< SubType >>' AS SubType,
    '<< Column >>' AS Column,
    COUNT(*) AS ErrorCount,
    REPLACE('''
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN ''Missing in warehouse data'' 
                WHEN TD.Original_WWITransactionTypeID IS NULL THEN ''Missing in original data'' 
                ELSE ''Mismatch data'' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DTT.WWITransactionTypeID AS Warehouse_WWITransactionTypeID,
                    DTT.TransactionType AS Warehouse_TransactionType,
                    DTT.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimTransactionTypes }} DTT
                WHERE 
                    DTT.LoadDate = ''<< NewCutoffDate >>'' AND 
                    DTT.TransactionTypeKey != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            TT.TransactionTypeID AS Original_WWITransactionTypeID,		            
		            TT.TransactionTypeName AS Original_TransactionType,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationTransactionTypes }} TT 
	            WHERE
		            TT.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN TT.ValidFrom AND TT.ValidTo

	            UNION ALL

	            SELECT
		            TTA.TransactionTypeID AS Original_WWITransactionTypeID,
		            TTA.TransactionTypeName AS Original_TransactionType,
                    CAST(''<< NewCutoffDate >>'' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationTransactionTypesArchive }} TTA 
	            WHERE
		            TTA.ValidFrom > ''<< LastCutoffDate >>'' AND
		            ''<< NewCutoffDate >>'' BETWEEN TTA.ValidFrom AND TTA.ValidTo
            ) TD ON 
                WD.Warehouse_WWITransactionTypeID = TD.Original_WWITransactionTypeID 
        WHERE 
            WD.Warehouse_WWITransactionTypeID IS NULL OR 
            TD.Original_WWITransactionTypeID IS NULL OR 
            ( 
                WD.Warehouse_WWITransactionTypeID IS NOT NULL AND 
                TD.Original_WWITransactionTypeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_TransactionType != TD.Original_TransactionType OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate 
                    ) 
                )
            )
    ''', CHR(10), ' ') AS Sql
FROM
    (
        SELECT 
            CASE 
                WHEN WD.Warehouse_WWITransactionTypeID IS NULL THEN 'Missing in warehouse data' 
                WHEN TD.Original_WWITransactionTypeID IS NULL THEN 'Missing in original data' 
                ELSE 'Mismatch data' 
            END AS Error, 
            * 
        FROM 
            ( 
                SELECT 
                    DTT.WWITransactionTypeID AS Warehouse_WWITransactionTypeID,
                    DTT.TransactionType AS Warehouse_TransactionType,
                    DTT.LoadDate AS Warehouse_LoadDate
                FROM 
                    {{ DimTransactionTypes }} DTT
                WHERE 
                    DTT.LoadDate = '<< NewCutoffDate >>' AND 
                    DTT.TransactionTypeKey != 0
            ) WD FULL OUTER JOIN 
            ( 
                SELECT
		            TT.TransactionTypeID AS Original_WWITransactionTypeID,		            
		            TT.TransactionTypeName AS Original_TransactionType,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationTransactionTypes }} TT 
	            WHERE
		            TT.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN TT.ValidFrom AND TT.ValidTo

	            UNION ALL

	            SELECT
		            TTA.TransactionTypeID AS Original_WWITransactionTypeID,
		            TTA.TransactionTypeName AS Original_TransactionType,
                    CAST('<< NewCutoffDate >>' AS DATETIME) AS Original_LoadDate
	            FROM
		            {{ ApplicationTransactionTypesArchive }} TTA 
	            WHERE
		            TTA.ValidFrom > '<< LastCutoffDate >>' AND
		            '<< NewCutoffDate >>' BETWEEN TTA.ValidFrom AND TTA.ValidTo
            ) TD ON 
                WD.Warehouse_WWITransactionTypeID = TD.Original_WWITransactionTypeID 
        WHERE 
            WD.Warehouse_WWITransactionTypeID IS NULL OR 
            TD.Original_WWITransactionTypeID IS NULL OR 
            ( 
                WD.Warehouse_WWITransactionTypeID IS NOT NULL AND 
                TD.Original_WWITransactionTypeID IS NOT NULL AND 
                ( 
                    ( 
                        WD.Warehouse_TransactionType != TD.Original_TransactionType OR
                        WD.Warehouse_LoadDate != TD.Original_LoadDate 
                    ) 
                )
            )
    ) R