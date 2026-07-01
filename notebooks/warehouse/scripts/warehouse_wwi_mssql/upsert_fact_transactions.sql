DECLARE @LastCutoffDate AS DATETIME2 = '2012-12-31'
DECLARE @NewCutoffDate AS DATETIME2 = '2013-01-01'
DECLARE @MaxTransactionKey INT 
    
SELECT
    @MaxTransactionKey = ISNULL(MAX(TransactionKey), 0)
FROM
    {{ FctTransactions }}

IF OBJECT_ID('tempdb..#FctTransactions') IS NOT NULL
    DROP TABLE #FctTransactions

;WITH mergedTransactions AS
(

	SELECT 
		[TransactionDate] = CT.TransactionDate,
		[CustomerID] = COALESCE(I.CustomerID, CT.CustomerID),
		[BillToCustomerID] = CT.CustomerID,
		[SupplierID] = CAST(NULL AS INT),
		[TransactionTypeID] = CT.TransactionTypeID,
		[PaymentMethodID] = CT.PaymentMethodID,
		[CustomerTransactionID] = CT.CustomerTransactionID,
		[SupplierTransactionID] = CAST(NULL AS INT),
		[InvoiceID] = CT.InvoiceID,
		[PurchaseOrderID] = CAST(NULL AS INT),
		[SupplierInvoiceNumber] = CAST(NULL AS NVARCHAR(20)),
		[AmountExcludingTax] = CT.AmountExcludingTax,
		[TaxAmount] = CT.TaxAmount,
		[TransactionAmount] = CT.TransactionAmount,
		[OutstandingBalance] = CT.OutstandingBalance,
		[IsFinalized] = CT.IsFinalized,
		[LastEditedWhen] = CT.LastEditedWhen
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
		[CustomerID] = CAST(NULL AS INT),
		[BillToCustomerID] = CAST(NULL AS INT),
		[SupplierID] = ST.SupplierID,
		[TransactionTypeID] = ST.TransactionTypeID,
		[PaymentMethodID] = ST.PaymentMethodID,
		[CustomerTransactionID] = CAST(NULL AS INT),
		[SupplierTransactionID] = ST.SupplierTransactionID,
		[InvoiceID] = CAST(NULL AS INT),
		[PurchaseOrderID] = ST.PurchaseOrderID,
		[SupplierInvoiceNumber] = ST.SupplierInvoiceNumber,
		[AmountExcludingTax] = ST.AmountExcludingTax,
		[TaxAmount] = ST.TaxAmount,
		[TransactionAmount] = ST.TransactionAmount,
		[OutstandingBalance] = ST.OutstandingBalance,
		[IsFinalized] = ST.IsFinalized,
		[LastEditedWhen] = ST.LastEditedWhen
	FROM 
		{{ PurchasingSupplierTransactions }} ST 
	WHERE 
		ST.LastEditedWhen > '<< LastCutoffDate >>' AND
		ST.LastEditedWhen <= '<< NewCutoffDate >>'

),

final AS 
(

	SELECT 
		[TransactionKey] = 
			CASE
				WHEN FT.TransactionKey IS NULL THEN @MaxTransactionKey + (ROW_NUMBER() OVER (ORDER BY FT.TransactionKey, MT.TransactionDate))
				ELSE FT.TransactionKey
			END,
		[DateKey] = CAST(MT.TransactionDate AS DATE),
		[CustomerKey] = C.CustomerKey,
		[BillToCustomerKey] = BC.CustomerKey,
		[SupplierKey] = S.SupplierKey,
		[TransactionTypeKey] = ISNULL(TT.TransactionTypeKey, 0),
		[PaymentMethodKey] = PM.PaymentMethodKey,
		[WWICustomerTransactionID] = MT.CustomerTransactionID,
		[WWISupplierTransactionID] = MT.SupplierTransactionID,
		[WWIInvoiceID] = MT.InvoiceID,
		[WWIPurchaseOrderID] = MT.PurchaseOrderID,
		[SupplierInvoiceNumber] = MT.SupplierInvoiceNumber,
		[TotalExcludingTax] = MT.AmountExcludingTax,
		[TaxAmount] = MT.TaxAmount,
		[TotalIncludingTax] = MT.TransactionAmount,
		[OutstandingBalance] = MT.OutstandingBalance,
		[IsFinalized] = MT.IsFinalized,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] = 
			CASE
				WHEN FT.TransactionKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
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
			ISNULL(FT.WWICustomerTransactionID, 0) = ISNULL(MT.CustomerTransactionID, 0) AND
			ISNULL(FT.WWISupplierTransactionID, 0) = ISNULL(MT.SupplierTransactionID, 0)
	WHERE 
		MT.LastEditedWhen > '<< LastCutoffDate >>' AND
		MT.LastEditedWhen <= '<< NewCutoffDate >>'

)

SELECT 
	*
INTO
	#FctTransactions
FROM
	Final

BEGIN TRAN

-- Update Existing
UPDATE
	T2
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
	#FctTransactions T JOIN
	{{ FctTransactions }} T2 ON
		ISNULL(T2.WWICustomerTransactionID, 0) = ISNULL(T.WWICustomerTransactionID, 0) AND
		ISNULL(T2.WWISupplierTransactionID, 0) = ISNULL(T.WWISupplierTransactionID, 0)
WHERE
	T.[Exists] = 1

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
	NULL
FROM
	#FctTransactions T 
WHERE
	T.[Exists] = 0
ORDER BY
	T.TransactionKey

COMMIT TRAN