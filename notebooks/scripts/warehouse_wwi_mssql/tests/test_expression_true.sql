SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = 'SELECT * FROM [<< Schema >>].[<< Table >>] WHERE [LoadDate] = ''<< LoadDate >>'' AND NOT (<< Expression >>)'
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    [LoadDate] = '<< LoadDate >>' AND
    NOT 
    (
        [<< Column >>] = << Expression >>
    )