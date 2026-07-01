DECLARE MaxTransactionKey INT64;

SET MaxTransactionKey = 
(
    SELECT
        IFNULL(MAX(TransactionKey), 0)
    FROM
        {{ FctTransactions }}
);

CREATE TEMP TABLE TempFctTransactions AS
WITH mergedTransactions AS
(

	SELECT 
		CT.TransactionDate AS TransactionDate,
		COALESCE(I.CustomerID, CT.CustomerID) AS CustomerID,
		CT.CustomerID AS BillToCustomerID,
		CAST(NULL AS INTEGER) AS SupplierID,
		CT.TransactionTypeID AS TransactionTypeID,
		CT.PaymentMethodID AS PaymentMethodID,
		CT.CustomerTransactionID AS CustomerTransactionID,
		CAST(NULL AS INTEGER) AS SupplierTransactionID,
		CT.InvoiceID AS InvoiceID,
		CAST(NULL AS INTEGER) AS PurchaseOrderID,
		CAST(NULL AS STRING) AS SupplierInvoiceNumber,
		CT.AmountExcludingTax AS AmountExcludingTax,
		CT.TaxAmount AS TaxAmount,
		CT.TransactionAmount AS TransactionAmount,
		CT.OutstandingBalance AS OutstandingBalance,
		CT.IsFinalized AS IsFinalized,
		CT.LastEditedWhen AS LastEditedWhen
	FROM 
		{{ SalesCustomerTransactions }} CT LEFT JOIN 
		{{ SalesInvoices }} I ON 
			CT.InvoiceID = I.InvoiceID 
	WHERE 
		CT.LastEditedWhen > '<< LastCutoffDate >>' AND
		CT.LastEditedWhen <= '<< NewCutoffDate >>'
		
	UNION ALL
			
	SELECT 
		ST.TransactionDate,
		CAST(NULL AS INTEGER) AS CustomerID,
		CAST(NULL AS INTEGER) AS BillToCustomerID,
		ST.SupplierID AS SupplierID,
		ST.TransactionTypeID AS TransactionTypeID,
		ST.PaymentMethodID AS PaymentMethodID,
		CAST(NULL AS INTEGER) AS CustomerTransactionID,
		ST.SupplierTransactionID AS SupplierTransactionID,
		CAST(NULL AS INTEGER) AS InvoiceID,
		ST.PurchaseOrderID AS PurchaseOrderID,
		ST.SupplierInvoiceNumber AS SupplierInvoiceNumber,
		ST.AmountExcludingTax AS AmountExcludingTax,
		ST.TaxAmount AS TaxAmount,
		ST.TransactionAmount AS TransactionAmount,
		ST.OutstandingBalance AS OutstandingBalance,
		ST.IsFinalized AS IsFinalized,
		ST.LastEditedWhen AS LastEditedWhen
	FROM 
		{{ PurchasingSupplierTransactions }} ST 
	WHERE 
		ST.LastEditedWhen > '<< LastCutoffDate >>' AND
		ST.LastEditedWhen <= '<< NewCutoffDate >>'

),

final AS 
(

	SELECT 
		CASE
			WHEN FT.TransactionKey IS NULL THEN CAST(MaxTransactionKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY FT.TransactionKey, MT.TransactionDate))
			ELSE FT.TransactionKey
		END AS TransactionKey,
		CAST(MT.TransactionDate AS DATE) AS DateKey,
		C.CustomerKey AS CustomerKey,
		BC.CustomerKey AS BillToCustomerKey,
		S.SupplierKey AS SupplierKey,
		IFNULL(TT.TransactionTypeKey, 0) AS TransactionTypeKey,
		PM.PaymentMethodKey AS PaymentMethodKey,
		MT.CustomerTransactionID AS WWICustomerTransactionID,
		MT.SupplierTransactionID AS WWISupplierTransactionID,
		MT.InvoiceID AS WWIInvoiceID,
		MT.PurchaseOrderID AS WWIPurchaseOrderID,
		MT.SupplierInvoiceNumber AS SupplierInvoiceNumber,
		MT.AmountExcludingTax AS TotalExcludingTax,
		MT.TaxAmount AS TaxAmount,
		MT.TransactionAmount AS TotalIncludingTax,
		MT.OutstandingBalance AS OutstandingBalance,
		MT.IsFinalized AS IsFinalized,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE
			WHEN FT.TransactionKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
	FROM 
		mergedTransactions MT LEFT JOIN 
		{{ DimCustomers }} C ON 
			MT.CustomerID = C.WWICustomerID LEFT JOIN
		{{ DimCustomers }} BC ON
			MT.CustomerID = BC.WWICustomerID LEFT JOIN
		{{ DimTransactionTypes }} TT ON
			MT.TransactionTypeID = TT.WWITransactionTypeID LEFT JOIN
		{{ DimPaymentMethods }} PM ON
			MT.PaymentMethodID = PM.WWIPaymentMethodID LEFT JOIN
		{{ DimSuppliers }} S ON
			MT.SupplierID = S.WWISupplierID LEFT JOIN
		{{ FctTransactions }} FT ON
			IFNULL(FT.WWICustomerTransactionID, 0) = IFNULL(MT.CustomerTransactionID, 0) AND
			IFNULL(FT.WWISupplierTransactionID, 0) = IFNULL(MT.SupplierTransactionID, 0)
	WHERE 
		MT.LastEditedWhen > '<< LastCutoffDate >>' AND
		MT.LastEditedWhen <= '<< NewCutoffDate >>'

)

SELECT 
	*
FROM
	final;

-- Update Existing
UPDATE
	{{ FctTransactions }} T2
SET
	T2.DateKey = T.DateKey,
	T2.CustomerKey = T.CustomerKey,
	T2.BillToCustomerKey = T.BillToCustomerKey,
	T2.SupplierKey = T.SupplierKey,
	T2.TransactionTypeKey = T.TransactionTypeKey,
	T2.PaymentMethodKey = T.PaymentMethodKey,
	T2.WWIInvoiceID = T.WWIInvoiceID,
	T2.WWIPurchaseOrderID = T.WWIPurchaseOrderID,
	T2.SupplierInvoiceNumber = T.SupplierInvoiceNumber,
	T2.TotalExcludingTax = T.TotalExcludingTax,
	T2.TaxAmount = T.TaxAmount,
	T2.TotalIncludingTax = T.TotalIncludingTax,
	T2.OutstandingBalance = T.OutstandingBalance,
	T2.IsFinalized = T.IsFinalized,
	T2.LoadDate = T.LoadDate,
	T2.LastLoadDate = T2.LoadDate
FROM
	TempFctTransactions T
WHERE
	T.Exist = TRUE AND
	IFNULL(T2.WWICustomerTransactionID, 0) = IFNULL(T.WWICustomerTransactionID, 0) AND
	IFNULL(T2.WWISupplierTransactionID, 0) = IFNULL(T.WWISupplierTransactionID, 0);

-- Insert New
INSERT INTO {{ FctTransactions }}
(
	TransactionKey,
	DateKey,
	CustomerKey,
	BillToCustomerKey,
	SupplierKey,
	TransactionTypeKey,
	PaymentMethodKey,
	WWICustomerTransactionID,
	WWISupplierTransactionID,
	WWIInvoiceID,
	WWIPurchaseOrderID,
	SupplierInvoiceNumber,
	TotalExcludingTax,
	TaxAmount,
	TotalIncludingTax,
	OutstandingBalance,
	IsFinalized,
	LoadDate,
	LastLoadDate
)
SELECT
	T.TransactionKey,
	T.DateKey,
	T.CustomerKey,
	T.BillToCustomerKey,
	T.SupplierKey,
	T.TransactionTypeKey,
	T.PaymentMethodKey,
	T.WWICustomerTransactionID,
	T.WWISupplierTransactionID,
	T.WWIInvoiceID,
	T.WWIPurchaseOrderID,
	T.SupplierInvoiceNumber,
	T.TotalExcludingTax,
	T.TaxAmount,
	T.TotalIncludingTax,
	T.OutstandingBalance,
	T.IsFinalized,
	T.LoadDate,
	CAST(NULL AS DATETIME)
FROM
	TempFctTransactions T 
WHERE
	T.Exist = FALSE
ORDER BY
	T.TransactionKey;