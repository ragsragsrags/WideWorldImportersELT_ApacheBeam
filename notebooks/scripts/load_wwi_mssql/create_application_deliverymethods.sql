IF NOT EXISTS 
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

    CREATE TABLE [<< Schema >>].[<< Table >>]
    (
        [DeliveryMethodID] INT NOT NULL,
        [DeliveryMethodName] NVARCHAR(50) NOT NULL,
        [LastEditedBy] INT NOT NULL,
        [ValidFrom] DATETIME2(6) NOT NULL,
        [ValidTo] DATETIME2(6) NOT NULL, 
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;

DELETE 
    [<< Schema >>].[<< Table >>] 
WHERE
    LoadDate > (
		SELECT
			MAX([LoadDate])
		FROM
			[<< LHSchema >>].[<< LHTable >>]
		WHERE
			[TableName] = '<< TableName >>' AND
			[Status] = 'Successful'
	);