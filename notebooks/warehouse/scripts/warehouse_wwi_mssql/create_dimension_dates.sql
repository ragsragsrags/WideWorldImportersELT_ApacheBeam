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
        [Date] [date] NOT NULL,
        [DayNumber] [int] NOT NULL,
        [Day] [nvarchar](10) NOT NULL,
        [Month] [nvarchar](10) NOT NULL,
        [ShortMonth] [nvarchar](3) NOT NULL,
        [CalendarMonthNumber] [int] NOT NULL,
        [CalendarMonthLabel] [nvarchar](20) NOT NULL,
        [CalendarYear] [int] NOT NULL,
        [CalendarYearLabel] [nvarchar](10) NOT NULL,
        [FiscalMonthNumber] [int] NOT NULL,
        [FiscalMonthLabel] [nvarchar](20) NOT NULL,
        [FiscalYear] [int] NOT NULL,
        [FiscalYearLabel] [nvarchar](10) NOT NULL,
        [ISOWeekNumber] [int] NOT NULL,
        [LoadDate] [datetime2](6) NOT NULL,
        [LastLoadDate] [datetime2](6) NULL,
        CONSTRAINT [PK_DimDates] PRIMARY KEY CLUSTERED 
        (
            [Date] ASC
        )
    ) 

    END;