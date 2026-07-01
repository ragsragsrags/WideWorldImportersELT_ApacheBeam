SELECT 
    COUNT(*)
FROM
    `<< Database >>.<< Schema >>.<< Table >>`
WHERE
    ValidFrom > '<< LastCutoffDate >>' AND	
    ValidFrom <= '<< NewCutoffDate >>'