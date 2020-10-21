

/*ALTER TABLE OrderLine ADD COLUMN unitPrice DECIMAL(4,2);
ALTER TABLE OrderLine ADD COLUMN totalPrice DECIMAL(5,2);
ALTER TABLE `Order` ADD COLUMN totalPrice DECIMAL(5,2);*/

\upos
DROP PROCEDURE IF EXISTS spCalculateTotalsLoop;

DELIMITER //
CREATE PROCEDURE spCalculateTotalsLoop()

BEGIN
	BEGIN
		DECLARE flag INT DEFAULT FALSE;
		DECLARE var_orderID INT;
		DECLARE var_productID INT;
		DECLARE var_quantity INT;
		DECLARE var_unitPrice DECIMAL(4,2);
		DECLARE var_totalPrice DECIMAL(5,2);
		DECLARE cur1 CURSOR FOR SELECT orderID, productID, quantity, unitPrice FROM OrderLine;	
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag = TRUE;	
				
		UPDATE OrderLine ol
		INNER JOIN Product p ON p.id = ol.productID 
		SET unitPrice = price;
				
		OPEN cur1;
		totalPriceLoop: LOOP
				FETCH cur1 INTO var_orderID, var_productID, var_quantity, var_unitPrice;
				IF flag THEN
					LEAVE totalPriceLoop;
				END IF;
				SET var_totalPrice = var_unitPrice * var_quantity;
				
				UPDATE OrderLine SET totalPrice = var_totalPrice 
				WHERE orderID = var_orderID AND productID = var_productID;
				
			END LOOP;
		CLOSE cur1;
	END;
	
	BEGIN
		DECLARE flag INT DEFAULT FALSE;
		DECLARE var_id INT;
		DECLARE tempTotal DECIMAL(5,2) DEFAULT 0;
		DECLARE cur1 CURSOR FOR SELECT id FROM `Order`;	
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag = TRUE;	
		
		OPEN cur1;
			orderLoop: LOOP
				FETCH cur1 INTO var_id;
				IF flag THEN
					LEAVE orderLoop;
				END IF;
				
				BEGIN
					DECLARE flag1 INT DEFAULT FALSE;
					DECLARE var_oTotalPrice DECIMAL(5,2);
					DECLARE cur2 CURSOR FOR SELECT totalPrice FROM OrderLine WHERE orderID  = var_id;	
					DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag1 = TRUE;	
				
					OPEN cur2;
						oTotalPriceLoop: LOOP
							FETCH cur2 INTO var_oTotalPrice;
							IF flag1 THEN
								LEAVE oTotalPriceLoop;
							END IF;
							SET tempTotal = tempTotal + var_oTotalPrice;
						END LOOP;
					CLOSE cur2;
					UPDATE `Order` SET totalPrice = tempTotal WHERE id = var_id;
				END;
				SET tempTotal=0;
			END LOOP;
		CLOSE cur1;
	END;
END//	

DELIMITER ;

DROP PROCEDURE IF EXISTS spCalculateTotalsSet;

DELIMITER //
CREATE PROCEDURE spCalculateTotalsSet()
BEGIN

	UPDATE OrderLine ol
	INNER JOIN Product p ON p.id = ol.productID 
	SET unitPrice = price;
	
	UPDATE OrderLine 
	SET totalPrice = unitPrice * quantity;
	
	UPDATE `Order` o
	SET o.totalPrice = (select SUM(totalPrice) FROM OrderLine ol WHERE ol.orderID = o.id);
	
END//	
DELIMITER ;

DROP PROCEDURE IF EXISTS spFillMVProductCustomers;

DELIMITER //
CREATE PROCEDURE spFillMVProductCustomers()
BEGIN
	
	
	DELETE FROM mv_ProductCustomers;
	
	INSERT INTO mv_ProductCustomers 
	SELECT app, p.id AS "productID", GROUP_CONCAT(DISTINCT CONCAT(lastName, " ", firstName) ORDER BY lastName, firstName separator', ') AS "customers"
	FROM Product p
	LEFT OUTER JOIN OrderLine ol ON p.id = ol.productID
	LEFT OUTER JOIN `Order` o ON ol.orderID = o.id
	LEFT OUTER JOIN Customer c ON o.customerID = c.id 
	GROUP BY 2;
	
END//	
DELIMITER ;

DROP PROCEDURE IF EXISTS spGenerateInvoice;
DELIMITER //
CREATE PROCEDURE spGenerateInvoice(IN orderID INT)
BEGIN

	SELECT "Invoice Summary" AS "", o.id AS "Order ID",  CONCAT(lastName, ", ", firstName) AS "Customer Name",
    email AS "Email", address AS "Address", totalPrice AS "Bill Total"
	FROM `Order` o INNER JOIN Customer c ON o.id = c.id
	WHERE o.id = orderID;    
	
	SELECT @sno:=@sno+1 "Invoice Details", app AS "App", unitPrice AS "Unit Price", quantity AS "Quantity", ol.totalPrice AS "Item Total"
    FROM (SELECT @sno:=0) srno, 
    `Order` o INNER JOIN OrderLine ol ON o.id = ol.orderID
    INNER JOIN Product p ON ol.productID = p.id
    where o.id = orderID
    UNION
    SELECT "Totals", "-", "-", sum(quantity), sum(ol.totalPrice)
    FROM `Order` o INNER JOIN OrderLine ol ON o.id = ol.orderID
    INNER JOIN Product p ON ol.productID = p.id
    where o.id = orderID;
    
END//	
DELIMITER ;

/*ALTER TABLE Product ADD COLUMN available BOOLEAN DEFAULT TRUE;

ALTER TABLE `Order` ADD COLUMN status ENUM('pending', 'placed', 'backordered', 'shipped', 'cancelled') DEFAULT 'pending';*/