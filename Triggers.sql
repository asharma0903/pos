
\upos

DROP TRIGGER IF EXISTS calculateTotalsOnInsertNewOrder;

DELIMITER //
CREATE TRIGGER calculateTotalsOnInsertNewOrder
BEFORE INSERT ON OrderLine 
FOR EACH ROW
BEGIN
SET NEW.unitPrice = (SELECT price FROM Product WHERE id = NEW.productID);
SET NEW.totalPrice = NEW.unitPrice * NEW.quantity;

select COALESCE(totalPrice, 0) from `Order` WHERE id = NEW.orderID into @old_total;

UPDATE `Order` SET totalPrice = NEW.totalPrice + @old_total WHERE id = new.orderID;

END//
DELIMITER ;



DROP TRIGGER IF EXISTS calculateTotalsOnUpdateQty;

DELIMITER //
CREATE TRIGGER calculateTotalsOnUpdateQty
BEFORE UPDATE ON OrderLine 
FOR EACH ROW
BEGIN
SET NEW.unitPrice = (SELECT price FROM Product where id = NEW.productID);
SET NEW.totalPrice = NEW.unitPrice * NEW.quantity;

select COALESCE(totalPrice, 0) from `Order` where id = NEW.orderID into @old_total;

UPDATE `Order` SET totalPrice = NEW.totalPrice + @old_total - OLD.totalPrice where id = new.orderID;

END//
DELIMITER ;

DROP TRIGGER IF EXISTS refreshMvOnOrderLineInsert;
DELIMITER //
CREATE TRIGGER refreshMvOnOrderLineInsert
AFTER INSERT ON OrderLine
FOR EACH ROW
BEGIN
call spFillMVProductCustomers();
END//
DELIMITER ;



DROP TRIGGER IF EXISTS refreshMvOnOrderLineDelete;
DELIMITER //
CREATE TRIGGER refreshMvOnOrderLineDelete
AFTER DELETE ON OrderLine
FOR EACH ROW
BEGIN
call spFillMVProductCustomers();
END//
DELIMITER ;




DROP TRIGGER IF EXISTS updateOrdersOfUnavailableProduct;

DELIMITER //
CREATE TRIGGER updateOrdersOfUnavailableProduct
AFTER UPDATE ON Product 
FOR EACH ROW
BEGIN

IF (SELECT available FROM Product where id = NEW.id) = FALSE THEN

	DELETE OrderLine 
	FROM OrderLine JOIN `Order` ON id = orderID 
	WHERE productId = NEW.id  and STATUS = 'pending';

	UPDATE `Order` o
	SET o.totalPrice = (select SUM(totalPrice) FROM OrderLine ol WHERE ol.orderID = o.id);

END IF;
END//
DELIMITER ;


DROP TABLE IF EXISTS HistoricalPricing;
CREATE TABLE HistoricalPricing 
(
appID INT,
oldPrice DECIMAL(4,2),
newPrice DECIMAL(4,2),
updateTime DATETIME,
FOREIGN KEY(appID) REFERENCES Product(id)
	ON DELETE RESTRICT ON UPDATE RESTRICT
)ENGINE=InnoDB;


DROP TRIGGER IF EXISTS trackProductPrice;

DELIMITER //
CREATE TRIGGER trackProductPrice
BEFORE UPDATE ON Product 
FOR EACH ROW
BEGIN

IF(OLD.price != NEW.price) THEN
INSERT INTO HistoricalPricing values(NEW.id, OLD.price, NEW.price, now());
END IF;

END//
DELIMITER ;




