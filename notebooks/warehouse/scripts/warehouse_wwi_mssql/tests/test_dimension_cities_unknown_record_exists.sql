SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = 
        CASE 
            WHEN (SELECT COUNT(*) FROM [<< Schema >>].[<< Table >>] WHERE [CityKey] = 0 AND [City] = 'Unknown') != 1 THEN 1
            ELSE 0
        END,
    [Sql] = 'SELECT COUNT(*) FROM [<< Schema >>].[<< Table >>] WHERE [CityKey] = 0 AND [City] = ''Unknown'''