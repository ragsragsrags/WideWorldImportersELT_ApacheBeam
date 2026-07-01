SELECT 
    '<< Table >>' AS TableName,
    '<< Schema >>' AS SchemaName,
    (
        SELECT 
            COUNT(*)
        FROM 
            `<< Database >>.<< Schema >>.<< Table >>`
        WHERE
            LoadDate > '<< LoadDate >>' AND
            LastLoadDate < '<< LoadDate >>'
    ) AS CountRecreateFromInitialDate,
    (
        SELECT 
            COUNT(*)
        FROM 
            `<< Database >>.<< Schema >>.<< Table >>`
        WHERE
            LoadDate > '<< LoadDate >>' AND
            LastLoadDate >= '<< LoadDate >>'
    ) AS CountRecreateFromLastCutoffDate