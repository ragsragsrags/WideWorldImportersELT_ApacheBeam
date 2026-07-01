DELETE 
    [<< Schema >>].[<< Table >>] 
WHERE
    LoadDate > '<< LoadDate >>' AND
    NOT EXISTS (
        SELECT
            1
        FROM 
            [<< SchemaWH >>].[<< TableWH >>]
        WHERE 
            LoadDate > '<< LoadDate >>'
    )