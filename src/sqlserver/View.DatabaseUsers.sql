/*requires Schema.Security.sql*/
/*requires Table.Contacts.sql*/
/*requires Table.SQLlogins.sql*/
/*requires Table.SQLMappings.sql*/

/**
  ==================================================================================
    DESCRIPTION
		Creation of the [security].[DatabaseUsers] view that lists active Database Users

	==================================================================================
  BUGS:
 
    BUGID       Fixed   Description
    ==========  =====   ==========================================================
	00013		1.0.1	This view does not give all database users !
    ----------------------------------------------------------------------------------
  ==================================================================================
  Notes :
 
        Exemples :
        -------
 
  ==================================================================================
  Revision history
 
    Date        Name                Description
    ==========  ================    ================================================
    24/04/2014  Jefferson Elias     Creation
    --------------------------------------------------------------------------------
	25/04/2014	Jefferson Elias		Modified to manage the new version of logins view
									Version 1.0.0
    --------------------------------------------------------------------------------
	07/05/2014	Jefferson Elias		Corrected Bug #00013
									Version 1.0.1
    --------------------------------------------------------------------------------
  ==================================================================================
*/

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT 'View [security].[DatabaseUsers] Creation'

DECLARE @SQL VARCHAR(MAX)
IF  NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[security].[DatabaseUsers]'))
BEGIN
    SET @SQL = 'CREATE view [security].[DatabaseUsers]
                AS
                select ''Not implemented'' as Col1' 
    EXEC (@SQL)
    if @@ERROR = 0 
		PRINT '    View [security].[DatabaseUsers] created.'
END

SET @SQL = 'ALTER view [security].[DatabaseUsers]
                AS
                select
                    c.[Name],
                    c.[Job],
                    c.[Department],
                    l.[ServerName],
                    l.SQLLogin,
                    m.DbName,
					m.DbUserName,
                    m.DefaultSchema,
                    m.isLocked
                from [security].[Contacts] c
                    join [Security].[SQLlogins] l
                        on c.SQLLogin = l.SQLLogin
                    left join [security].[SQLMappings] m
						on l.SqlLogin   = m.SqlLogin
					  and  l.ServerName = m.ServerName
                where c.isActive = 1'
EXEC (@SQL)
if @@ERROR = 0
BEGIN
	PRINT '    View [security].[DatabaseUsers] altered.'
END
GO

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT '' 