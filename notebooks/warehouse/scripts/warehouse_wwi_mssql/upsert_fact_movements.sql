DECLARE @MaxMovementKey INT 
    
SELECT
    @MaxMovementKey = ISNULL(MAX(MovementKey), 0)
FROM
    {{ FctMovements }}

IF OBJECT_ID('tempdb..#FctMovements') IS NOT NULL
    DROP TABLE #FctMovements

;WITH stockItemTransactions AS
(

	SELECT 
		FM.MovementKey,
		SIT.TransactionOccurredWhen,
		SIT.StockItemTransactionID,
		SIT.InvoiceID,
		SIT.PurchaseOrderID,
		SIT.Quantity,
		SIT.StockItemID,
		SIT.CustomerID,
		SIT.SupplierID,
		SIT.TransactionTypeID
	FROM 
		{{ WarehouseStockItemTransactions }} AS SIT LEFT JOIN
		{{ FctMovements }} FM ON
			FM.WWIStockItemTransactionID = SIT.StockItemTransactionID
	WHERE 
		SIT.LastEditedWhen > '<< LastCutoffDate >>' AND
		SIT.LastEditedWhen <= '<< NewCutoffDate >>'

),

final AS 
(

	SELECT
		[MovementKey] =
			CASE 
				WHEN SIT.MovementKey IS NULL THEN @MaxMovementKey + (ROW_NUMBER() OVER (ORDER BY SIT.MovementKey, SIT.StockItemTransactionID))
				ELSE SIT.MovementKey
			END,
		[DateKey] = CAST(SIT.TransactionOccurredWhen AS DATE),
		[StockItemKey] = ISNULL(SI.StockItemKey, 0),
		[CustomerKey] = ISNULL(C.CustomerKey, 0),
		[SupplierKey] = ISNULL(S.SupplierKey, 0),
		[TransactionTypeKey] = TT.TransactionTypeKey,
		[WWIStockItemTransactionID] = SIT.StockItemTransactionID,
		[WWIInvoiceID] = SIT.InvoiceID,
		[WWIPurchaseOrderID] = SIT.PurchaseOrderID,
		[Quantity] = SIT.Quantity,
		[LoadDate] = '<< NewCutoffDate >>',
		[Exists] =
			CASE 
				WHEN SIT.MovementKey IS NULL THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END
	FROM 
		stockItemTransactions AS SIT LEFT JOIN
		{{ DimStockItems }} SI ON 
			SI.WWIStockItemID = SIT.StockItemID LEFT JOIN
		{{ DimCustomers }} C ON
			C.WWICustomerID = SIT.CustomerID LEFT JOIN
		{{ DimSuppliers }} S ON
			S.WWISupplierID = SIT.SupplierID LEFT JOIN
		{{ DimTransactionTypes }} TT ON
			TT.WWITransactionTypeID = SIT.TransactionTypeID

)

SELECT 
	*
INTO
	#FctMovements
FROM
	final

BEGIN TRAN

-- Update Existing
UPDATE
	M2
SET
	M2.DateKey = M.DateKey,
	M2.StockItemKey = M.StockItemKey,
	M2.CustomerKey = M.CustomerKey,
	M2.SupplierKey = M.SupplierKey,
	M2.TransactionTypeKey = M.TransactionTypeKey,
	M2.WWIStockItemTransactionID = M.WWIStockItemTransactionID,
	M2.WWIInvoiceID = M.WWIInvoiceID,
	M2.WWIPurchaseOrderID = M.WWIPurchaseOrderID,
	M2.Quantity = M.Quantity,
	M2.LoadDate = M.LoadDate,
	M2.LastLoadDate = M2.LoadDate
FROM
	#FctMovements M JOIN
	{{ FctMovements }} M2 ON
		M2.WWIStockItemTransactionID = M.WWIStockItemTransactionID
WHERE
	M.[Exists] = 1

-- Insert New
INSERT INTO {{ FctMovements }}
(
	MovementKey,
	DateKey,
	StockItemKey,
	CustomerKey,
	SupplierKey,
	TransactionTypeKey,
	WWIStockItemTransactionID,
	WWIInvoiceID,
	WWIPurchaseOrderID,
	Quantity,
	LoadDate,
	LastLoadDate
)
SELECT
	M.MovementKey,
	M.DateKey,
	M.StockItemKey,
	M.CustomerKey,
	M.SupplierKey,
	M.TransactionTypeKey,
	M.WWIStockItemTransactionID,
	M.WWIInvoiceID,
	M.WWIPurchaseOrderID,
	M.Quantity,
	M.LoadDate,
	NULL
FROM
	#FctMovements M LEFT JOIN
	{{ FctMovements }} M2 ON
		M2.WWIStockItemTransactionID = M.WWIStockItemTransactionID
WHERE
	M.[Exists] = 0
ORDER BY
	M.WWIStockItemTransactionID

COMMIT TRAN