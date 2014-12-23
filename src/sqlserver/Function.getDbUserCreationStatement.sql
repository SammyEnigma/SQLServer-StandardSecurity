/*requires Schema.Security.sql*/

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT 'Function [security].[getDbUserCreationStatement] Creation'

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[security].[getDbUserCreationStatement]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
    EXECUTE ('CREATE FUNCTION [security].[getDbUserCreationStatement] ( ' +
            ' @ServerName    varchar(512), ' +
            ' @DbName    varchar(50) ' +
            ') ' +
            'RETURNS VARCHAR(max) ' +
            'AS ' +
            'BEGIN ' +
            '   RETURN ''Not implemented'' ' +
            'END')
	PRINT '    Function [security].[getDbUserCreationStatement] created.'
END
GO

ALTER FUNCTION [security].[getDbUserCreationStatement] (
    @DbName  		                varchar(32),
	@LoginName		                varchar(32),
	@UserName		                varchar(32),
	@SchemaName		                varchar(32),
    @isActive                       BIT = 1,
    @NoHeader                       BIT = 0,
    @NoDependencyCheckGen           BIT = 0,
    @Debug                          BIT = 0
)
RETURNS VARCHAR(max)
AS
/*
 ===================================================================================
  DESCRIPTION:
    This function returns a string with all statements for a database user creation
 	This procedure sets the default schema and doesn't do anything 
 	about login to user mapping.
 
  ARGUMENTS :
    @DbName         name of the database on that server in which execute the statements generated by this function
	@LoginName		Name of the login that will be used to connect on this database
 	@UserName		the database user to create
 	@SchemaName		the database schema to use by default for the specified user name
 
  REQUIREMENTS:
  
  EXAMPLE USAGE :
    PRINT [security].[getDbUserCreationStatement] ('TESTING_ONLY_TESTING','jel_test','jel_test','dbo',1,0,0,1)

 
  ==================================================================================
  BUGS:
 
    BUGID       Fixed   Description
    ==========  =====   ==========================================================
    ----------------------------------------------------------------------------------
  ==================================================================================
  NOTES:
  AUTHORS:
       .   VBO     Vincent Bouquette   (vincent.bouquette@chu.ulg.ac.be)
       .   BBO     Bernard Bozert      (bernard.bozet@chu.ulg.ac.be)
       .   JEL     Jefferson Elias     (jelias@chu.ulg.ac.be)
 
  COMPANY: CHU Liege
  ==================================================================================
  Revision History
 
    Date        Name        Description
    ==========  =====       ==========================================================
    24/04/2014  JEL         Version 0.1.0
    ----------------------------------------------------------------------------------
    22/12/2014  JEL         Added some parameter for new generator with backward compatibility
                            Version 0.2.0
    ----------------------------------------------------------------------------------
 ===================================================================================
*/
BEGIN

    --SET NOCOUNT ON;
    DECLARE @versionNb        varchar(16) = '0.2.0';
    DECLARE @tsql             varchar(max);    
    DECLARE @ErrorDbNotExists varchar(max);
    DECLARE @LineFeed 		  VARCHAR(10);
    DECLARE @DynDeclare  VARCHAR(512);
    
    /* Sanitize our inputs */
	SELECT 
		@LineFeed 			= CHAR(13) + CHAR(10),
        @DynDeclare         = 'DECLARE @CurDbUser     VARCHAR(64)' + @LineFeed +
                              'DECLARE @CurDbName     VARCHAR(64)' + @LineFeed +
                              'DECLARE @CurLoginName  VARCHAR(64)' + @LineFeed +
                              'DECLARE @CurSchemaName VARCHAR(64)' + @LineFeed +
                              'SET @CurDbUser     = ''' + QUOTENAME(@UserName) + '''' + @LineFeed +
                              'SET @CurDbName     = ''' + QUOTENAME(@DbName) + '''' + @LineFeed +
                              'SET @CurLoginName  = ''' + QUOTENAME(@LoginName) + '''' + @LineFeed +
                              'SET @CurSchemaName = ''' + QUOTENAME(@SchemaName) + '''' + @LineFeed,                              
        @ErrorDbNotExists   =  N'The given database ('+QUOTENAME(@DbName)+') does not exist'
    
    
    if @NoHeader = 0 
    BEGIN    
        SET @tsql = isnull(@tsql,'') + 
                    '/**' +@LineFeed+
                    ' * Database user creation version ' + @versionNb + '.' +@LineFeed+
                    ' *   Database Name  : ' + @DbName +@LineFeed+
                    ' *   User Name 	 : ' + @UserName 	 +@LineFeed+
                    ' *   Default Schema : ' + @SchemaName 	 +@LineFeed+
                    ' */'   + @LineFeed+
                    ''      + @LineFeed
                
    END 
    
    set @tsql = isnull(@tsql,'') + @DynDeclare
    
    if @NoDependencyCheckGen = 0 
    BEGIN
        SET @tsql = @tsql + 
				'-- 1.1 Check that the database actually exists' + @LineFeed+
                'if (NOT exists (select 1 from sys.databases where QUOTENAME(name) = @CurDbName))' + @LineFeed +
                'BEGIN' + @LineFeed +
                '    RAISERROR ( ''' + @ErrorDbNotExists + ''',0,1 ) WITH NOWAIT' + @LineFeed +
                '    return' + @LineFeed+
                'END' + @LineFeed +
                '' + @LineFeed +
                'Use '+ QUOTENAME(@DbName) + @LineFeed+
				'-- 1.2 Check that the schema exists in that database' + @LineFeed + 
				'if not exists (select 1 from sys.schemas where QUOTENAME(name) = @CurSchemaName)' + @LineFeed +
				'BEGIN' + @LineFeed + 
                '    RAISERROR ( ''The given schema ('+@SchemaName + ') does not exist'',0,1 ) WITH NOWAIT' + @LineFeed +
                '    return' + @LineFeed+	
				'END' + @LineFeed
    END
    
    SET @tsql = @tsql + 
                'Use '+ QUOTENAME(@DbName) + @LineFeed +
                'DECLARE @gotName       VARCHAR(64)' + @LineFeed +                
                'DECLARE @defaultSchema VARCHAR(64)' + @LineFeed +                
                'select @gotName = name, @defaultSchema = default_schema_name from sys.database_principals WHERE QUOTENAME(NAME) = @CurDbUser and Type in (''S'',''U'')' + @LineFeed +
                'IF @gotName is null' + @LineFeed +
				'BEGIN' + @LineFeed +
				'    EXEC (''create user '' + @CurDbUser + '' FOR LOGIN '' + @CurLoginName )' + @LineFeed +
				'END' + @LineFeed +
                'if isnull(@defaultSchema,''<NULL>'') <> isnull(@CurSchemaName,''<NULL>'')' + @LineFeed + 
                'BEGIN' + @LineFeed +
				'    EXEC (''alter user '' + @CurDbUser + '' WITH DEFAULT_SCHEMA = '' + @CurSchemaName )' + @LineFeed +
                'END' + @LineFeed    
    
    
    SET @tsql = @tsql +
				'GO'  + @LineFeed 
    
    RETURN @tsql
END
GO

PRINT '    Function [security].[getDbUserCreationStatement] altered.'

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT '' 