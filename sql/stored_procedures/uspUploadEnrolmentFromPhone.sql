IF OBJECT_ID('[dbo].[uspUploadEnrolmentFromPhone]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[uspUploadEnrolmentFromPhone]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[uspUploadEnrolmentFromPhone]
(
	@xml XML,
	@OfficerId INT,
	@AuditUserId INT,
	@ErrorMessage NVARCHAR(300) = N'' OUTPUT
)
AS
BEGIN
    
	/*=========ERROR CODES==========
	-400	:Uncaught exception
	0	:	All okay
	-1	:	Given family has no HOF
	-2	:	Insurance number of the HOF already exists
	-3	:	Duplicate Insurance number found
	-4	:	Duplicate receipt found
	*/
	TRY --THE MAIN TRY
		--Create table variables
		--DECLARE @Result TABLE(ErrorMessage NVARCHAR(500))
		DECLARE @Family TABLE(FamilyId INT,InsureeId INT,LocationId INT, HOFCHFID nvarchar(50),Poverty BIT NULL,FamilyType NVARCHAR(2),FamilyAddress NVARCHAR(200), Ethnicity NVARCHAR(1), ConfirmationNo NVARCHAR(12), ConfirmationType NVARCHAR(3),isOffline INT)
		DECLARE @Insuree TABLE(InsureeId INT,FamilyId INT,CHFID NVARCHAR(50),LastName NVARCHAR(100),OtherNames NVARCHAR(100),DOB DATE,Gender CHAR(1),Marital CHAR(1),IsHead BIT,Passport NVARCHAR(25),Phone NVARCHAR(50),CardIssued BIT,Relationship SMALLINT,Profession SMALLINT,Education SMALLINT,Email NVARCHAR(100), TypeOfId NVARCHAR(1), HFID INT, CurrentAddress NVARCHAR(200), GeoLocation NVARCHAR(250), CurrentVillage INT, PhotoPath NVARCHAR(100), IdentificationNumber NVARCHAR(50),isOffline INT,EffectiveDate DATE)
		DECLARE @Policy TABLE(PolicyId INT,FamilyId INT,EnrollDate DATE,StartDate DATE,EffectiveDate DATE,ExpiryDate DATE,PolicyStatus TINYINT,PolicyValue DECIMAL(18,2),ProdId INT,OfficerId INT,PolicyStage CHAR(1),isOffline INT)
		DECLARE @Premium TABLE(PremiumId INT,PolicyId INT,PayerId INT,Amount DECIMAL(18,2),Receipt NVARCHAR(50),PayDate DATE,PayType CHAR(1),isPhotoFee BIT,isOffline INT)
		--DECLARE @InsureePolicy TABLE(InsureePolicyId INT, InsureeId INT,PolicyId INT, EnrollmentDate DATE,StartDate DATE, EffectiveDate DATE, ExpiryDate DATE,isOffline INT)
		--Insert data into table variable from XML
		INSERT INTO @Family(FamilyId, InsureeId, LocationId,HOFCHFID, Poverty, FamilyType, FamilyAddress, Ethnicity, ConfirmationNo, ConfirmationType,isOffline)
		SELECT 
		T.F.value('(FamilyId)[1]', 'INT'),
		T.F.value('(InsureeId)[1]', 'INT'),
		T.F.value('(LocationId)[1]', 'INT'),
		T.F.value('(HOFCHFID)[1]', 'NVARCHAR(50)'),
		T.F.value('(Poverty)[1]', 'BIT'),
		NULLIF(T.F.value('(FamilyType)[1]', 'NVARCHAR(2)'), ''),
		NULLIF(T.F.value('(FamilyAddress)[1]', 'NVARCHAR(200)'), ''),
		NULLIF(T.F.value('(Ethnicity)[1]', 'NVARCHAR(1)'), ''),
		NULLIF(T.F.value('(ConfirmationNo)[1]', 'NVARCHAR(12)'), ''),
		NULLIF(NULLIF(T.F.value('(ConfirmationType)[1]', 'NVARCHAR(4)'), 'null'), ''),
		T.F.value('(isOffline)[1]','INT')
		FROM @xml.nodes('Enrollment/Family') AS T(F);

	
		INSERT INTO @Insuree(InsureeId, FamilyId, CHFID, LastName, OtherNames, DOB, Gender, Marital, IsHead, Phone, CardIssued, Relationship, 
		Profession, Education, Email, TypeOfId, HFID, CurrentAddress, GeoLocation, CurrentVillage, PhotoPath, Passport,isOffline,EffectiveDate)
		SELECT 
		T.I.value('(InsureeId)[1]', 'INT'),
		T.I.value('(FamilyId)[1]', 'INT'),
		T.I.value('(CHFID)[1]', 'NVARCHAR(50)'),
		T.I.value('(LastName)[1]', 'NVARCHAR(100)'),
		T.I.value('(OtherNames)[1]', 'NVARCHAR(100)'),
		T.I.value('(DOB)[1]', 'DATE'),
		T.I.value('(Gender)[1]', 'CHAR(1)'),
		NULLIF(T.I.value('(Marital)[1]', 'CHAR(1)'), ''),
		T.I.value('(isHead)[1]', 'BIT'),
		NULLIF(T.I.value('(Phone)[1]', 'NVARCHAR(50)'), ''),
		ISNULL(NULLIF(T.I.value('(CardIssued)[1]', 'BIT'), ''), 0),
		NULLIF(T.I.value('(Relationship)[1]', 'INT'), ''),
		NULLIF(T.I.value('(Profession)[1]', 'INT'), ''),
		NULLIF(T.I.value('(Education)[1]', 'INT'), ''),
		NULLIF(T.I.value('(Email)[1]', 'NVARCHAR(100)'), ''),
		NULLIF(T.I.value('(TypeOfId)[1]', 'NVARCHAR(1)'), ''),
		NULLIF(T.I.value('(HFID)[1]', 'INT'), ''),
		NULLIF(T.I.value('(CurrentAddress)[1]', 'NVARCHAR(200)'), ''),
		NULLIF(T.I.value('(GeoLocation)[1]', 'NVARCHAR(250)'), ''),
		NULLIF(T.I.value('(CurVillage)[1]', 'INT'), ''),
		NULLIF(T.I.value('(PhotoPath )[1]', 'NVARCHAR(100)'), ''),
		NULLIF(T.I.value('(IdentificationNumber)[1]', 'NVARCHAR(50)'), ''),
		T.I.value('(isOffline)[1]','INT'),
		CASE WHEN T.I.value('(EffectiveDate)[1]', 'DATE')='1900-01-01' THEN NULL ELSE T.I.value('(EffectiveDate)[1]', 'DATE') END
		FROM @xml.nodes('Enrollment/Insuree') AS T(I)

		
		INSERT INTO @Policy(PolicyId, FamilyId, EnrollDate, StartDate, EffectiveDate, ExpiryDate, PolicyStatus, PolicyValue, ProdId, OfficerId, PolicyStage,isOffline)
		SELECT 
		T.P.value('(PolicyId)[1]', 'INT'),
		T.P.value('(FamilyId)[1]', 'INT'),
		T.P.value('(EnrollDate)[1]', 'DATE'),
		NULLIF(T.P.value('(StartDate)[1]', 'DATE'), ''),
		NULLIF(T.P.value('(EffectiveDate)[1]', 'DATE'), ''),
		NULLIF(T.P.value('(ExpiryDate)[1]', 'DATE'), ''),
		T.P.value('(PolicyStatus)[1]', 'INT'),
		NULLIF(T.P.value('(PolicyValue)[1]', 'DECIMAL'), 0),
		T.P.value('(ProdId)[1]', 'INT'),
		T.P.value('(OfficerId)[1]', 'INT'),
		ISNULL(NULLIF(T.P.value('(PolicyStage)[1]', 'CHAR(1)'), ''), N'N'),
		T.P.value('(isOffline)[1]','INT')
		FROM @xml.nodes('Enrollment/Policy') AS T(P)

		INSERT INTO @Premium(PremiumId, PolicyId, PayerId, Amount, Receipt, PayDate, PayType, isPhotoFee,isOffline)
		SELECT 
		T.PR.value('(PremiumId)[1]', 'INT'),
		T.PR.value('(PolicyId)[1]', 'INT'),
		NULLIF(T.PR.value('(PayerId)[1]', 'INT'), 0),
		T.PR.value('(Amount)[1]', 'DECIMAL'),
		T.PR.value('(Receipt)[1]', 'NVARCHAR(50)'),
		T.PR.value('(PayDate)[1]', 'DATE'),
		T.PR.value('(PayType)[1]', 'CHAR(1)'),
		T.PR.value('(isPhotoFee)[1]', 'BIT'),
		T.PR.value('(isOffline)[1]','INT')
		FROM @xml.nodes('Enrollment/Premium') AS T(PR)

		
		

		DECLARE @FamilyId INT = 0,
				@HOFId INT = 0,
				@PolicyValue DECIMAL(18, 4),
				@ProdId INT,
				@PolicyStage CHAR(1),
				@EnrollDate DATE,
				@ErrorCode INT,
				@PolicyStatus INT,
				@PolicyId INT,
				
				@CurInsureeId INT,
				@CurIsOffline INT,
				@CurHFID NVARCHAR(50),
				@CurFamilyId INT,
				
				@GivenPolicyValue DECIMAL(18, 4),
				@NewPolicyId INT,
				@ReturnValue INT = 0;
		DECLARE @isOffline INT,
				@CHFID NVARCHAR(50)
			--PREMIUM
			DECLARE @PremiumID INT,
					@Contribution DECIMAL(18,2) ,
					@EffectiveDate DATE,
					@AssociatedPhotoFolder NVARCHAR(255)

		SET @AssociatedPhotoFolder=(SELECT AssociatedPhotoFolder FROM tblIMISDefaults)
		--TEMP tables
		--IF NOT  OBJECT_ID('TempFamily') IS NULL
		--DROP TABLE TempFamily
		--SELECT * INTO TempFamily FROM @Family
		--IF NOT OBJECT_ID('TempInsuree') IS NULL
		--DROP TABLE TempInsuree
		--SELECT * INTO TempInsuree FROM @Insuree
		--IF NOT OBJECT_ID('TempPolicy') IS NULL
		--DROP TABLE TempPolicy
		--SELECT * INTO TempPolicy FROM @Policy
		--IF NOT OBJECT_ID('TempPremium') IS NULL
		--DROP TABLE TempPremium
		--SELECT * INTO TempPremium FROM @Premium
		--RETURN
		--end temp tables
	--CHFID for HOF, Amani 14.12.2017
		DECLARE @HOFCHFID NVARCHAR(50) =''
			
		---Added by Amani to Grab CHFID of HED
		SELECT @HOFCHFID =HOFCHFID FROM @Family F 
		--END
		--<newchanges>
		--Validations
		IF NOT EXISTS(SELECT 1 FROM tblInsuree WHERE IsHead=1 AND CHFID=@HOFCHFID AND ValidityTo IS NULL)
		BEGIN--NEW FAMILY BEGIN
		---NEW FAMILY HERE
		BEGIN TRY

		--Amani Added 25.01.2018
		IF NOT EXISTS(SELECT 1 FROM @Insuree  WHERE IsHead = 1)
			BEGIN
			--RETURN -1;
			--Make the first insuree to be head if there is no HOF by Amani & Hiren 19/02/2018
			UPDATE @Insuree SET IsHead =1 WHERE InsureeId=(SELECT TOP 1 InsureeId FROM @Insuree)
			END
			
		--end added by Amani
		IF EXISTS(SELECT 1 FROM tblInsuree I 
				  INNER JOIN @Insuree dt ON dt.CHFID = I.CHFID AND ABS(dt.InsureeId) <> I.InsureeID
				  WHERE I.ValidityTo IS NULL AND dt.IsHead = 1 AND I.IsHead = 1)
			RETURN -2;

		IF EXISTS(SELECT 1 FROM tblInsuree I 
				  INNER JOIN @Insuree dt ON dt.CHFID = I.CHFID  AND dt.InsureeId <> I.InsureeID
				  WHERE I.ValidityTo IS NULL AND dt.isOffline = 1)
			RETURN -3;

		IF EXISTS(SELECT 1
					FROM @Premium dtPR
					INNER JOIN tblPremium PR ON PR.Receipt = dtPR.Receipt 
					INNER JOIN @Policy dtPL ON dtPL.PolicyId = dtPR.PolicyId
					INNER JOIN @Family dtF ON dtF.FamilyId = dtPL.FamilyID
					INNER JOIN tblVillages V ON V.VillageId = dtF.LocationId
					INNER JOIN tblWards W ON W.WardId = V.WardId
					INNER JOIN tblDistricts D ON D.DistrictId = W.DistrictId

					WHERE   dtPR.isOffline = 1
					AND PR.ValidityTo IS NULL)
			RETURN -4;
			--DROP TABLE Premium
			--SELECT * INTO Insuree FROM @Insuree
			--SELECT * INTO Policy FROM @Policy
			--SELECT * INTO Premium FROM @Premium
		BEGIN TRAN ENROLLFAMILY
		/****************************************************START INSERT FAMILY**********************************/


					
			SELECT @isOffline =F.isOffline, @CHFID=CHFID FROM @Family F
			INNER JOIN @Insuree I ON I.FamilyId =F.FamilyId
				
				IF EXISTS(SELECT 1 FROM @Family WHERE isOffline =1)
					BEGIN
						INSERT INTO tblFamilies(InsureeId, LocationId, Poverty, ValidityFrom, AuditUserId, isOffline, FamilyType,
						FamilyAddress, Ethnicity, ConfirmationNo, ConfirmationType)
						SELECT 0 InsureeId, LocationId, Poverty, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, FamilyType,
						FamilyAddress, Ethnicity, ConfirmationNo, ConfirmationType
						FROM @Family;
						SELECT @FamilyId = SCOPE_IDENTITY();
						UPDATE @Insuree SET FamilyId = @FamilyId
						UPDATE @Policy SET FamilyId =  @FamilyId
					END
			
				

		/****************************************************START INSERT INSUREE**********************************/
				SELECT @isOffline =I.isOffline, @CHFID=CHFID FROM @Insuree I
				
				--Insert insurees
				IF EXISTS(SELECT 1 FROM @Insuree WHERE isOffline = 1  )
						BEGIN
							DECLARE CurInsuree CURSOR FOR SELECT InsureeId, CHFID, isOffline,FamilyId FROM @Insuree WHERE isOffline = 1 --OR CHFID NOT IN (SELECT CHFID FROM tblInsuree WHERE ValidityTo IS NULL);
							OPEN CurInsuree
							FETCH NEXT FROM CurInsuree INTO @CurInsureeId, @CurHFID, @CurIsOffline, @CurFamilyId;
							WHILE @@FETCH_STATUS = 0
							BEGIN
							INSERT INTO tblInsuree(FamilyId, CHFID, LastName, OtherNames, DOB, Gender, Marital, IsHead, passport, Phone, CardIssued, ValidityFrom,
							AuditUserId, isOffline, Relationship, Profession, Education, Email, TypeOfId, HFID, CurrentAddress, GeoLocation, CurrentVillage)
							SELECT @CurFamilyId FamilyId, CHFID, LastName, OtherNames, DOB, Gender, Marital, IsHead, passport, Phone, CardIssued, GETDATE() ValidityFrom,
							@AuditUserId AuditUserId, 0 isOffline, Relationship, Profession, Education, Email, TypeOfId, HFID, CurrentAddress, GeoLocation, CurrentVillage
							FROM @Insuree WHERE InsureeId = @CurInsureeId;
							DECLARE @NewInsureeId  INT  =0
							SELECT @NewInsureeId = SCOPE_IDENTITY();
							IF @isOffline <> 1 AND @ReturnValue = 0 SET @ReturnValue = @NewInsureeId
							UPDATE @Insuree SET InsureeId = @NewInsureeId WHERE InsureeId = @CurInsureeId
							--Insert photo entry
							INSERT INTO tblPhotos(InsureeID,CHFID,PhotoFolder,PhotoFileName,OfficerID,PhotoDate,ValidityFrom,AuditUserID)
							SELECT I.InsureeId, I.CHFID, @AssociatedPhotoFolder + '\\' PhotoFolder, dt.PhotoPath, @OfficerId OfficerId, GETDATE() PhotoDate, GETDATE() ValidityFrom, @AuditUserId AuditUserId
							FROM tblInsuree I 
							INNER JOIN @Insuree dt ON dt.CHFID = I.CHFID
							--WHERE I.FamilyId = @CurFamilyId
							WHERE dt.InsureeId=@NewInsureeId
							AND ValidityTo IS NULL;

							--Update photoId in Insuree
							UPDATE I SET PhotoId = PH.PhotoId, I.PhotoDate = PH.PhotoDate
							FROM tblInsuree I
							INNER JOIN tblPhotos PH ON PH.InsureeId = I.InsureeId
							WHERE I.FamilyId = @CurFamilyId;
					FETCH NEXT FROM CurInsuree INTO @CurInsureeId, @CurHFID, @CurIsOffline, @CurFamilyId;
					END
					CLOSE CurInsuree
					DEALLOCATE CurInsuree;	
				
			
				
					
					
					--Get the id of the HOF and update Family
					--SELECT @HOFId = InsureeId FROM tblInsuree WHERE FamilyId = @FamilyId AND IsHead = 1
					SELECT @HOFId = InsureeId FROM @Insuree WHERE FamilyId = @FamilyId AND IsHead = 1
					UPDATE tblFamilies SET InsureeId = @HOFId WHERE Familyid = @FamilyId 
					
						END
				/****************************************************END INSERT INSUREE**********************************/



				/****************************************************END INSERT POLICIES**********************************/
				
				SELECT TOP 1 @isOffline = P.isOffline FROM @Policy P
				IF EXISTS(SELECT 1 FROM @Policy WHERE isOffline = 1)
				BEGIN		
					--INSERT POLICIES
						DECLARE CurOfflinePolicy CURSOR FOR SELECT PolicyId, ProdId, ISNULL(PolicyStage, N'N') PolicyStage, EnrollDate,FamilyId FROM @Policy WHERE isOffline = 1 OR PolicyId NOT IN (SELECT PolicyId FROM tblPolicy WHERE ValidityTo	 IS NULL);
						OPEN CurOfflinePolicy
							FETCH NEXT FROM CurOfflinePolicy INTO @PolicyId, @ProdId, @PolicyStage, @EnrollDate,@FamilyId;
							WHILE @@FETCH_STATUS = 0
							BEGIN

								EXEC @PolicyValue = uspPolicyValue @FamilyId,
																	@ProdId,
																	0,
																	@PolicyStage,
																	@EnrollDate,
																	0,
																	@ErrorCode OUTPUT;


								SELECT @GivenPolicyValue = PolicyValue, @PolicyStatus = PolicyStatus FROM @Policy WHERE PolicyId = @PolicyId;
								INSERT INTO tblPolicy(FamilyId, EnrollDate, StartDate, EffectiveDate, ExpiryDate, PolicyStatus, PolicyValue, 
								ProdId, OfficerId, ValidityFrom, AuditUserId, isOffline, PolicyStage)
								SELECT @FamilyId FamilyId, EnrollDate, StartDate, EffectiveDate, ExpiryDate, @PolicyStatus PolicyStatus, @PolicyValue PolicyValue, 
								ProdId, OfficerId, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, @PolicyStage PolicyStage
								FROM @Policy
								WHERE PolicyId = @PolicyId;

								SELECT @NewPolicyId = SCOPE_IDENTITY();
								UPDATE @Premium SET PolicyId = @NewPolicyId WHERE PolicyId = @PolicyId 
								IF @isOffline <> 1 AND @ReturnValue = 0  
									BEGIN
										SET @ReturnValue = @NewPolicyId;
										--AND isOffline = 0
									END
								--Insert policy Insuree
														
								;WITH IP AS
								(
								SELECT ROW_NUMBER() OVER(ORDER BY InsureeId)RNo,
								Prod.MemberCount,  I.InsureeID,PL.PolicyID,PL.EnrollDate,PL.StartDate,PL.ExpiryDate,PL.AuditUserID,I.isOffline
								FROM tblInsuree I
								INNER JOIN tblPolicy PL ON I.FamilyID = PL.FamilyID
								INNER JOIN tblProduct Prod ON PL.ProdId = Prod.ProdID
								WHERE(I.ValidityTo Is NULL)
								AND PL.ValidityTo IS NULL
								AND Prod.ValidityTo IS NULL
								AND PL.PolicyID = @NewPolicyId
								)
								INSERT INTO tblInsureePolicy(InsureeId,PolicyId,EnrollmentDate,StartDate,ExpiryDate,AuditUserId,isOffline)
								SELECT InsureeId, PolicyId, EnrollDate, StartDate, ExpiryDate, AuditUserId, @IsOffLine
								FROM IP
								WHERE RNo <= MemberCount;
								

								IF   EXISTS(SELECT 1 FROM @Premium WHERE isOffline = 1)
								BEGIN
									INSERT INTO tblPremium(PolicyId, PayerId, Amount, Receipt, PayDate, PayType, ValidityFrom, AuditUserId, isOffline, isPhotoFee)
									SELECT  PolicyId, PayerId, Amount, Receipt, PayDate, PayType, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, isPhotoFee 
									FROM @Premium
									WHERE PolicyId = @NewPolicyId;

									IF(@GivenPolicyValue >= @PolicyValue)
									BEGIN
										UPDATE tblInsureePolicy SET EffectiveDate = PL.EffectiveDate,StartDate = PL.StartDate, ExpiryDate = PL.ExpiryDate 
										FROM tblInsureePolicy I 
										INNER JOIN tblPolicy PL ON I.PolicyId = PL.PolicyId 
										WHERE I.ValidityTo IS NULL 
										AND PL.ValidityTo IS NULL 
										AND PL.PolicyId = @NewPolicyId;
									END
								END

		
								FETCH NEXT FROM CurOfflinePolicy INTO @PolicyId, @ProdId, @PolicyStage, @EnrollDate, @FamilyId;
						END
					CLOSE CurOfflinePolicy
					DEALLOCATE CurOfflinePolicy;
				END
	/****************************************************END INSERT POLICIES**********************************/
			
	/****************************************************START UPDATE PREMIUM**********************************/
		
		
						IF  EXISTS(SELECT 1 FROM @Premium dt 
									  LEFT JOIN tblPremium P ON P.PremiumId = dt.PremiumId 
										WHERE P.ValidityTo IS NULL AND dt.isOffline <> 1 AND P.PremiumId IS NULL)
							BEGIN
								--INSERTPREMIMIUN
									INSERT INTO tblPremium(PolicyId, PayerId, Amount, Receipt, PayDate, PayType, ValidityFrom, AuditUserId, isOffline, isPhotoFee)
												SELECT     PolicyId, PayerId, Amount, Receipt, PayDate, PayType, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, isPhotoFee 
												FROM @Premium
												WHERE @isOffline <> 1;
												SELECT @PremiumId = SCOPE_IDENTITY();
								IF @isOffline <> 1 AND ISNULL(@PremiumId,0) >0 AND @ReturnValue =0 SET @ReturnValue = @PremiumId
							END
						

	/****************************************************END INSERT PREMIUM**********************************/

		COMMIT TRAN ENROLLFAMILY;
		SET @ErrorMessage = '';
		RETURN @ReturnValue;
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0 ROLLBACK TRAN ENROLLFAMILY;
		RETURN -400;
	END CATCH
		SELECT 1
		END
		ELSE
		BEGIN---BEGIN EXISTING  FAMILY
	BEGIN TRY
	
		
		--IF   EXISTS(SELECT 1 FROM @Insuree WHERE IsHead = 0 AND isOffline = 1)
		--BEGIN
		--	UPDATE @Insuree SET IsHead = 1 WHERE InsureeId = (SELECT TOP 1 InsureeId FROM @Insuree ORDER BY InsureeId)
		--END

		--Amani Added 25.01.2018
		--IF NOT EXISTS(SELECT 1 FROM tblInsuree I 
		--		  INNER JOIN @Insuree dt ON dt.FamilyId = I.FamilyId
		--		  WHERE I.ValidityTo IS NULL AND I.IsHead = 1)
		--	RETURN -1;
		--end added by Amani
		IF EXISTS(SELECT 1 FROM tblInsuree I 
				  INNER JOIN @Insuree dt ON dt.CHFID = I.CHFID AND ABS(dt.InsureeId) <> I.InsureeID
				  WHERE I.ValidityTo IS NULL AND dt.IsHead = 1 AND I.IsHead = 1)
			RETURN -2;

		IF EXISTS(SELECT 1 FROM tblInsuree I 
				  INNER JOIN @Insuree dt ON dt.CHFID = I.CHFID  AND dt.InsureeId <> I.InsureeID
				  WHERE I.ValidityTo IS NULL AND dt.isOffline = 1)
			RETURN -3;

		IF EXISTS(SELECT 1
					FROM @Premium dtPR
					INNER JOIN tblPremium PR ON PR.Receipt = dtPR.Receipt 
					INNER JOIN @Policy dtPL ON dtPL.PolicyId = dtPR.PolicyId
					INNER JOIN @Family dtF ON dtF.FamilyId = dtPL.FamilyID
					INNER JOIN tblVillages V ON V.VillageId = dtF.LocationId
					INNER JOIN tblWards W ON W.WardId = V.WardId
					INNER JOIN tblDistricts D ON D.DistrictId = W.DistrictId
					WHERE   dtPR.isOffline = 1)
			RETURN -4;
			--DROP TABLE Premium
			--SELECT * INTO Insuree FROM @Insuree
			--SELECT * INTO Policy FROM @Policy
			--SELECT * INTO Premium FROM @Premium
		BEGIN TRAN UPDATEFAMILY
		/****************************************************START INSERT FAMILY**********************************/

			SELECT @FamilyId = FamilyID FROM tblInsuree WHERE IsHead=1 AND CHFID=@HOFCHFID AND ValidityTo IS NULL		
			SELECT @isOffline =F.isOffline, @CHFID=CHFID FROM @Family F
			INNER JOIN @Insuree I ON I.FamilyId =F.FamilyId
				
				IF EXISTS(SELECT 1 FROM @Family WHERE isOffline =1)
					BEGIN
						INSERT INTO tblFamilies(InsureeId, LocationId, Poverty, ValidityFrom, AuditUserId, isOffline, FamilyType,
						FamilyAddress, Ethnicity, ConfirmationNo, ConfirmationType)
						SELECT 0 InsureeId, LocationId, Poverty, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, FamilyType,
						FamilyAddress, Ethnicity, ConfirmationNo, ConfirmationType
						FROM @Family;
						SELECT @FamilyId = SCOPE_IDENTITY();
						UPDATE @Insuree SET FamilyId = @FamilyId
						UPDATE @Policy SET FamilyId =  @FamilyId
					END
				ELSE
					BEGIN
						
						--Insert History Record
						INSERT INTO tblFamilies ([insureeid],[Poverty],[ConfirmationType],isOffline,[ValidityFrom],[ValidityTo],[LegacyID],[AuditUserID],FamilyType, FamilyAddress,Ethnicity,ConfirmationNo, LocationId) 
						SELECT [insureeid],[Poverty],[ConfirmationType],isOffline,[ValidityFrom],getdate(),@FamilyID, @AuditUserID,FamilyType, FamilyAddress,Ethnicity,ConfirmationNo,LocationId FROM tblFamilies where FamilyID = @FamilyID;
						

						
						--Update Family
						UPDATE @Family SET FamilyId = @FamilyId
						UPDATE @Policy SET FamilyId =  @FamilyId
						 UPDATE  dst  SET dst.[Poverty] = src.Poverty,  dst.[ConfirmationType] = src.ConfirmationType, isOffline=0, dst.[ValidityFrom]=GETDATE(), dst.[AuditUserID] = @AuditUserID, dst.FamilyType = src.FamilyType,  dst.FamilyAddress = src.FamilyAddress,
										   dst.Ethnicity = src.Ethnicity,  dst.ConfirmationNo = src.ConfirmationNo,  dst.LocationId = src.LocationId
						 FROM tblFamilies dst
						 INNER JOIN @Family src ON src.FamilyID = dst.FamilyID
					--	 WHERE  dst.FamilyID = @FamilyID;
					
					END
		/*******************************************************END INSERT FAMILY**********************************/		
				

		/****************************************************START INSERT INSUREE**********************************/
				SELECT @isOffline =I.isOffline, @CHFID=CHFID FROM @Insuree I
				
				--Insert insurees
				IF EXISTS(SELECT 1 FROM @Insuree WHERE isOffline = 1  )
						BEGIN
INSERTINSUREE:
								DECLARE CurInsuree CURSOR FOR SELECT InsureeId, CHFID, isOffline FROM @Insuree WHERE isOffline = 1 OR CHFID NOT IN (SELECT CHFID FROM tblInsuree WHERE ValidityTo IS NULL);
								OPEN CurInsuree
									FETCH NEXT FROM CurInsuree INTO @CurInsureeId, @CurHFID, @CurIsOffline;
									WHILE @@FETCH_STATUS = 0
									BEGIN
									INSERT INTO tblInsuree(FamilyId, CHFID, LastName, OtherNames, DOB, Gender, Marital, IsHead, passport, Phone, CardIssued, ValidityFrom,
									AuditUserId, isOffline, Relationship, Profession, Education, Email, TypeOfId, HFID, CurrentAddress, GeoLocation, CurrentVillage)
									SELECT @FamilyId FamilyId, CHFID, LastName, OtherNames, DOB, Gender, Marital, IsHead, passport, Phone, CardIssued, GETDATE() ValidityFrom,
									@AuditUserId AuditUserId, 0 isOffline, Relationship, Profession, Education, Email, TypeOfId, HFID, CurrentAddress, GeoLocation, CurrentVillage
									FROM @Insuree WHERE InsureeId = @CurInsureeId;
									DECLARE @NewExistingInsureeId  INT  =0
									SELECT @NewExistingInsureeId= SCOPE_IDENTITY();


									--Now we will insert new insuree in the table tblInsureePolicy
									 EXEC uspAddInsureePolicy @NewExistingInsureeId	


									IF @isOffline <> 1 AND @ReturnValue = 0 SET @ReturnValue = @NewExistingInsureeId
									UPDATE @Insuree SET InsureeId = @NewExistingInsureeId WHERE InsureeId = @CurInsureeId
									--Insert photo entry
									INSERT INTO tblPhotos(InsureeID,CHFID,PhotoFolder,PhotoFileName,OfficerID,PhotoDate,ValidityFrom,AuditUserID)
									--SELECT I.InsureeId, I.CHFID, @AssociatedPhotoFolder+'\'PhotoFolder, dt.PhotoPath, @OfficerId OfficerId, GETDATE() PhotoDate, GETDATE() ValidityFrom, @AuditUserId AuditUserId
									--FROM tblInsuree I 
									--INNER JOIN @Insuree dt ON dt.CHFID = I.CHFID
									----WHERE I.FamilyId = @FamilyId
									--WHERE dt.InsureeId=@NewInsureeId
									--AND ValidityTo IS NULL;

									SELECT @NewExistingInsureeId InsureeId, @CHFID CHFID, @AssociatedPhotoFolder photoFolder, PhotoPath photoFileName, @OfficerId OfficerID, getdate() photoDate, getdate() ValidityFrom,@AuditUserId AuditUserId
									FROM @Insuree WHERE InsureeId=@NewExistingInsureeId 

									--Update photoId in Insuree
									UPDATE I SET PhotoId = PH.PhotoId, I.PhotoDate = PH.PhotoDate
									FROM tblInsuree I
									INNER JOIN tblPhotos PH ON PH.InsureeId = I.InsureeId
									WHERE I.FamilyId = @FamilyId;
									FETCH NEXT FROM CurInsuree INTO @CurInsureeId, @CurHFID, @CurIsOffline;
									END
							CLOSE CurInsuree
							DEALLOCATE CurInsuree;
					
					
							--Get the id of the HOF and update Family
							SELECT @HOFId = InsureeId FROM tblInsuree WHERE FamilyId = @FamilyId AND IsHead = 1
							UPDATE tblFamilies SET InsureeId = @HOFId WHERE Familyid = @FamilyId 
					
					END
				ELSE
					BEGIN
						IF EXISTS (
								SELECT 1 FROM @Insuree dt 
								LEFT JOIN tblInsuree I ON I.CHFID = dt.CHFID AND I.ValidityTo IS NULL 
								WHERE  I.InsureeID IS NULL AND dt.isOffline =0 
									)
							BEGIN
								--SET @FamilyId = (SELECT TOP 1 FamilyId FROM @Family)
								GOTO INSERTINSUREE;
							END
									
						ELSE
						BEGIN
							DECLARE CurUpdateInsuree CURSOR FOR SELECT  TI.CHFID FROM @Insuree TI INNER JOIN tblInsuree I ON TI.CHFID=I.CHFID WHERE  I.ValidityTo IS NULL;
							OPEN CurUpdateInsuree
							FETCH NEXT FROM CurUpdateInsuree INTO  @CHFID;
								WHILE @@FETCH_STATUS = 0
								BEGIN
									DECLARE @InsureeId INT,
											@PhotoFileName NVARCHAR(200)
									
									update @Insuree set InsureeId = (select TOP 1 InsureeId from tblInsuree where CHFID = @CHFID and ValidityTo is null)
									where CHFID = @CHFID;

									SELECT @InsureeId = InsureeId, @PhotoFileName = PhotoPath FROM @Insuree WHERE CHFID = @CHFID;
									--Insert Insuree History
									INSERT INTO tblInsuree ([FamilyID],[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID],						[PhotoDate],[CardIssued],isOffline,[AuditUserID],[ValidityFrom] ,[ValidityTo],legacyId,[Relationship],[Profession],[Education],[Email],[TypeOfId],[HFID], [CurrentAddress], [GeoLocation], [CurrentVillage]) 
									SELECT	[FamilyID],[CHFID],[LastName],[OtherNames],[DOB],[Gender],[Marital],[IsHead],[passport],[Phone],[PhotoID],[PhotoDate],[CardIssued],isOffline,[AuditUserID],[ValidityFrom] ,GETDATE(),InsureeID,[Relationship],[Profession],[Education],[Email] ,[TypeOfId],[HFID], [CurrentAddress], [GeoLocation], [CurrentVillage] 
									FROM tblInsuree WHERE InsureeID = @InsureeId; 

									

									UPDATE dst SET dst.[CHFID] = @CHFID, dst.[LastName] = src.LastName,dst.[OtherNames] = src.OtherNames,dst.[DOB] = src.DOB,dst.[Gender] = src.Gender ,dst.[Marital] = src.Marital,dst.[passport] = src.passport,dst.[Phone] = src.Phone,dst.[PhotoDate] = GETDATE(),dst.[CardIssued] = src.CardIssued,dst.isOffline=0,dst.[ValidityFrom] = GetDate(),dst.[AuditUserID] = @AuditUserID ,dst.[Relationship] = src.Relationship, dst.[Profession] = src.Profession, dst.[Education] = src.Education,dst.[Email] = src.Email ,dst.TypeOfId = src.TypeOfId,dst.HFID = src.HFID, dst.CurrentAddress = src.CurrentAddress, dst.CurrentVillage = src.CurrentVillage, dst.GeoLocation = src.GeoLocation 
									FROM tblInsuree dst
									LEFT JOIN @Insuree src ON src.InsureeId = dst.InsureeID
									WHERE dst.InsureeId = @InsureeId;

									--Insert Photo  History
									DECLARE @PhotoId INT =  (SELECT PhotoID from tblInsuree where CHFID = @CHFID AND LegacyID is NULL and ValidityTo is NULL) 
									INSERT INTO tblPhotos(InsureeID,CHFID,PhotoFolder,PhotoFileName,PhotoDate,OfficerID,ValidityFrom,ValidityTo,AuditUserID) 
									SELECT InsureeID,CHFID,PhotoFolder,PhotoFileName,PhotoDate,OfficerID,ValidityFrom,GETDATE(),AuditUserID 
									FROM tblPhotos WHERE PhotoID = @PhotoID;

									--Update Photo
								
									UPDATE tblPhotos SET PhotoFolder = @AssociatedPhotoFolder+'\\',PhotoFileName = @PhotoFileName, OfficerID = @OfficerID, ValidityFrom = GETDATE(), AuditUserID = @AuditUserID 
									WHERE PhotoID = @PhotoID
								FETCH NEXT FROM CurUpdateInsuree INTO  @CHFID;
								END
							CLOSE CurUpdateInsuree
							DEALLOCATE CurUpdateInsuree;

						END
						
						END
				/****************************************************END INSERT INSUREE**********************************/



				/****************************************************END INSERT POLICIES**********************************/
				
				SELECT TOP 1 @isOffline = P.isOffline FROM @Policy P
				IF EXISTS(SELECT 1 FROM @Policy WHERE isOffline = 1)
				BEGIN

		INSERTPOLICY:
		DECLARE @isOfflinePolicy bit=0;
		
					--INSERT POLICIES
						DECLARE CurPolicy CURSOR FOR SELECT PolicyId, ProdId, ISNULL(PolicyStage, N'N') PolicyStage, EnrollDate,FamilyId,isOffline FROM @Policy WHERE isOffline = 1 OR PolicyId NOT IN (SELECT PolicyId FROM tblPolicy WHERE ValidityTo	 IS NULL);
						OPEN CurPolicy
							FETCH NEXT FROM CurPolicy INTO @PolicyId, @ProdId, @PolicyStage, @EnrollDate,@FamilyId,@isOfflinePolicy;
							WHILE @@FETCH_STATUS = 0
							BEGIN

								EXEC @PolicyValue = uspPolicyValue @FamilyId,
																	@ProdId,
																	0,
																	@PolicyStage,
																	@EnrollDate,
																	0,
																	@ErrorCode OUTPUT;


								SELECT @GivenPolicyValue = PolicyValue, @PolicyStatus = PolicyStatus FROM @Policy WHERE PolicyId = @PolicyId;
								IF @GivenPolicyValue < @PolicyValue

								--amani 17/12/2017
								if NOT @isOfflinePolicy =1
									SET @PolicyStatus = 1
								ELSE
									SET @PolicyStatus=2

								INSERT INTO tblPolicy(FamilyId, EnrollDate, StartDate, EffectiveDate, ExpiryDate, PolicyStatus, PolicyValue, 
								ProdId, OfficerId, ValidityFrom, AuditUserId, isOffline, PolicyStage)
								SELECT @FamilyId FamilyId, EnrollDate, StartDate, EffectiveDate, ExpiryDate, @PolicyStatus PolicyStatus, @PolicyValue PolicyValue, 
								ProdId, OfficerId, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, @PolicyStage PolicyStage
								FROM @Policy
								WHERE PolicyId = @PolicyId;

								SELECT @NewPolicyId = SCOPE_IDENTITY();
								UPDATE @Premium SET PolicyId = @NewPolicyId WHERE PolicyId = @PolicyId 



								IF @isOffline <> 1 AND @ReturnValue = 0  
									BEGIN
										SET @ReturnValue = @NewPolicyId;
										--AND isOffline = 0
									END
								--Insert policy Insuree
								
								----Amani added for Only New Family
								--IF EXISTS(SELECT 1 FROM tblFamilies F INNER JOIN tblInsuree I ON I.FamilyID=F.FamilyID
								--WHERE F.ValidityTo IS NULL AND I.ValidityTo IS NULL AND I.CHFID=@HOFCHFID)

				
								IF   EXISTS(SELECT 1 FROM @Premium WHERE isOffline = 1)
								BEGIN
									INSERT INTO tblPremium(PolicyId, PayerId, Amount, Receipt, PayDate, PayType, ValidityFrom, AuditUserId, isOffline, isPhotoFee)
									SELECT  PolicyId, PayerId, Amount, Receipt, PayDate, PayType, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, isPhotoFee 
									FROM @Premium
									WHERE PolicyId = @NewPolicyId;
								END


								BEGIN--Existing Family


								--SELECT InsureeID FROM tblInsuree WHERE FamilyID IN (SELECT FamilyID FROM tblPolicy WHERE PolicyID=@NewPolicyId AND ValidityTo IS NULL) AND ValidityTo IS NULL ORDER BY InsureeID ASC


										--DECLARE @NewCurrentInsureeId INT =0
										--DECLARE CurNewCurrentInsuree CURSOR FOR 	
										--SELECT InsureeID FROM tblInsuree WHERE FamilyID IN (SELECT FamilyID FROM tblPolicy WHERE PolicyID=@NewPolicyId AND ValidityTo IS NULL) AND ValidityTo IS NULL 
										--AND InsureeID NOT IN (SELECT InsureeID FROM tblInsureePolicy WHERE PolicyID=@NewPolicyId AND ValidityTo IS NULL)
										--ORDER BY InsureeID ASC
													--OPEN CurNewCurrentInsuree
														--FETCH NEXT FROM CurNewCurrentInsuree INTO @NewCurrentInsureeId
														--WHILE @@FETCH_STATUS = 0
														--BEGIN
														--Now we will insert new insuree in the table tblInsureePolicy
															EXEC uspAddInsureePolicyOffline  @NewPolicyId
															--FETCH NEXT FROM CurNewCurrentInsuree INTO @NewCurrentInsureeId
														--END
														
													--CLOSE CurNewCurrentInsuree
													--DEALLOCATE CurNewCurrentInsuree						
								END 

					
								FETCH NEXT FROM CurPolicy INTO @PolicyId, @ProdId, @PolicyStage, @EnrollDate, @FamilyId,@isOfflinePolicy;
						END
					CLOSE CurPolicy
					DEALLOCATE CurPolicy;
				END
			ELSE
				BEGIN 
					IF EXISTS (SELECT 1 FROM @Policy dt 
								WHERE   dt.IsOffline = 0 
								AND		dt.PolicyId NOT IN(SELECT PolicyId FROM tblPolicy WHERE ValidityTo IS NULL ) 
									 
							)
					BEGIN
						GOTO INSERTPOLICY;
					END
					--ELSE
					-- BEGIN
					----	SELECT TOP 1 @PolicyId = PolicyId  FROM @Policy 
					--	--INSERT Policy History
					--	INSERT INTO tblPolicy (FamilyID, EnrollDate, StartDate, EffectiveDate, ExpiryDate, ProdID, OfficerID,PolicyStage,PolicyStatus,PolicyValue,isOffline, ValidityTo, LegacyID, AuditUserID)
					--	SELECT FamilyID, EnrollDate, StartDate, EffectiveDate, ExpiryDate, ProdID, OfficerID,PolicyStage,PolicyStatus,PolicyValue,isOffline, GETDATE(), @PolicyID, AuditUserID FROM tblPolicy WHERE PolicyID = @PolicyID;
					--	--Update Policy Record
					--	UPDATE dst SET OfficerID= src.OfficerID, ValidityFrom=GETDATE(), AuditUserID = @AuditUserID 
					--	FROM tblPolicy dst
					--	INNER JOIN @Policy src ON src.PolicyId = dst.PolicyID
					----	WHERE src.PolicyID=@PolicyID
					--END
				END

	/****************************************************END INSERT POLICIES**********************************/
			
	/****************************************************START UPDATE PREMIUM**********************************/


			
			--SELECT TOP 1 @isOffline =  P.isOffline,  @PolicyId = PolicyId,@PremiumID=PremiumId FROM @Premium P WHERE isOffline   <> 1
			--IF @isOffline != 1
			--	BEGIN
				 
			--			IF  EXISTS(SELECT 1 FROM @Premium dt 
			--						  LEFT JOIN tblPremium P ON P.PremiumId = dt.PremiumId 
			--							WHERE P.ValidityTo IS NULL AND dt.isOffline <> 1 AND P.PremiumId IS NULL)
			--				BEGIN
			--					--INSERTPREMIMIUN
			--						INSERT INTO tblPremium(PolicyId, PayerId, Amount, Receipt, PayDate, PayType, ValidityFrom, AuditUserId, isOffline, isPhotoFee)
			--									SELECT     PolicyId, PayerId, Amount, Receipt, PayDate, PayType, GETDATE() ValidityFrom, @AuditUserId AuditUserId, 0 isOffline, isPhotoFee 
			--									FROM @Premium
			--									WHERE @isOffline <> 1;
			--									SELECT @PremiumId = SCOPE_IDENTITY();
			--					IF @isOffline <> 1 AND ISNULL(@PremiumId,0) >0 AND @ReturnValue =0 SET @ReturnValue = @PremiumId
			--				END
			--			ELSE
			--				BEGIN
			--					INSERT INTO tblPremium (PolicyID, PayerID, Amount, Receipt, PayDate, PayType,isOffline, ValidityTo, LegacyID, AuditUserID,isPhotoFee) 
			--					SELECT PolicyID, PayerID, Amount, Receipt, PayDate, PayType,isOffline, GETDATE(), @PremiumID, AuditUserID,isPhotoFee FROM tblPremium where PremiumID = @PremiumID;
				
			--					UPDATE dst set dst.PolicyID= src.PolicyID, dst.PayerID = src.PayerID, dst.Amount = src.Amount, dst.Receipt = src.Receipt, dst.PayDate =  src.PayDate, dst.PayType = src.PayType, 
			--											dst.ValidityFrom=GETDATE(), dst.LegacyID = @PremiumID, dst.AuditUserID = @AuditUserID,dst.isPhotoFee = src.isPhotoFee 
			--					FROM tblPremium dst
			--					INNER JOIN @Premium src ON src.PremiumId = dst.PremiumId
			--					--WHERE dst.PremiumID=@PremiumID;
													
			--				END
			--	 --Update InsureePolicy and Policy Table
			--	 SELECT TOP 1  @PremiumID= PremiumId , @FamilyId = FamilyId, @ProdId = Po.ProdId, @PolicyStage = PolicyStage,@EnrollDate = EnrollDate, @EffectiveDate = PayDate, @PolicyStatus = PolicyStatus
			--				FROM tblPremium P
			--				INNER JOIN tblPolicy Po ON Po.PolicyId = P.PolicyId
			--				WHERE PremiumId = @PremiumID 
			--	 EXEC @PolicyValue = uspPolicyValue		@FamilyId,
			--											@ProdId,
			--											0,
			--											@PolicyStage,
			--											@EnrollDate,
			--											0,
			--											@ErrorCode OUTPUT;
			--		SELECT @Contribution = SUM(AMOUNT) FROM tblPremium where PolicyID =@PolicyId AND ValidityTo IS NULL AND isPhotoFee = 0;
				  
			--		IF @PolicyValue <= @Contribution
			--		BEGIN
			--			UPDATE tblPolicy SET PolicyStatus = 2,EffectiveDate = @EffectiveDate   WHERE PolicyID =  @PolicyId AND ValidityTo IS NULL 
			--			UPDATE tblInsureePolicy SET EffectiveDate = @EffectiveDate WHERE ValidityTo IS NULL AND EffectiveDate IS NULL AND PolicyId = @PolicyId
			--		END
			--	END
	/****************************************************END INSERT PREMIUM**********************************/

		COMMIT TRAN UPDATEFAMILY;
		SET @ErrorMessage = '';
		RETURN @ReturnValue;
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage = ERROR_MESSAGE();
		IF @@TRANCOUNT > 0 ROLLBACK TRAN UPDATEFAMILY;
		RETURN -400;
	END CATCH
		END

END TRY
BEGIN CATCH
	SELECT @ErrorMessage = ERROR_MESSAGE();
	--INSERT INTO @Result(ErrorMessage) values (@ErrorMessage)
	--IF NOT OBJECT_ID('TempResult') IS NULL
	--DROP TABLE TempResult
	--SELECT * INTO TempResult FROM @Result
	--IF @@TRANCOUNT > 0 ROLLBACK TRAN ENROLLFAMILY;
	RETURN -400;
END CATCH
GO
