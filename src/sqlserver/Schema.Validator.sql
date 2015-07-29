/*requires main.sql*/

/**
    Creation of the [validator] schema
  ==================================================================================
    DESCRIPTION
		This script creates the [validator] schema if it does not exist.
  ==================================================================================
  BUGS:
 
    BUGID       Fixed   Description
    ==========  =====   ==========================================================
    ----------------------------------------------------------------------------------
  ==================================================================================
  Notes :
 
        Exemples :
        -------
 
  ==================================================================================
  Revision history
 
    Date        Name                Description
    ==========  ================    ================================================
    24/12/2014  Jefferson Elias     VERSION 1.0.0
    --------------------------------------------------------------------------------
  ==================================================================================
*/

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT 'SCHEMA [validator] CREATION'

IF  NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'validator')
BEGIN	
    DECLARE @SQL VARCHAR(MAX);
    SET @SQL = 'CREATE SCHEMA [validator] AUTHORIZATION [dbo]'
    EXEC (@SQL)
    
	PRINT '   SCHEMA [validator] created.'
END
ELSE
	PRINT '   SCHEMA [validator] already exists.'
GO

PRINT '--------------------------------------------------------------------------------------------------------------'
PRINT '' 
