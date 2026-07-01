SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = 
        CASE 
            WHEN (SELECT COUNT(*) FROM [<< Schema >>].[<< Table >>] WHERE [StockItemKey] = 0 AND [StockItem] = 'Unknown') != 1 THEN 1
            ELSE 0
        END,
    [Sql] = 'SELECT COUNT(*) FROM [<< Schema >>].[<< Table >>] WHERE [StockItemKey] = 0 AND [StockItem] = ''Unknown'''