SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = 'SELECT * FROM [<< Schema >>].[<< Table >>] WHERE [<< Column >>] IS NULL AND [LoadDate] <= ''<< LoadDate >>'''
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    [<< Column >>] IS NULL AND
    [LoadDate] <= '<< LoadDate >>'