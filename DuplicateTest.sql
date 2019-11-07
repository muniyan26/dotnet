use abc
	[SelectId]  as ('Select ' + cast(SQueryId as nvarchar) + ' as Id'),
	(('Select '+CONVERT([nvarchar],[SQueryId]))+' as Id,')
Select EmployeeId,CompanyId,AttendanceDate,Count(1) from [HRMS.EmployeeAttendance]
group by EmployeeId,CompanyId,AttendanceDate
having Count(1) > 1

Delete from [HRMS.EmployeeAttendance] where EmployeeAttendanceId in(
Select EmployeeAttendanceId from (
Select EmployeeAttendanceId,EmployeeId,CompanyId,AttendanceDate,ROW_NUMBER() over (partition by  EmployeeId,CompanyId,AttendanceDate order by EmployeeId) as SrNo
from [HRMS.EmployeeAttendance])
as AbC where AbC.SrNo>1 )


Select * from [HRMS.EmployeeAttendance] where 
EmployeeId=70259 and CompanyId=25 and  AttendanceDate='2018-07-17'


Select * from [HRMS.UploadAttendance] where AttendanceDate >='2018-06-01'    and AttendanceDate <='2018-06-29' 

Select * from [HRMS.AttendanceDetail]where CompanyId <> 1  and  AttendanceDate >='2018-06-01'    and AttendanceDate <='2018-06-23' 
Select * from   [HRMS.EmployeeActualAttendance] where CompanyId <> 1  and  AttendanceDate >='2018-06-01'    and AttendanceDate <='2018-06-23' 

Select * from [HRMS.EmployeeAttendance] where CompanyId <> 1  and  AttendanceDate >='2018-06-01'    and AttendanceDate <='2018-06-23'

Select Empadd.EmployeeHistoryShiftId,empadd Isnull((Select * from dbo.SplitString(history.WorkingDay,',') 
		    Where item in(FORMAT(Empadd.AttendanceDate,'ddd'))),'') As [WorkingDays] from [HRMS.EmployeeAttendance] as Empadd 
inner join 
(Select  EmployeeHistoryShiftId,WorkingDay from [HRMS.EmployeeHistoryShift] where IsActive=1) as history
on history.EmployeeHistoryShiftId=Empadd.EmployeeHistoryShiftId  


update Empadd set Empadd.IsWorkingDay=iif(Isnull((Select * from dbo.SplitString(history.WorkingDay,',') 
		    Where item in(FORMAT(Empadd.AttendanceDate,'ddd'))),'0')<>'0',1,0) from [HRMS.EmployeeAttendance] as Empadd
inner join  
(Select  EmployeeHistoryShiftId,WorkingDay from [HRMS.EmployeeHistoryShift] where IsActive=1) as history
on history.EmployeeHistoryShiftId=Empadd.EmployeeHistoryShiftId   
where Empadd.IsWorkingDay is null



Select Empadd.CompanyId,Empadd.AttendanceDate,Holiday.*,
(Select  Case 
when Empadd.AttendanceDate >=Holiday.HolidayStartDate And Empadd.AttendanceDate<=Holiday.HolidayEndDate
then 1
else 0
end) as IsHoliday from [HRMS.EmployeeAttendance] as Empadd 
inner join 
(
Select CompanyId,Cast(HolidayStartDate as Date) as HolidayStartDate,Cast(HolidayEndDate as Date) as HolidayEndDate from [HRMS.HolidayMaster] where IsActive=1
and (HolidayStartDate is not null and HolidayEndDate is not null)) as Holiday
on Empadd.CompanyId=Holiday.CompanyId

Declare @tableSql table
(
	Id Int identity(1,1),
	Name  nvarchar(1000)
)


Insert into @tableSql
Select name from sys.tables where name like 'Finance.%' order by name


Declare @intMinId int=1
Declare @intMaxId int=0
Select @intMaxId=max(Id) from @tableSql
Declare @tablename nvarchar(150) 
 
while @intMinId<=@intMaxId
begin
	Select  @tablename=name from  @tableSql  where Id=@intMinId
	--print  '[' + @tablename +']'
	print 'Drop table [' + @tablename +']'
	set @intMinId=@intMinId+1

end 


SELECT  DB_NAME() AS dbname, 
 o.type_desc AS referenced_object_type, 
 d1.referenced_entity_name, 
 d1.referenced_id, 
        STUFF( (SELECT ', ' + OBJECT_NAME(d2.referencing_id)
   FROM sys.sql_expression_dependencies d2
         WHERE d2.referenced_id = d1.referenced_id
                ORDER BY OBJECT_NAME(d2.referencing_id)
                FOR XML PATH('')), 1, 1, '') AS dependent_objects_list
FROM sys.sql_expression_dependencies  d1 JOIN sys.objects o 
  ON  d1.referenced_id = o.[object_id]
GROUP BY o.type_desc, d1.referenced_id, d1.referenced_entity_name
ORDER BY o.type_desc, d1.referenced_entity_name

 Declare @ForeignKeyTable table
(
	Id Int identity(1,1),
	PKTableName nvarchar(150),
	FKTableName nvarchar(150),
	FKName nvarchar(150)
)

insert into @ForeignKeyTable
exec usp_GetForeignKeyReferenceTable 'Finance.CurrencyRateType'

 exec usp_SettingDeletingForeignRefernceWithTable 'CRM'



 declare @intMinId int=1
declare @intMaxId int=0
Declare @ObjectName nvarchar(150)=''
Select @intMaxId=Max(ObjectId) from DeletedObject where ObjectType='table'
while @intMinId<=@intMaxId
begin
	Select @ObjectName=ObjectName from DeletedObject where ObjectId=@intMinId
	set @ObjectName='[dbo].['+ @ObjectName+']'
	 insert into DeletedObject
	 exec sp_depends @ObjectName
	 --exec sp_depends '[dbo].['+ @ObjectName+']'  		
	--print '[dbo].['+@ObjectName+']' 
	--print @ObjectName

	set @intMinId=@intMinId+1
end





Declare @locTable table
(
	Id Int identity(1,1),
	ObjectName nvarchar(150),
	ObjectType nvarchar(50)
)
insert into @locTable
Select ObjectName,ObjectType from DeletedObject
where ObjectType<>'table'


Declare @intMinId int=1
Declare @intMaxId int=0
Declare @type nvarchar(50);
Declare @Name nvarchar(150);
Select @intMaxId=max(Id) from @locTable
while @intMinId<=@intMaxId
begin
		Select @type=ObjectType,@Name=ObjectName from @locTable where Id=@intMinId
		if(@type='stored procedure')
		begin
			print 'IF OBJECT_ID(''' + @Name+''') IS NOT NULL ' 
			print 'drop procedure ' + @Name
			print 'Go'

		end
		else if (@type='table function')
		begin
			print 'IF OBJECT_ID(''' + @Name+''') IS NOT NULL ' 
			print 'drop function ' + @Name
			print 'Go'
		end
		else if (@type='trigger')
		begin
			print 'IF OBJECT_ID(''' + @Name+''') IS NOT NULL ' 
			print 'drop trigger ' + @Name
			print 'Go'
		end


		Set @intMinId=@intMinId+1
End





Select TabControlId,TabName,'' as Burmese from TabControl
where SubModuleId in ( 
Select SubModuleId from [SubModule] where ModuleId
in (1,2,6,7)
) 
and SubModuleId > 4
and TabControlId  not  in (Select TabControlId from TabLanguageValue where LanguageDetailId=3)



 ;With RoleMenu
as
( 
Select SetPermissionDetailsId,NavigationId from [Setting.SetNavigationPermissionDetails] where CompanyId=1 and
PersmissionSetId = 18
and IsActive=1
)


Update menu  set menu.IsDefault=1 from [Base.MenuMaster] as menu
inner join RoleMenu on RoleMenu.NavigationId=menu.MenuId


Select  NavigationId,CompanyId,PersmissionSetId,count(1) from(
Select NavigationId,CompanyId,PersmissionSetId,ActionPerformID from [Setting.SetFunctionPermissionDetails] 
where ActionPerformID in (7,8) and IsActive=1
) as Abc 
group by NavigationId,CompanyId,PersmissionSetId
having count(1) >1

 

 --Select EmployeeID,EffectiveDate from [HRMS.EmployeeShift] where  CompanyId=37 
begin tran
update Es set Es.EffectiveDate=Emp.DateOfJoining  
--Select  * 
from [HRMS.EmployeeShift]  as Es 
inner join
(
Select EmployeeId, FirstName, DateOfJoining
FROM  [HRMS.Employee] where CompanyId=37 
) as Emp on Emp.EmployeeId=Es.EmployeeID
commit tran


Select CompanyId,EmployeeShiftId,EffectiveDate,Count(1) from [HRMS.EmployeeHistoryShift]
group by CompanyId,EmployeeShiftId,EffectiveDate
having count(1) >1



Update email set 
		email.Subject=gl.Subject,
		email.EmailHeader=gl.EmailHeader,
		email.EmailBody=gl.EmailBody,
		email.EmailFooter =gl.EmailFooter 
		from [Base.EmailContent] as email inner join 
[Base.GlobalEmailContent] as gl on gl.GlobalEmailContentId= email.GlobalEmailContentId
where email.CompanyId<>32




Select distinct Normal.* from (
 Select  NavigationId,CompanyId,PersmissionSetId,count(1) as [Count] from(
Select NavigationId,CompanyId,PersmissionSetId,ActionPerformID from [Setting.SetFunctionPermissionDetails] 
where ActionPerformID in (7,8) and IsActive=1 --and PersmissionSetId=121 --and CompanyId<>0 --
) as Abc 
group by NavigationId,CompanyId,PersmissionSetId
having count(1) >1) as tab
inner join 
(Select SetFunctionPermissionDetailsId,NavigationId,CompanyId,PersmissionSetId,ActionPerformID from [Setting.SetFunctionPermissionDetails] where 
ActionPerformID in (7,8) and IsActive=1 --and PersmissionSetId=121
) as Normal
on tab.NavigationId=Normal.NavigationId
and tab.PersmissionSetId=Normal.PersmissionSetId
order by PersmissionSetId


begin tran
Update Functions set Functions.IsActive=0 ,Functions.UpdatedBy=-10,UpdatedDate=GETDATE() from  [Setting.SetFunctionPermissionDetails] as Functions
inner join (

Select distinct Normal.* from (
 Select  NavigationId,CompanyId,PersmissionSetId,count(1) as [Count] from(
Select NavigationId,CompanyId,PersmissionSetId,ActionPerformID from [Setting.SetFunctionPermissionDetails] 
where ActionPerformID in (7,8) and IsActive=1 and PersmissionSetId=134 --and CompanyId<>0 --
) as Abc 
group by NavigationId,CompanyId,PersmissionSetId
having count(1) >1) as tab
inner join 
(Select SetFunctionPermissionDetailsId,NavigationId,CompanyId,PersmissionSetId,ActionPerformID from [Setting.SetFunctionPermissionDetails] where 
ActionPerformID in (7,8) and IsActive=1 --and PersmissionSetId=121
) as Normal
on tab.NavigationId=Normal.NavigationId
and tab.PersmissionSetId=Normal.PersmissionSetId

where ActionPerformID=7
--order by PersmissionSetId
) as functionrole on functionrole.SetFunctionPermissionDetailsId=Functions.SetFunctionPermissionDetailsId
commit tran

Select * from [Foundation.Users] where EmailId='SSayyad@lunetta.in'
Select * from [Setting.UserPersmission] where UserId=60285

Select * from [Setting.SetFunctionPermissionDetails] where PersmissionSetId=105



update usersd set usersd.MobileNumber=Employee.MobileNumber from	 [Foundation.Users] as usersd
inner join (select EmployeeId,CompanyId,MobileNumber from [HRMS.Employee] where IsActive=1) as Employee
on Employee.CompanyId=usersd.CompanyId and Employee.EmployeeId=usersd.EmployeeId


select text from syscomments where text like '%CREATE TRIGGER%'




Update email set email.EmailBody=Content.EmailBody,email.UpdatedBy=-50     from  [Base.EmailContent] as  email

inner join (
Select GlobalEmailContentId,EmailBody from  
  [Base.EmailContent] where
EmailContentId In (
 62286
,62293
,62297
,62295
,62306
,62305
,62304
,62303
,62296
,62292
,62300
,62294
,62283
,62284
,62310
,62287)
) as Content on email.GlobalEmailContentId=Content.GlobalEmailContentId
and email.CompanyId <> 41



--MenuId
--22028,
--21075







Begin tran
Update   [Base.GlobalEmailContent]
Set EmailBody=Replace(EmailBody,'justify','left')
WHERE        (EmailBody LIKE '%justify%')
Commit tran

Begin tran
Update   [Base.EmailContent]
Set EmailBody=Replace(EmailBody,'justify','left')
WHERE        (EmailBody LIKE '%justify%')
commit tran



Select uat.MenuId,uat.MenuName,live.MenuName from [UAT_MRHM].[dbo].[Base.MenuMaster] as uat
inner join [HRMSNuzayLive].[dbo].[Base.MenuMaster] as live
on live.MenuId=uat.MenuId
where  uat.MenuName  != live.MenuName COLLATE SQL_Latin1_General_CP1_CS_AS

begin tran
Update live set live.MenuName=uat.MenuName from [HRMSNuzayLive].[dbo].[Base.MenuMaster] as live 
inner join [UAT_MRHM].[dbo].[Base.MenuMaster] as uat
on live.MenuId=uat.MenuId
where  uat.MenuName  != live.MenuName COLLATE SQL_Latin1_General_CP1_CS_AS
commit tran

Select uat.MenuMasterId,uat.MenuName,live.MenuName,uat.MenuValue,live.MenuValue from [HRMSNuzayLive].[dbo].[base.MenuValueLanguage] as live 
inner join [UAT_MRHM].[dbo].[base.MenuValueLanguage] as uat
on live.MenuValueLanguageId=uat.MenuValueLanguageId and live.MenuMasterId=uat.MenuMasterId
where ( uat.MenuName  != live.MenuName COLLATE SQL_Latin1_General_CP1_CS_AS
or uat.MenuValue  != live.MenuValue COLLATE SQL_Latin1_General_CP1_CS_AS)


begin tran
Update  live  set live.MenuName= uat.MenuName,live.MenuValue=uat.MenuValue from [HRMSNuzayLive].[dbo].[base.MenuValueLanguage] as live 
inner join [UAT_MRHM].[dbo].[base.MenuValueLanguage] as uat
on live.MenuValueLanguageId=uat.MenuValueLanguageId and live.MenuMasterId=uat.MenuMasterId
where ( uat.MenuName  != live.MenuName COLLATE SQL_Latin1_General_CP1_CS_AS
or uat.MenuValue  != live.MenuValue COLLATE SQL_Latin1_General_CP1_CS_AS)

commit tran


Select uat.ModuleSettingId,uat.DefaultLabelName,live.DefaultLabelName from [HRMSNuzayLive].[dbo].[ModuleSetting] as live 
inner join [UAT_MRHM].[dbo].[ModuleSetting] as uat
on live.ModuleSettingId=uat.ModuleSettingId  
where ( uat.DefaultLabelName  != live.DefaultLabelName COLLATE SQL_Latin1_General_CP1_CS_AS
 )

 ---Currency-====
 Update [Base.Company] set CurrencyMasterId=1,UpdatedBy=-10,UpdatedDate=getdate()
 
 ---Currency-====

 ----BloodGroup===================
 update Employee set Employee.BloodGroup=NBloodGroupId,Employee.UpdatedBy=-50,UpdatedDate=GETDATE() from [HRMS.Employee] as Employee  
--Select  EmployeeId,BloodGroup,EBloodGroupId,NBloodGroupId from [HRMS.Employee] as Employee  
inner join (
Select EBloodGroupId,NBloodGroupId from (
Select * from(
Select BloodGroupId AS EBloodGroupId,Bloodgroup as EB from [HRMS.BloodGroup] where IsActive=1) as existingB
--full outer join (
inner join (
Select BloodGroupId as NBloodGroupId,Bloodgroup as NB from [HRMS.BloodGroup] where IsActive=1 and BloodGroupId<9) as newBlood
on existingB.EB=newBlood.NB) as a ) as B on
Employee.BloodGroup=B.EBloodGroupId
where Employee.BloodGroup !='' and Employee.IsActive=1




Select * from(
Select BloodGroupId,Bloodgroup as EB from [HRMS.BloodGroup] where IsActive=1) as existingB
--full outer join (
inner join (
Select BloodGroupId,Bloodgroup as NB from [HRMS.BloodGroup] where IsActive=1 and BloodGroupId<9) as newBlood
on existingB.EB=newBlood.NB
--where  
--Select BloodGroupId,Bloodgroup as EB from [HRMS.BloodGroup] where IsActive=1 and Bloodgroup  in
--(
--Select  Bloodgroup as NB from [HRMS.BloodGroup] where IsActive=1 and BloodGroupId<9
--)



--Select * from (
--Select EmployeeId,BloodGroup,CompanyId from [HRMS.Employee] where IsActive=1 and BloodGroup !=''
--) as Employee
--join
--(
--Select BloodGroupId,Bloodgroup from [HRMS.BloodGroup] where IsActive=1
--) as Blood on Employee.BloodGroup=Blood.BloodGroupId


--Select EmployeeId,BloodGroup,CompanyId from [HRMS.Employee] where IsActive=1 and BloodGroup !=''
--and BloodGroup in
--(
--Select BloodGroupId  from [HRMS.BloodGroup] where IsActive=1 and Bloodgroup   in
--(
--Select  Bloodgroup  from [HRMS.BloodGroup] where IsActive=1 and BloodGroupId<9
--)
--)


Select Employee.*,b.* from (
Select EmployeeId,BloodGroup from [HRMS.Employee] where IsActive=1 and BloodGroup !=''
) as Employee
inner join (

Select * from (
Select * from(
Select BloodGroupId ,Bloodgroup as EB from [HRMS.BloodGroup] where IsActive=1) as existingB
--full outer join (
inner join (
Select BloodGroupId as NI,Bloodgroup as NB from [HRMS.BloodGroup] where IsActive=1 and BloodGroupId<9) as newBlood
on existingB.EB=newBlood.NB) as a) as b
on Employee.BloodGroup=b.BloodGroupId



Update [HRMS.BloodGroup]  set IsActive=0,UpdatedBy=-50,UpdatedDate=GETDATE() where BloodGroupId >8
 ----BloodGroup===================


 
 Select * from [HRMS.EmployeeAttendance] where ModeOfAttendance= 'Mobile'
 select EmployeeId,EmployeeBiomatricCode, BiometricDataId,CompanyId from 
	 [HRMS.EmployeeCodeMap]  where BiometricDataId not  in  ( 
 Select distinct BiometricId from [HRMS.AttendanceDetail])
 and (BiometricDataId <> '' and BiometricDataId <> 'Select') and  EmployeeBiomatricCode <> ''  

 Update [Setting.BiometricLastUploaded] set BiometicType='Finger'

 DECLARE @db_name VARCHAR(100);
 
SET @db_name = 'My_Database'; -- Change your database name here
 
SELECT database_name [Database Name],enabled,
 name [Job Name],
 js.job_id [Job ID]
FROM msdb.dbo.sysjobsteps js
 INNER JOIN msdb.dbo.sysjobs_view jv
 ON js.job_id = jv.job_id
WHERE database_name = @db_name;




Select CompanyId,CompanyName,CEmail,CMobNumber, FirstName,EmailId,MobileNumber from (
Select ROW_NUMBER() over (partition by userdtl.CompanyId order by userid) as SrNo,userdtl.CompanyId,CompanyName,CEmail,CMobNumber, FirstName,EmailId,MobileNumber  from [Foundation.Users] as userdtl
inner join 
 
(
SELECT [CompanyId],CompanyName,EmailAddress as CEmail,MobileNumber  as CMobNumber
  FROM  [dbo].[Base.Company]
  where IsActive=1
) as Company 
on Company.CompanyId=userdtl.CompanyId
where userdtl.IsActive=1
) dtl
where SrNo=1



DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
SELECT * FROM LanguageValue  
WHERE FieldValue like '%'+@nl+'%'
--CONTAINS(FieldValue, char(13)) OR CONTAINS(FieldValue, char(10)) 
--carriage return: char(13)
--line feed:       char(10)


begin tran
update LanguageValue set FieldValue=REPLACE(FieldValue, @nl, '')
WHERE FieldValue like '%'+@nl+'%'
commit tran







declare @date datetime = '2019-01-01'
Select datediff(week, '2018-12-31' , @date - 1),datediff(week, '2018-12-31' , @date - 1)
select datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, @date), 0)), 0), @date - 1) + 1


--Select DATEDIFF(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, @date), 0), @date) +1
select  datediff(month, 0, @date),dateadd(month, datediff(month, 0, @date), 0),
datediff(week, 0, dateadd(month, datediff(month, 0, @date), 0)),dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, @date), 0)), 0),
datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, @date), 0)), 0), @date - 1) + 1
select datediff(month, 0, @date),dateadd(month, 1428,0),
datediff(week, 0, '2019-01-01'),dateadd(week, 6209, 0),datediff(week, '2018-12-31' , @date - 1)


--SELECT DATEDIFF(year,  '2011/08/25','2017/08/25') AS DateDiff;1428  datediff(month,'1900-01-01', @date)


Select ModuleSettingId,FieldValue from [LanguageValue] where LanguageDetailId=1 and
ModuleSettingId 
In(
Select ModuleSettingId from [ModuleSetting] where IsActive=1
)

Select TabControlId,LanguageValue from [TabLanguageValue]
where LanguageDetailId=1 and
TabControlId 
In(
Select TabControlId from [ModuleSetting] where IsActive=1
)

Select MenuMasterId,MenuValue from [base.MenuValueLanguage]
where LanguageDetailId=1 and MenuMasterId in ( 
Select MenuId from [Base.MenuMaster] where IsActive=1 and MainMenuID Is Not NULL  
)


Declare @tableSql table
(
	Id Int identity(1,1),
	MenuId  Bigint,
	MenuName varchar(50),
	ParentMenuid Bigint,
	MainMenuId bigint
)

insert into @tableSql
Select MenuId,MenuName,ParentMenuId,0 from [Base.MenuMaster] where IsActive=1  

 

;with CteMainMenu 
as
(	SELECT MenuId, MenuName, ParentMenuid ,MainMenuId 
	FROM @tableSql 
	WHERE ParentMenuId = 0 
	UNION ALL 
	--recursive execution 
	SELECT e.MenuId,e.MenuName, e.ParentMenuid ,iif(m.ParentMenuid=0,e.ParentMenuid,m.ParentMenuid)
	FROM @tableSql e INNER JOIN CteMainMenu m  
	ON e.ParentMenuid = m.MenuId 
) 
Select * from CteMainMenu

Declare @tempDuplicate table
( 
	[BiometricEmployeeCode] nvarchar(50),  
	BiometricDataId nvarchar(50) , 
	[InTime] time(0), 
	[AttendanceDate] date,
	Nos int
	
) 

Insert into @tempDuplicate
Select '111','11111','10:00','2018-10-12',0
union all
Select '111','11111','10:00','2018-10-12',0
union all
Select '111','11111','10:00','2018-10-12',0
union all
Select '111','11111','10:00','2018-10-13',0
union all
Select '111','11111','10:00','2018-10-14',0

 

Declare @tempDuplicate table
( 
	Id int Identity(1,1),
	[BiometricEmployeeCode] nvarchar(50),  
	BiometricDataId nvarchar(50) , 
	[InTime] datetime , 
	[OutTime] datetime, 
	[AttendanceDate] date,
	Nos int
	
) 

Declare @tempDuplicate1 table
( 
	Id int ,
	BiometricEmployeeCode nvarchar(50),  
	BiometricDataId nvarchar(50) , 
	[InTime] datetime , 
	[OutTime] datetime,  
	[AttendanceDate] date,
	Nos int,
	[NextInTime] datetime , 
	[NextOutTime] datetime
	
) 


Insert into @tempDuplicate
Select '111','11111','01:00','15:00','2018-10-12',0
union all
Select '111','11111','10:00','10:00','2018-10-12',0
union all
Select '111','11111','10:00','10:00','2018-10-12',0 
union all
Select '111','11111','01:00','15:00','2018-10-13',0
union all
Select '111','11111','10:00','18:00','2018-10-13',0
union all
Select '111','11111','10:00','10:00','2018-10-14',0

Update Temp1 set Temp1.Nos=Temp2.RNO from @tempDuplicate as Temp1
Inner Join
(Select *,Row_number() over(partition by BiometricDataId,BiometricEmployeeCode,AttendanceDate order by AttendanceDate ) as RNO 
from @tempDuplicate) as Temp2
on Temp1.Id=Temp2.Id

Delete from @tempDuplicate where Nos > 2

Delete from @tempDuplicate where AttendanceDate not in (
select AttendanceDate from @tempDuplicate where Nos=2
) 
Insert into @tempDuplicate1
Select *,Lead(InTime) Over (partition by AttendanceDate order by InTime) as InTime,NULL from @tempDuplicate 

update temp set Temp.NextOutTime= Temp2.NOutTime from @tempDuplicate1 as Temp 
inner Join
(
Select *,Lead(OutTime) Over (partition by AttendanceDate order by Nos ) as NOutTime from @tempDuplicate
) as Temp2 on
Temp.Id =Temp2.Id

Select * from @tempDuplicate1
where Nos=1



--To disable / enable selective triggers...
--ALTER TABLE tableName DISABLE TRIGGER triggername
--ALTER TABLE tableName ENABLE TRIGGER triggername


--To disable / enable all triggers...
--ALTER TABLE tableName DISABLE TRIGGER ALL
--ALTER TABLE tableName ENABLE TRIGGER ALL

Select  EmployeeId , ReportingToId,t2.*  from 
[Base.EmployeeReporties]  t1,
(Select  EmployeeId AS ManagerEmployeeId, ReportingToId  as ManagerReportingToId from [Base.EmployeeReporties] where isactive=1 ) t2
where t1.ReportingToId=t2.ManagerEmployeeId  
and t1.EmployeeId=t2.ManagerReportingToId and 
t2.ManagerEmployeeId=t1.ReportingToId
and t1.IsActive=1


Declare @tempEmployee Table
(
	ID int,
	EmployeeName varchar(10),
	ReportingID int
)


Insert into @tempEmployee
select 1,'MON',2
Insert into @tempEmployee
select 2,'TUE',3
Insert into @tempEmployee
select 3,'WED',4
Insert into @tempEmployee
select 4,'THU',5
Insert into @tempEmployee
select 5,'FRI',6
Insert into @tempEmployee
select 6,'SAT',1
 

 
Select t1.*,t2.EmployeeName as Manager from @tempEmployee t1 , 
@tempEmployee t2 where t1.ReportingID=t2.ID
--and t1.ID=t2.ReportingID  
--and t2.ID=t1.ReportingID


Select * from [dbo].[Setting.WeekOff]

Select * from  [dbo].[Setting.WeekOffDetail]  

Select * from [Base.WorkShift]

Select * from [Base.WorkShiftGrid]



declare @loopCount int,@companyId int,@EmployeeId int
declare @locCompanyData table
(Id int identity(1,1),EmployeeId int,
CompanyId int)

Declare @UserId int=-12,@CreatedDate datetime=getdate()
insert into @locCompanyData(EmployeeId,CompanyId)
(
Select EmployeeId,CompanyId from [HRMS.Employee] where IsActive=1 and CompanyId<>1 
)


 
set @loopCount = (select min(Id) from @locCompanyData)

while @loopCount > 0
begin
 
 select @companyId=CompanyId,@EmployeeId=EmployeeId from @locCompanyData where Id = @loopCount 
 
 INSERT INTO [dbo].[HRMS.EmployeeHrmsSetting]
           ([GlobalHrmsSettingId]
           ,[EmployeeId]
           ,[CompanyId]
           ,[SettingName]
           ,[SettingDescription]
           ,[CategoryType]
           ,[ValueType]
           ,[DefaultValue]
           ,[MinValue]
           ,[MaxValue]
           ,[Status]
           ,[IsActive]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[UpdatedDate])

 Select GlobalHrmsSettingId,@EmployeeId,@companyId,SettingName,SettingDescription,CategoryType,
 ValueType,DefaultValue,MinValue,MaxValue,Status,IsActive,@UserId,@CreatedDate,@UserId,@CreatedDate from [HRMS.CompanyHrmsSetting] where CompanyId=@companyId 
 and GlobalHrmsSettingId not in (
 Select GlobalHrmsSettingId from  [HRMS.EmployeeHrmsSetting] where CompanyId=@companyId and EmployeeId=@EmployeeId)
  
   
  --Select * from [HRMS.CompanyHrmsSetting]  where CompanyId=@companyId and IsActive=1 and
  -- GlobalHrmsSettingId not in (Select GlobalHrmsSettingId from [HRMS.GlobalHrmsSetting] where IsActive=1)

  set @loopCount = (select min(Id) from @locCompanyData where Id > @loopCount)
end 


update cg set cg.SettingName=gh.SettingName,
cg.SettingDescription=gh.SettingDescription,
cg.CategoryType=gh.CategoryType,
cg.ValueType=gh.ValueType,
cg.DefaultValue=gh.DefaultValue,
cg.MinValue=gh.MinValue,
cg.MaxValue=gh.MaxValue,
cg.Status=gh.Status
  from [HRMS.EmployeeHrmsSetting] as cg
inner join [HRMS.GlobalHrmsSetting]  as gh on
cg.GlobalHrmsSettingId=gh.GlobalHrmsSettingId

usp_MsInsertEmployeeMasterUatToLive

Select '@CompanyID', ShiftCode,ShiftName,ShiftInTimeGrace,ShiftOutTimeGrace,MaxWorkingHour,Break1,Break2,Break3,
Break4,ShiftPlan,IsSplit,ShiftStatus,1,InTimeGraceSplit,OutTimeGraceSplit,MaxWorkingHoursMins,MaxWorkingHourSplit from [Base.WorkShift] where CompanyId=38
Select '@CompanyId','@WorkShiftId',TypeShift,WeekNumber,SplitNo,Mon,Tue,Wed,Thu,Fri,Sat,Sun,Normal,1 from [Base.WorkShiftGrid] where WorkShiftId=15
Select '@CompanyId',Code,Name,isChecked,1 from [Setting.WeekOff]  where CompanyId=38
Select '@SettingWeekId',WeekOff,[All],1st,2nd,3rd,4th,5th,Odd,Even,1 from [Setting.WeekOffDetail]  where SettingWeekId=3