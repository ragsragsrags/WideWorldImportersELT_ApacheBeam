CREATE TABLE IF NOT EXISTS `<< Database >>.<< Schema >>.<< Table >>` 
(
    PersonID INTEGER,
    FullName STRING,
    PreferredName STRING,
    IsPermittedToLogon BOOLEAN,
    LogonName STRING,
    IsExternalLogonProvider BOOLEAN,
    HashedPassword BYTES,
    IsSystemUser BOOLEAN,
    IsEmployee BOOLEAN,
    IsSalesperson BOOLEAN,
    UserPreferences STRING,
    PhoneNumber STRING,
    FaxNumber STRING,
    EmailAddress STRING,
    Photo BYTES,
    CustomFields STRING,
    LastEditedBy INTEGER,
    ValidFrom DATETIME,
    ValidTo DATETIME, 
    LoadDate DATETIME
);