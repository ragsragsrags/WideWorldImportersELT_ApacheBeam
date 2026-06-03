DECLARE StartDate DATE;
DECLARE NewCutoffDate DATE;
DECLARE Dates STRING;
SET StartDate = CAST(SUBSTR('<< LastCutoffDate >>', 1, 10) AS DATE);
SET NewCutoffDate = CAST(SUBSTR('<< NewCutoffDate >>', 1, 10) AS DATE);
SET Dates = '';

BEGIN
    WHILE DATE_ADD(StartDate, INTERVAL 1 DAY) <= DATE_ADD(NewCutoffDate, INTERVAL 30 DAY) DO

        SET StartDate = DATE_ADD(StartDate, INTERVAL 1 DAY);
        SET Dates = CONCAT(Dates, CAST(StartDate AS STRING), ',');

    END WHILE;
END;

CREATE TEMP TABLE TempDates AS
WITH dates AS (
    SELECT 
        SPLIT(Dates, ',') AS dates_array
)

SELECT
    CAST(Date AS DATE) AS Date
FROM
    dates, UNNEST(dates_array) AS Date
WHERE
    Date != '';

SELECT
    *
FROM
    TempDates;

INSERT INTO {{ DimDates }}
(
    Date,
    DayNumber,
    Day,
    Month,
    ShortMonth,
    CalendarMonthNumber,
    CalendarMonthLabel,
    CalendarYear,
    CalendarYearLabel,
    FiscalMonthNumber,
    FiscalMonthLabel,
    FiscalYear,
    FiscalYearLabel,
    ISOWeekNumber,
    LoadDate
)
SELECT
    D.Date,
    EXTRACT(DAY FROM D.Date) AS DayNumber,
    CAST(EXTRACT(DAY FROM D.Date) AS STRING) AS Day,
    FORMAT_DATE('%B', D.Date) AS Month,
    SUBSTR(FORMAT_DATE('%B', D.Date), 1, 3) AS ShortMonth,
    EXTRACT(MONTH FROM D.Date) AS CalendarMonthNumber,
    CONCAT(
        'CY', 
        EXTRACT(YEAR FROM D.Date), 
        '-',
        SUBSTR(FORMAT_DATE('%B', D.Date), 1, 3)
    ) AS CalendarMonthLabel,
    EXTRACT(Year FROM D.Date) AS CalendarYear,
    CONCAT(
        'CY',
        EXTRACT(YEAR FROM D.Date)
    ) AS CalendarYearLabel,
    CASE 
        WHEN EXTRACT(MONTH FROM D.Date) IN (11, 12) THEN EXTRACT(MONTH FROM D.Date) - 10
        ELSE EXTRACT(MONTH FROM D.Date) + 2
    END AS FiscalMonthNumber,
    CONCAT(
        'FY',
        CAST(
            CASE 
                WHEN EXTRACT(MONTH FROM D.Date) IN (11, 12) THEN EXTRACT(YEAR FROM D.Date) + 1
                ELSE EXTRACT(YEAR FROM D.Date)
            END AS STRING
        ),
        '-',
        SUBSTR(FORMAT_DATE('%B', D.Date), 1, 3)
    ) AS FiscalMonthLabel,
    CASE 
        WHEN EXTRACT(MONTH FROM D.Date) IN (11, 12) THEN EXTRACT(YEAR FROM D.Date) + 1
        ELSE EXTRACT(YEAR FROM D.Date)
    END AS FiscalYear,
    CONCAT(
        'FY',
        CAST(
            CASE 
                WHEN EXTRACT(MONTH FROM D.Date) IN (11, 12) THEN EXTRACT(YEAR FROM D.Date) + 1
                ELSE EXTRACT(YEAR FROM D.Date)
            END AS STRING
        )
    ) AS FiscalYearLabel,
    EXTRACT(ISOWEEK FROM D.Date) AS ISOWeekNumber,
    CAST('<< NewCutoffDate >>' AS DATETIME)
FROM
    TempDates D LEFT JOIN
    {{ DimDates }} DD ON
        D.Date = DD.Date
WHERE
    DD.Date IS NULL;