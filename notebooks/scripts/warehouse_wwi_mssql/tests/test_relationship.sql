SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = 'SELECT * FROM [<< Schema >>].[<< Table >>] WHERE [LoadDate] = ''<< LoadDate >>'' AND [<< Column >>] NOT IN (SELECT [<< ParentColumn >>] FROM {{ << ParentTable >> }}) '
FROM
    [<< Schema >>].[<< Table >>] 
WHERE
    [LoadDate] = '<< LoadDate >>' AND
    [<< Column >>] NOT IN
    (
        SELECT
            [<< ParentColumn >>]
        FROM
            {{ << ParentTable >> }}
    )