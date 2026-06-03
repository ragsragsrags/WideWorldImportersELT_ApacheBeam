IF EXISTS (
    SELECT 
        1 
    FROM
        INFORMATION_SCHEMA.TABLES T  
    WHERE
        T.TABLE_CATALOG = '<< Database >>' AND
        T.TABLE_SCHEMA = '<< Schema >>' AND
        T.TABLE_NAME = '<< Table >>'
)
    SELECT CAST(1 AS BIT)
ELSE
    SELECT CAST(0 AS BIT)