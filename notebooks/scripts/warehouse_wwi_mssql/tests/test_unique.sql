SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = 'SELECT [<< Column >>], [Count] = COUNT(*) FROM [<< Schema >>].[<< Table >>] WHERE [LoadDate] = ''<< LoadDate >>'' GROUP BY [<< Column >>] HAVING COUNT(*) > 1'
FROM
    (
        SELECT
            [Count] = COUNT(*)
        FROM
            [<< Schema >>].[<< Table >>]
        WHERE
            [LoadDate] = '<< LoadDate >>'
        GROUP BY
            [<< Column >>]
        HAVING
            COUNT(*) > 1
    ) U