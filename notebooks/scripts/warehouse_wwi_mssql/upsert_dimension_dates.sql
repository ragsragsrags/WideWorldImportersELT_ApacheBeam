DECLARE @Date DATE = CAST('<< LastCutoffDate >>' AS DATE)
DECLARE @NewCutoffDate DATE = CAST('<< NewCutoffDate >>' AS DATE)
DECLARE @Dates NVARCHAR(MAX) = ''

WHILE (
	DATEADD(DAY, 1, @Date) <= CAST(DATEADD(DAY, 30, @NewCutoffDate) AS DATE)
)
BEGIN

	SET @Date = DATEADD(DAY, 1, @Date)

    SET @Dates = @Dates + CAST(@Date AS NVARCHAR) + ','

END

INSERT INTO [dbo].[DimDates]
(
    [Date],
    [DayNumber],
    [Day],
    [Month],
    [ShortMonth],
    [CalendarMonthNumber],
    [CalendarMonthLabel],
    [CalendarYear],
    [CalendarYearLabel],
    [FiscalMonthNumber],
    [FiscalMonthLabel],
    [FiscalYear],
    [FiscalYearLabel],
    [ISOWeekNumber],
    [LoadDate]
)
SELECT
    D.[Date],
    DAY(D.[Date]),
    CAST(DATENAME(DAY, D.[Date]) AS NVARCHAR(10)),
    CAST(DATENAME(MONTH, D.[Date]) AS NVARCHAR(10)),
    CAST(SUBSTRING(DATENAME(MONTH, D.[Date]), 1, 3) AS NVARCHAR(3)),
    MONTH(D.[Date]),
    CAST(N'CY' + CAST(YEAR(D.[Date]) AS NVARCHAR(4)) + N'-' + SUBSTRING(DATENAME(MONTH, D.[Date]), 1, 3) AS nvarchar(10)),
    YEAR(D.[Date]),
    CAST(N'CY' + CAST(YEAR(D.[Date]) AS nvarchar(4)) AS nvarchar(10)),
    CASE WHEN MONTH(D.[Date]) IN (11, 12)
        THEN MONTH(D.[Date]) - 10
        ELSE MONTH(D.[Date]) + 2
    END,
    CAST(N'FY' + CAST(CASE WHEN MONTH(D.[Date]) IN (11, 12)
                            THEN YEAR(D.[Date]) + 1
                            ELSE YEAR(D.[Date])
                    END AS NVARCHAR(4)) + N'-' + SUBSTRING(DATENAME(month, D.[Date]), 1, 3) AS nvarchar(20)),
    CASE WHEN MONTH(D.[Date]) IN (11, 12)
        THEN YEAR(D.[Date]) + 1
        ELSE YEAR(D.[Date])
    END,
    CAST(N'FY' + CAST(CASE WHEN MONTH(D.[Date]) IN (11, 12)
                            THEN YEAR(D.[Date]) + 1
                            ELSE YEAR(D.[Date])
                    END AS NVARCHAR(4)) AS NVARCHAR(10)),
    DATEPART(ISO_WEEK, D.[Date]),
    @NewCutoffDate
FROM
    (
        SELECT
            [Date] = CAST([value] AS [Date])
        FROM
            string_split(@dates, ',') D LEFT JOIN
            [dbo].[DimDates] DD ON
                CAST([value] AS [Date]) = DD.[Date]
        WHERE
            D.[value] != '' AND
            DD.[Date] IS NULL
    ) D