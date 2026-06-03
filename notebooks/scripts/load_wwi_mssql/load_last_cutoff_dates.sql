IF EXISTS 
(
	SELECT 
		1 
	FROM
		INFORMATION_SCHEMA.TABLES T  
	WHERE
		T.TABLE_CATALOG = '<< Database >>' AND
		T.TABLE_SCHEMA = '<< Schema >>' AND
		T.TABLE_NAME = '<< Table >>'
)
	BEGIN

        SELECT
            TableName,
            CAST(MAX(LoadDate) AS DATETIME2(6)) AS LastCutoffDate
        FROM
            [<< Schema >>].[<< Table >>]
        GROUP BY
            TableName
    
    END

ELSE
    BEGIN

        SELECT
            CAST(NULL AS NVARCHAR(50)) AS TableName,
            CAST(NULL AS DATETIME2(6)) AS LastCutoffDate
        WHERE
            1 = 0

    END