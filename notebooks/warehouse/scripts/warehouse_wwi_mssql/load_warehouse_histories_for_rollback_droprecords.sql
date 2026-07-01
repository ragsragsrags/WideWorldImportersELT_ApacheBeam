SELECT 
    [TableName] = '<< Table >>',
    [SchemaName] = '<< Schema >>',
    [CountRecreateFromInitialDate] = (
        SELECT 
            COUNT(*)
        FROM 
            [<< Schema >>].[<< Table >>] 
        WHERE
            [LoadDate] > '<< LoadDate >>' AND
            [LastLoadDate] < '<< LoadDate >>'
    ),
    [CountRecreateFromLastCutoffDate] = (
        SELECT 
            COUNT(*)
        FROM 
            [<< Schema >>].[<< Table >>] 
        WHERE
            [LoadDate] > '<< LoadDate >>' AND
            [LastLoadDate] >= '<< LoadDate >>'
    )