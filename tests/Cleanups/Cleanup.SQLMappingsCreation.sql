/*requires cleanups.sql*/
/*requires Cleanup.DatabaseSchemas.sql*/

SET @TestID = @TestID + 1 ;
SET @TestName = 'SQLMappings Cleanup by T-SQL "DELETE" statement ';
SET @TestDescription = 'Removes Data from [security].[SQLMappings] table';
SET @TestResult = 'SUCCESS';
SET @ErrorMessage = '';

if($(NoCleanups) = 1)
BEGIN
    SET @TestResult = 'SKIPPED'
END

DECLARE getTestContacts CURSOR LOCAL FOR 
    SELECT SQLLogin
    FROM $(TestingSchema).testContacts ;
    
OPEN getTestContacts ;

FETCH Next From getTestContacts into @SQLLogin ;

SET @TmpIntVal = 0

WHILE @@FETCH_STATUS = 0 and $(NoCleanups) = 0
BEGIN 
    PRINT '    . Removing SQL Mappings for SQL Login ' + QUOTENAME(@SQLLogin) + ' from list for ' + @@SERVERNAME + ' SQL instance';

/*    
    SET @TestID = @TestID + 1 ;
    SET @TestName = 'Deletion of unused SQL Mappings ' + QUOTENAME(@SQLLogin) ;
    SET @TestDescription = 'deletes a record from the [security].[SQLMappings] table';
    SET @TestResult = 'SUCCESS';
    SET @ErrorMessage = NULL ;
*/
    BEGIN TRY    
		BEGIN TRAN ;
		DELETE FROM [security].[SQLMappings] WHERE ServerName = @@SERVERNAME and SqlLogin = @SQLLogin ;            		
		SET @TmpIntVal = @TmpIntVal + @@ROWCOUNT;
		COMMIT;
    END TRY 
    BEGIN CATCH         
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK ;
        END
        --SET @ErrorCount = @ErrorCount + 1
        SET @TestResult = 'FAILURE';
        if(LEN(@ErrorMessage) > 0)
            SET @ErrorMessage = @ErrorMessage + @LineFeed
         
        SET @ErrorMessage = @ErrorMessage + 'Deletion of unused SQL Mappings ' + QUOTENAME(@SQLLogin)  + ' : ' + ERROR_MESSAGE() ;
        
        PRINT '        > ERROR ' + REPLACE(REPLACE(@ErrorMessage,CHAR(10),' ') , CHAR(13) , ' ')
    END CATCH     
    
    FETCH Next From getTestContacts into @SQLLogin ;
END ;

CLOSE getTestContacts ;
DEALLOCATE getTestContacts;

if( $(NoCleanups) = 0 and @TmpIntVal <> $(expectedSQLMappingsTotalCount))
BEGIN 
    SET @TestResult = 'FAILURE';
    SET @ErrorMessage = @ErrorMessage + 'Unable to delete all expected SQL Mappings' ;
    
    if(LEN(@ErrorMessage) > 0)
        SET @ErrorMessage = @ErrorMessage + @LineFeed
    
    PRINT '        > ERROR Unable to delete all SQL Mappings';        
END 

if(@TestResult = 'FAILURE')
    SET @ErrorCount = @ErrorCount + 1

BEGIN TRAN ;
INSERT into $(TestingSchema).testResults values (@TestID , '$(Feature)', @TestName , @TestDescription, @TestResult , @ErrorMessage );
COMMIT;