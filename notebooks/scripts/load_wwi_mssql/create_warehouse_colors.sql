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
        [ColorID] [int] NOT NULL,
        [ColorName] [nvarchar](20) NOT NULL,
        [LastEditedBy] [int] NOT NULL,
        [ValidFrom] [datetime2](6) NOT NULL,
        [ValidTo] [datetime2](6) NOT NULL, 
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