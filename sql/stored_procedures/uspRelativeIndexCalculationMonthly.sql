IF OBJECT_ID('[dbo].[uspRelativeIndexCalculationMonthly]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[uspRelativeIndexCalculationMonthly]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspRelativeIndexCalculationMonthly]
(
@RelType INT,   --1 ,4 12  
@startDate date,    
@EndDate date,
@ProductID INT ,
@DistrType  char(1) ,
@Period int ,
@AuditUser int = -1,
@RelIndex  decimal(18,4) OUTPUT
)
AS
BEGIN
	DECLARE @oReturnValue as int 
	SET @oReturnValue = 0 
	BEGIN TRY

	DECLARE @locationId as int
	DECLARE @PrdValue as decimal(18,2)



	SELECT  @PrdValue = SUM(ISNULL(
	CAST(1+DATEDIFF(DAY,
		CASE WHEN @startDate >  PR.PayDate and  @startDate >  PL.EffectiveDate  THEN  @startDate  WHEN PR.PayDate > PL.EffectiveDate THEN PR.PayDate ELSE  PL.EffectiveDate  END
		,CASE WHEN PL.ExpiryDate < @EndDate THEN PL.ExpiryDate ELSE @EndDate END)
		as decimal(18,4)) * PR.Amount / NULLIF(DATEDIFF (DAY,(CASE WHEN PR.PayDate > PL.EffectiveDate THEN PR.PayDate ELSE  PL.EffectiveDate  END), PL.ExpiryDate ), 0)
	 ,0))
	FROM tblPremium PR INNER JOIN tblPolicy PL ON PR.PolicyID = PL.PolicyID
	INNER JOIN tblProduct Prod ON PL.ProdID = Prod.ProdID 
	LEFT JOIN tblLocations L ON ISNULL(Prod.LocationId,-1) = ISNULL(L.LocationId,-1)
	WHERE PR.ValidityTo IS NULL
	AND PL.ValidityTo IS NULL
	AND Prod.ValidityTo IS  NULL
	AND (Prod.ProdID = @ProductID OR @ProductId = 0)
	AND PL.PolicyStatus <> 1
	AND PR.PayDate < PL.ExpiryDate
	AND PL.EffectiveDate < PL.ExpiryDate
	AND PL.ExpiryDate >= @startDate
	AND (PR.PayDate <=  @EndDate AND PL.EffectiveDate <= @EndDate) 

	if @locationId is null and @ProductID is not null
		select @locationId = isnull(locationId,0) FROM tblProduct where ProdID=@ProductID

	EXEC  @oReturnValue =[dbo].[uspInsertIndexMonthly] @Type = @DistrType,
		@RelType = @RelType, 
		@startDate = @startDate, 
		@EndDate = @EndDate, 
		@Period = @Period,
		@LocationId = @locationId ,
		@ProductID = @ProductID ,
		@PrdValue = @PrdValue ,
		@AuditUser = @AuditUser , 
		@RelIndex =  @RelIndex OUTPUT;


FINISH:
	
	RETURN @oReturnValue
END TRY
	
	BEGIN CATCH
		SELECT 'uspRelativeIndexCalculationMonthly',
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage
		SET @oReturnValue = 1 
		SET @RelIndex = 0.0
		RETURN @oReturnValue
		
	END CATCH
	
END
GO
