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
        [ValidFrom] [datetime2](7) NOT NULL,
        [ValidTo] [datetime2](7) NOT NULL, 
		[LoadDate] DATETIME2(7) NOT NULL
    )

	END