/****** Where are the error logs?  ******/
sp_readerrorlog


/****** Online executions?  ******/
SELECT  *
FROM    sys.dm_exec_requests  
        CROSS APPLY sys.dm_exec_sql_text(sql_handle)  
		
		
/****** Size databases?  ******/
exec sp_spaceused 

SELECT      sys.databases.name,  
            CONVERT(VARCHAR,SUM(size)*8/1024)+' MB' AS [Total disk space MB] ,
			CONVERT(VARCHAR,SUM(size)*8/1024000)+' GB' AS [Total disk space GB]  
FROM        sys.databases   
JOIN        sys.master_files  
ON          sys.databases.database_id=sys.master_files.database_id  
GROUP BY    sys.databases.name  
ORDER BY    sys.databases.name 


/****** Size databases and logs?  ******/
SELECT 
      database_name = DB_NAME(database_id)
    , log_size_mb = CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(8,2))
    , total_size_mb = CAST(SUM(size) * 8. / 1024 AS DECIMAL(8,2))
FROM sys.master_files WITH(NOWAIT)
WHERE database_id = DB_ID() -- for current db 
GROUP BY database_id

/****** Are running jobs?  ******/
SELECT
    ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,      
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh 
    ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j 
ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
AND start_execution_date is not null
AND stop_execution_date is null;



/****** Size of all tables?  ******/
USE database_name
GO 
SELECT
  t.Name                                       AS TableName,
  s.Name                                       AS SchemaName,
  p.Rows                                       AS RowCounts,
  SUM(a.total_pages) * 8                       AS TotalSpaceKB,
  SUM(a.used_pages) * 8                        AS UsedSpaceKB,
  (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
FROM
  sys.tables t
  INNER JOIN sys.indexes i ON t.object_id = i.object_id
  INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
  INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
  LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE
  t.Name NOT LIKE 'dt%'
  AND t.is_ms_shipped = 0
  AND i.object_id > 255
GROUP BY
  t.Name, s.Name, p.Rows
ORDER BY
  t.Name;
GO



/****** Column data types?  ******/

SELECT COLUMN_NAME,
       DATA_TYPE,
       IS_NULLABLE,
       CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION,
       NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='your_table_name';