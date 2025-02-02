/***************************************************************************
****************************************************************************
** Please execute openIMIS_ONLINE.sql script before executing this script **
****************************************************************************
***************************************************************************/

DECLARE @Password VARCHAR(MAX) = 'Admin'
DECLARE @PrivateKey VARCHAR(MAX) = 'Admin'

DELETE FROM [dbo].[tblUsersDistricts]
DELETE FROM [dbo].[tblUserRole]
DELETE FROM [dbo].[tblUsers]

SET IDENTITY_INSERT [dbo].[tblUsers] ON 

INSERT [dbo].[tblUsers] ([UserID], [LanguageID], [LastName], [OtherNames], [Phone], [LoginName], [RoleID], [HFID], [ValidityFrom],
	[ValidityTo], [LegacyID], [AuditUserID], [PrivateKey], [StoredPassword], [PasswordValidity], [IsAssociated]) 
VALUES (1, N'en', N'Admin', N'Admin', N'', N'Admin', 524288, 0, CURRENT_TIMESTAMP, NULL, NULL, 0,  
	-- PrivateKey
	CONVERT(varchar(max),HASHBYTES('SHA2_256', @PrivateKey),2), 
	-- [StoredPassword]
	CONVERT(varchar(max),HASHBYTES('SHA2_256',CONCAT(@Password,CONVERT(varchar(max),HASHBYTES('SHA2_256',@PrivateKey),2))),2), 
	NULL, NULL)
SET IDENTITY_INSERT [dbo].[tblUsers] OFF

INSERT INTO tblUsersDistricts ([UserID],[LocationId],[AuditUserID]) 
VALUES (1,(
		SELECT TOP(1) LocationId FROM tblLocations WHERE LocationType='D'
	),-1)


SET IDENTITY_INSERT [dbo].[tblUserRole] ON 
INSERT [dbo].[tblUserRole] ([UserRoleID], [UserID], [RoleID], [ValidityFrom], [ValidityTo], [AudituserID], [LegacyID]) VALUES (1, 1, 11, CURRENT_TIMESTAMP, NULL, 1, NULL)
SET IDENTITY_INSERT [dbo].[tblUserRole] OFF
GO
