/****** Where are the error logs?  ******/
sp_readerrorlog


/****** Online executions?  ******/
SELECT  *
FROM    sys.dm_exec_requests  
        CROSS APPLY sys.dm_exec_sql_text(sql_handle)  