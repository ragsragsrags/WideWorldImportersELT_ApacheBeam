DELETE 
    `<< Database >>.<< Schema >>.<< Table >>` 
WHERE
    LoadDate > '<< LoadDate >>' AND
    NOT EXISTS (
        SELECT
            1
        FROM
            `<< Database >>.<< SchemaLH >>.<< TableLH >>`
        WHERE
            LoadDate > '<< LoadDate >>'
    )