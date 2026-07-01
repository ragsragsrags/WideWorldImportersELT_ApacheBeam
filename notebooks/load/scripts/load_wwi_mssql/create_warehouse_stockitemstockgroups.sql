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
        [StockItemStockGroupID] [int] NOT NULL,
        [StockItemID] [int] NOT NULL,
        [StockGroupID] [int] NOT NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](6) NOT NULL,
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;