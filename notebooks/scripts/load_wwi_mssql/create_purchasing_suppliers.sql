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
		[SupplierID] [int] NOT NULL,
        [SupplierName] [nvarchar](100) NOT NULL,
        [SupplierCategoryID] [int] NOT NULL,
        [PrimaryContactPersonID] [int] NOT NULL,
        [AlternateContactPersonID] [int] NOT NULL,
        [DeliveryMethodID] [int] NULL,
        [DeliveryCityID] [int] NOT NULL,
        [PostalCityID] [int] NOT NULL,
        [SupplierReference] [nvarchar](20) NULL,
        [BankAccountName] [nvarchar](50) NULL,
        [BankAccountBranch] [nvarchar](50) NULL,
        [BankAccountCode] [nvarchar](20) NULL,
        [BankAccountNumber] [nvarchar](20) NULL,
        [BankInternationalCode] [nvarchar](20) NULL,
        [PaymentDays] [int] NOT NULL,
        [InternalComments] [nvarchar](max) NULL,
        [PhoneNumber] [nvarchar](20) NOT NULL,
        [FaxNumber] [nvarchar](20) NOT NULL,
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
        [LoadDate] [datetime2](6) NOT NULL
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