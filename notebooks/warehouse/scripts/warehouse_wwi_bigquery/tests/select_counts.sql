SELECT 
    *
FROM
    (
        << SelectCountsSql >>
    ) E
WHERE
    ErrorCount > 0