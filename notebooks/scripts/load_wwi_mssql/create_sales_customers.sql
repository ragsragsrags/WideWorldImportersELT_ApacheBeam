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
        [CustomerID] [int] NOT NULL,
        [CustomerName] [nvarchar](100) NOT NULL,
        [BillToCustomerID] [int] NOT NULL,
        [CustomerCategoryID] [int] NOT NULL,
        [BuyingGroupID] [int] NULL,
        [PrimaryContactPersonID] [int] NOT NULL,
        [AlternateContactPersonID] [int] NULL,
        [DeliveryMethodID] [int] NOT NULL,
        [DeliveryCityID] [int] NOT NULL,
        [PostalCityID] [int] NOT NULL,
        [CreditLimit] [decimal](18, 2) NULL,
        [AccountOpenedDate] [date] NOT NULL,
        [StandardDiscountPercentage] [decimal](18, 3) NOT NULL,
        [IsStatementSent] [bit] NOT NULL,
        [IsOnCreditHold] [bit] NOT NULL,
        [PaymentDays] [int] NOT NULL,
        [PhoneNumber] [nvarchar](20) NOT NULL,
        [FaxNumber] [nvarchar](20) NOT NULL,
        [DeliveryRun] [nvarchar](5) NULL,
        [RunPosition] [nvarchar](5) NULL,
        [WebsiteURL] [nvarchar](256) NOT NULL,
        [DeliveryAddressLine1] [nvarchar](60) NOT NULL,
        [DeliveryAddressLine2] [nvarchar](60) NULL,
        [DeliveryPostalCode] [nvarchar](10) NOT NULL,
        [DeliveryLocation] [geography] NULL,
        [PostalAddressLine1] [nvarchar](60) NOT NULL,
        [PostalAddressLine2] [nvarchar](60) NULL,
        [PostalPostalCode] [nvarchar](10) NOT NULL,
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