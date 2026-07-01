DECLARE MaxMovementKey INT64;

SET MaxMovementKey = 
(
    SELECT
        IFNULL(MAX(MovementKey), 0)
    FROM
        {{ FctMovements }}
);

CREATE TEMP TABLE TempFctMovements AS
WITH stockItemTransactions AS
(

	SELECT 
		FM.MovementKey,
		SIT.TransactionOccurredWhen,
		SIT.StockItemTransactionID,
		SIT.InvoiceID,
		SIT.PurchaseOrderID,
		CAST(SIT.Quantity AS INTEGER) AS Quantity,
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
		CASE 
			WHEN SIT.MovementKey IS NULL THEN CAST(MaxMovementKey AS INTEGER) + (ROW_NUMBER() OVER (ORDER BY SIT.MovementKey, SIT.StockItemTransactionID))
			ELSE SIT.MovementKey
		END AS MovementKey,
		CAST(SIT.TransactionOccurredWhen AS DATE) AS DateKey,
		IFNULL(SI.StockItemKey, 0) AS StockItemKey,
		IFNULL(C.CustomerKey, 0) AS CustomerKey,
		IFNULL(S.SupplierKey, 0) AS SupplierKey,
		TT.TransactionTypeKey AS TransactionTypeKey,
		SIT.StockItemTransactionID AS WWIStockItemTransactionID,
		SIT.InvoiceID AS WWIInvoiceID,
		SIT.PurchaseOrderID AS WWIPurchaseOrderID,
		SIT.Quantity AS Quantity,
		CAST('<< NewCutoffDate >>' AS DATETIME) AS LoadDate,
		CASE 
			WHEN SIT.MovementKey IS NULL THEN CAST(FALSE AS BOOLEAN)
			ELSE CAST(TRUE AS BOOLEAN)
		END AS Exist
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
FROM
	final;

-- Update Existing
UPDATE
	{{ FctMovements }} M2
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
	TempFctMovements M
WHERE
	M.Exist = TRUE AND
	M2.WWIStockItemTransactionID = M.WWIStockItemTransactionID;

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
	CAST(NULL AS DATETIME)
FROM
	TempFctMovements M
WHERE
	M.Exist = FALSE
ORDER BY
	M.WWIStockItemTransactionID;