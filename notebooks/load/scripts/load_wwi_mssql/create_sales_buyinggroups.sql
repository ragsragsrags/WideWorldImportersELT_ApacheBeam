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
		[BuyingGroupID] [int] NOT NULL,
        [BuyingGroupName] [nvarchar](50) NOT NULL,
        [LastEditedBy] [int] NOT NULL,
        [ValidFrom] [datetime2](6) NOT NULL,
        [ValidTo] [datetime2](6) NOT NULL, 
		LoadDate DATETIME2(6) NOT NULL
	)

	END;