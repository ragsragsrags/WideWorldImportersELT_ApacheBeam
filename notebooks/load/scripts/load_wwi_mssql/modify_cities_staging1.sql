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

    DROP TABLE [<< Schema >>].[<< Table >>]

	END

CREATE TABLE [<< Schema >>].[<< Table >>] 
(
    [CityID] INT, 
    [NewColumn] NVARCHAR(50) NOT NULL,
	[ValidFrom] [datetime2](7) NOT NULL,
    [ValidTo] [datetime2](7) NOT NULL 
)