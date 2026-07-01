DELETE 
    `<< Database >>.<< Schema >>.<< Table >>` 
WHERE
    LoadDate > '<< LoadDate >>'  AND
    NOT EXISTS (
        SELECT
            1
        FROM 
            `<< Database >>.<< SchemaWH >>.<< TableWH >>`
        WHERE 
            LoadDate > '<< LoadDate >>'
    )