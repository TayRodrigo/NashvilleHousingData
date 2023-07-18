Select *
From Projects..NV;


SELECT SaleDate
FROM Projects..NV;

---To start we are going to change the date of sale to more simple type

Select SaleDate, CONVERT(Date, SaleDate)
From Projects..NV;

--As this one didn't worked at the beginning, we will try this:
ALTER TABLE Projects..NV
ADD DateofSale date;

Update Projects..NV
Set DateofSale = CONVERT(Date, SaleDate) 

--And then, drop the old date
ALTER TABLE Projects..NV
DROP COLUMN SaleDate 

--Now we're checking de PropertyAddress

Select PropertyAddress
FROM Projects..NV
WHERE PropertyAddress is NULL

--As we know there are nulls, we'll check why and fix the problem

Select *
FROM Projects..NV
order by ParcelID
WHERE PropertyAddress is NULL;


SELECT *
FROM Projects..NV A, Projects..NV B
WHERE A.ParcelID = B.ParcelID 
AND A.UniqueID <> B.UniqueID
AND A.PropertyAddress is null

--So, with this query what we are doing is to replace every null value with the function isnull, so 
--that we replace the null value with something else, in this case with the adress with the PropertyAdress of the same table
--In this case we are using a self join to identify the nulls and replace them
Update A
Set A.PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM Projects..NV A, Projects..NV B
WHERE A.ParcelID = B.ParcelID 
AND A.UniqueID <> B.UniqueID
AND A.PropertyAddress is null


--Now let's check the propertyaddress so we can break it in thre columns: addresss, city and state

SELECT PropertyAddress
FROM Projects..NV

--We can do this in 2 ways, here we'll use the substring and charindex commands
--Substring helps us looking for some characters and charindex for the position o a certain command
--Also, to the length we're using -1/+1 to avoid the comma
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS ADDRESS,
SUBSTRING(PropertyAddress,  CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
FROM Projects..NV

--Now that we have the columns, let's create new ones so we can update the table

ALTER TABLE Projects..NV
ADD PropertySAddressv nvarchar(255), PropertySCity nvarchar(255)

UPDATE Projects..NV
SET PropertySAddressv = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

UPDATE Projects..NV
SET PropertySCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--The other way to go around this kind of issue is to use parsename and replace
-- as we know parsename only owrks with ".", so we hace to replace de commas with it
--So first, let's create the columns

ALTER TABLE Projects..nv
ADD OwnerSaddress nvarchar(255), OwnerSCity nvarchar(255), OwnerSState nvarchar(255)

--Now update
Update Projects..nv
SET 
OwnerSaddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
OwnerSCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),  
OwnerSState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 

SELECT *
from Projects..nv

--Now let's check the column sold as vacant

SELECT SoldAsVacant
FROM Projects..NV
group by SoldAsVacant

--As we can see, we have some values that are N instead of No and Y instead of Yes,
--So, let's change that, but in this case with the case command

Update Projects..NV
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' then 'Yes'
	 When SoldAsVacant = 'N' then 'No'
	 ELSE SoldAsVacant
	 END



--Now let's delete the rows that are duplicated
--In this case we'll use the command row number and a CTE


WITH ROWNUMBCTE AS (
SELECT *,
	ROW_NUMBER () OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 DateofSale,
				 LegalReference
				 ORDER BY
					UNIQUEID
					) ROW_NUM
FROM Projects..nv
)
SELECT *
FROM ROWNUMBCTE
WHERE ROW_NUM > 1
