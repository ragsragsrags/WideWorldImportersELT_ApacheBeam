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
		[PersonID] INT NOT NULL,
        [FullName] NVARCHAR(50) NOT NULL,
        [PreferredName] NVARCHAR(50) NOT NULL,
        [IsPermittedToLogon] [bit] NOT NULL,
        [LogonName] NVARCHAR(50) NULL,
        [IsExternalLogonProvider] [bit] NOT NULL,
        [HashedPassword] [varbinary](max) NULL,
        [IsSystemUser] [bit] NOT NULL,
        [IsEmployee] [bit] NOT NULL,
        [IsSalesperson] [bit] NOT NULL,
        [UserPreferences] NVARCHAR(max) NULL,
        [PhoneNumber] NVARCHAR(20) NULL,
        [FaxNumber] NVARCHAR(20) NULL,
        [EmailAddress] NVARCHAR(256) NULL,
        [Photo] [varbinary](max) NULL,
        [CustomFields] NVARCHAR(max) NULL,
        [LastEditedBy] INT NOT NULL,
        [ValidFrom] DATETIME2(7) NOT NULL,
        [ValidTo] DATETIME2(7) NOT NULL, 
		[LoadDate] DATETIME2(7) NOT NULL
	)

	END