SELECT
    [PersonID],
    [FullName],
    [PreferredName],
    [IsPermittedToLogon],
    [LogonName],
    [IsExternalLogonProvider],
    [HashedPassword],
    [IsSystemUser],
    [IsEmployee],
    [IsSalesperson],
    [UserPreferences],
    [PhoneNumber],
    [FaxNumber],
    [EmailAddress],
    [Photo],
    [CustomFields],
    [LastEditedBy],
    [ValidFrom],
    [ValidTo],
    [LoadDate] = CAST('<< NewCutoffDate >>' AS DATETIME2(6))
FROM
    [<< Schema >>].[<< Table >>]
WHERE
    ValidFrom > '<< LastCutoffDate >>'  AND	
    ValidFrom <= '<< NewCutoffDate >>'
ORDER BY
    PersonID,
    ValidFrom,
    ValidTo
    
OFFSET 0 ROW