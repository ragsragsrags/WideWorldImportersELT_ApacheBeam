SELECT
    [Name] = '<< Name >>',
    [Type] = '<< Type >>',
    [SubType] = '<< SubType >>',
    [Column] = '<< Column >>',
    [ErrorCount] = COUNT(*),
    [Sql] = 'SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS T WHERE T.TABLE_CATALOG = ''<< Database >>'' AND T.TABLE_SCHEMA = ''<< Schema >>'' AND T.TABLE_NAME = ''<< Table >>'' AND T.COLUMN_NAME = ''IsOnCreditHold'''
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    EXISTS (
        SELECT 
            1 
        FROM
            INFORMATION_SCHEMA.COLUMNS T  
        WHERE
            T.TABLE_CATALOG = '<< Database >>' AND
            T.TABLE_SCHEMA = '<< Schema >>' AND
            T.TABLE_NAME = '<< Table >>' AND
            T.COLUMN_NAME = 'IsOnCreditHold'
    )