DELETE 
    [<< Schema >>].[<< Table >>] 
WHERE
    LoadDate > '<< LoadDate >>' AND
    NOT EXISTS (
        SELECT
            1
        FROM
            [<< SchemaLH >>].[<< TableLH >>]
        WHERE
            LoadDate > '<< LoadDate >>'
    )