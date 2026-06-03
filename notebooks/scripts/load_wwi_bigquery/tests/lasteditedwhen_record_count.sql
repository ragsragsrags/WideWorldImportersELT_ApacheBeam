SELECT 
    COUNT(*)
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    LastEditedWhen > '<< LastCutoffDate >>' AND	
    LastEditedWhen <= '<< NewCutoffDate >>'