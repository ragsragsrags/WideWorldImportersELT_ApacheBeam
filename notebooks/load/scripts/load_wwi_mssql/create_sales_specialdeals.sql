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
        [SpecialDealID] [int] NOT NULL,
        [StockItemID] [int] NULL,
        [CustomerID] [int] NULL,
        [BuyingGroupID] [int] NULL,
        [CustomerCategoryID] [int] NULL,
        [StockGroupID] [int] NULL,
        [DealDescription] [nvarchar](30) NOT NULL,
        [StartDate] [date] NOT NULL,
        [EndDate] [date] NOT NULL,
        [DiscountAmount] [decimal](18, 2) NULL,
        [DiscountPercentage] [decimal](18, 3) NULL,
        [UnitPrice] [decimal](18, 2) NULL,
        [LastEditedBy] [int] NOT NULL,
        [LastEditedWhen] [datetime2](6) NOT NULL,
		[LoadDate] DATETIME2(6) NOT NULL
    )

	END;