/***
 * Diary setup check queries for easier and more effiscient administration of Patricia's Diary-related setup.
 * 
 * Contributors (add your name here after a contribution): 
 * Peik Hovi
 * 
 * License: Apache license v.2.0
 *
 * SQL versions (tested): MSSQL2008R2
 * Patricia database versions (tested): 5.0.0 - 5.5.1 
 * Remark: Might work on earlier or later database versions also. 
 * 
 * Please, include a small description of and how to use your query.
 * 
 * ALL CODE IS WITHOUT ANY WARRANTIES WHATSOEVER! USE AT YOUR OWN RISK AND DISCRETION!
 ***/

/***
 * Description:  Quickly find out from which Diary Matrices and Fields a Term, or any Term in the same Workflow 
 * with it, is triggered from. This query was originally published at http://forum.patrix.com/phpbb/viewtopic.php?f=48&t=324
 *
 * Usage: Just copy paste the query to your query tool and Put your Term Id in the variable @es_id and you are 
 * good to go (the value 820 is only an example!).
 *
 ***/

DECLARE @es_id int;

SET @es_id = 820;

SELECT 
	cc.CASE_MASTER_ID,
	cm.CASE_MASTER_LABEL,
	mlse.CASE_CATEGORY_ID,
	cc.CASE_TYPE_ID,
	sn.STATE_NAME,      
	att.APPLICATION_TYPE_NAME,      
	slt.SERVICE_LEVEL_LABEL,                  
	mlse.FIELD_NUMBER,
	df.DIARY_TYPE_LABEL,
	cc.CASE_CATEGORY_CODE,
	mlse.CASE_CATEGORY_CODE,      
	mlse.EVENT_SCHEME_ID

FROM MATRIX_LINE_START_EVENTS mlse   
	INNER JOIN DIARY_FIELD df ON
		mlse.FIELD_NUMBER = df.FIELD_NUMBER      
	INNER JOIN CASE_CATEGORY cc ON
		mlse.CASE_CATEGORY_ID = cc.CASE_CATEGORY_ID
	INNER JOIN STATE_NAME sn ON
		cc.STATE_ID = sn.STATE_ID AND
		sn.LANGUAGE_ID = 3   
	INNER JOIN CASE_MASTER cm ON
		cc.CASE_MASTER_ID = cm.CASE_MASTER_ID
	LEFT OUTER JOIN APPLICATION_TYPE_TEXT att ON
		cc.APPLICATION_TYPE_ID = att.APPLICATION_TYPE_ID AND
		att.LANGUAGE_ID = 3        
	LEFT OUTER JOIN SERVICE_LEVEL_TEXT slt ON
		cc.SERVICE_LEVEL_ID = slt.SERVICE_LEVEL_ID AND
		slt.LANGUAGE_ID =3

WHERE mlse.EVENT_SCHEME_ID IN
	(SELECT DISTINCT eiwfs1.EVENT_SCHEME_ID
	 FROM EVENT_IN_WORK_FLOW_SHEET eiwfs1
	 WHERE eiwfs1.REPORT_ID IN
		(SELECT DISTINCT eiwfs2.REPORT_ID
		 FROM EVENT_IN_WORK_FLOW_SHEET eiwfs2
		 WHERE eiwfs2.EVENT_SCHEME_ID = @es_id))

ORDER BY cc.CASE_MASTER_ID, mlse.CASE_CATEGORY_ID

/***
 * Description: Quickly find all Diary Matrices where a Diary Field is defined.
 * 
 * Usage: Just copy paste the query to your query tool and Put your Term Id in the variable @diary_field_no and you are 
 * good to go (the value 53 is only an example!).
 * 
 ***/

DECLARE @diary_field_no int;
SET @diary_field_no = 53;

SELECT dml.FIELD_NUMBER,
	   df.DIARY_TYPE_LABEL,	
	   dlt.DIARY_LINE_TEXT,
	   dm.MATRIX_TITLE, 	   	   
	   cm.CASE_MASTER_LABEL,
	   att.APPLICATION_TYPE_NAME,
	   sn.STATE_NAME,
	   CASE WHEN (dml.DO_NOT_INHERIT = 1) 
			THEN '*** BLOCKED ***'
			ELSE 'DEFINED'
		END AS
		MATRIX_STATUS	   
FROM DIARY_MATRIX_LINE dml
	INNER JOIN DIARY_LINE_TEXT dlt ON
		dml.FIELD_NUMBER = dlt.FIELD_NUMBER AND
		dml.DIARY_LINE_TEXT_SEQ = dlt.DIARY_LINE_TEXT_SEQ AND
		dlt.DIARY_LINE_TEXT_LANGUAGE = 3
	INNER JOIN DIARY_MATRIX dm ON
		dml.CASE_CATEGORY_ID = dm.CASE_CATEGORY_ID
	INNER JOIN DIARY_FIELD df ON
		dml.FIELD_NUMBER = df.FIELD_NUMBER
	INNER JOIN CASE_CATEGORY cc ON
		dml.CASE_CATEGORY_ID = cc.CASE_CATEGORY_ID
	INNER JOIN STATE_NAME sn ON
		cc.STATE_ID = sn.STATE_ID AND
		sn.LANGUAGE_ID = 3	
	INNER JOIN CASE_MASTER cm ON
		cc.CASE_MASTER_ID = cm.CASE_MASTER_ID
	LEFT OUTER JOIN APPLICATION_TYPE_TEXT att ON
	   	cc.APPLICATION_TYPE_ID = att.APPLICATION_TYPE_ID AND
	   	att.LANGUAGE_ID = 3	      
	LEFT OUTER JOIN SERVICE_LEVEL_TEXT slt ON
	   	cc.SERVICE_LEVEL_ID = slt.SERVICE_LEVEL_ID AND
	   	slt.LANGUAGE_ID =3
WHERE dml.FIELD_NUMBER = @diary_field_no    
ORDER BY cm.CASE_MASTER_LABEL,dm.MATRIX_TITLE

/***
 * Description: Quickly find defined and undefined Diary Matrices for a Term, that is, if a
 * Term is defined to be triggered from a Diary Field on a certain Diary Matrix level then all 
 * the availabe Diary Matrix where that Diary Field is defined are also displayed. 
 * This has proven to be a very useful tool for finding and correcting missing setup...
 *   
 * Usage: Just copy paste the query to your query tool and Put your Term Id in the variable @es_id and you are
 * good to go (the value 550 is only an example!).
 * 
 ***/

DECLARE @es_id int;
SET @es_id = 550;

(SELECT @es_id AS TERM_ID,
		dml.FIELD_NUMBER,
		df.DIARY_TYPE_LABEL,
		dlt.DIARY_LINE_TEXT,
	    dm.MATRIX_TITLE, 
	    cm.CASE_MASTER_LABEL,
	    sn.STATE_NAME,		      
	    att.APPLICATION_TYPE_NAME,	    
	    CASE WHEN (cc.STATE_ID = '**') 
			THEN (
				SELECT sn3.STATE_NAME 
				FROM CASE_TYPE_DEFAULT_STATE ctds2							
					 INNER JOIN STATE_NAME sn3 ON
						ctds2.DEF_STATE_ID = sn3.STATE_ID AND
						sn3.LANGUAGE_ID = 3
				WHERE ctds2.CASE_TYPE_ID = cc.CASE_MASTER_ID AND
				      ctds2.STATE_ID = 'FI'
			) 
			ELSE sn2.STATE_NAME 
		END AS DEFAULT_STATE,
		CASE WHEN (dml.DO_NOT_INHERIT = 1) 
			THEN '*** FIELD BLOCKED ***'
			ELSE '*** MISSING ***'
		END AS
		MATRIX_TERM_STATUS
	    
	   
FROM DIARY_MATRIX_LINE dml
	INNER JOIN DIARY_LINE_TEXT dlt ON
		dml.FIELD_NUMBER = dlt.FIELD_NUMBER AND
		dml.DIARY_LINE_TEXT_SEQ = dlt.DIARY_LINE_TEXT_SEQ AND
		dlt.DIARY_LINE_TEXT_LANGUAGE = 3
	INNER JOIN DIARY_MATRIX dm ON
		dml.CASE_CATEGORY_ID = dm.CASE_CATEGORY_ID
	INNER JOIN DIARY_FIELD df ON
		dml.FIELD_NUMBER = df.FIELD_NUMBER
	INNER JOIN CASE_CATEGORY cc ON
		dml.CASE_CATEGORY_ID = cc.CASE_CATEGORY_ID
	INNER JOIN STATE_NAME sn ON
		cc.STATE_ID = sn.STATE_ID AND
		sn.LANGUAGE_ID = 3						
	INNER JOIN CASE_MASTER cm ON
		cc.CASE_MASTER_ID = cm.CASE_MASTER_ID	
	LEFT OUTER JOIN CASE_TYPE_DEFAULT_STATE ctds ON
		ctds.CASE_TYPE_ID = cc.CASE_MASTER_ID AND
		ctds.STATE_ID = cc.STATE_ID	
	LEFT OUTER JOIN STATE_NAME sn2 ON
			ctds.DEF_STATE_ID = sn2.STATE_ID AND
			sn2.LANGUAGE_ID = 3			
	LEFT OUTER JOIN APPLICATION_TYPE_TEXT att ON
		cc.APPLICATION_TYPE_ID = att.APPLICATION_TYPE_ID AND
	   	att.LANGUAGE_ID = 3	      
	LEFT OUTER JOIN SERVICE_LEVEL_TEXT slt ON
	   	cc.SERVICE_LEVEL_ID = slt.SERVICE_LEVEL_ID AND
	   	slt.LANGUAGE_ID =3
WHERE dml.FIELD_NUMBER IN
	(SELECT DISTINCT mlse.FIELD_NUMBER
	 FROM MATRIX_LINE_START_EVENTS mlse
	 WHERE mlse.EVENT_SCHEME_ID = @es_id)
	 AND 
	 dm.CASE_CATEGORY_ID NOT IN
	 (SELECT DISTINCT mlse2.CASE_CATEGORY_ID
	  FROM MATRIX_LINE_START_EVENTS mlse2
	  WHERE mlse2.EVENT_SCHEME_ID = @es_id))
UNION

(SELECT @es_id AS TERM_ID,
		dml.FIELD_NUMBER,
		df.DIARY_TYPE_LABEL,
		dlt.DIARY_LINE_TEXT,	   
		dm.MATRIX_TITLE,
		cm.CASE_MASTER_LABEL,
		sn.STATE_NAME,	   	   
		att.APPLICATION_TYPE_NAME,
		CASE WHEN (cc.STATE_ID = '**') 
			THEN (
				SELECT sn3.STATE_NAME 
				FROM CASE_TYPE_DEFAULT_STATE ctds2							
					 INNER JOIN STATE_NAME sn3 ON
						ctds2.DEF_STATE_ID = sn3.STATE_ID AND
						sn3.LANGUAGE_ID = 3
				WHERE ctds2.CASE_TYPE_ID = cc.CASE_MASTER_ID AND
				      ctds2.STATE_ID = 'FI'
			) 
			ELSE sn2.STATE_NAME 
		END AS DEFAULT_STATE,
		CASE WHEN (dml.DO_NOT_INHERIT = 1) 
			THEN '*** FIELD BLOCKED ***'
			ELSE 'DEFINED'
		END AS
		MATRIX_TERM_STATUS
	   
FROM MATRIX_LINE_START_EVENTS mlse
	   INNER JOIN DIARY_MATRIX_LINE dml ON
		mlse.FIELD_NUMBER = dml.FIELD_NUMBER AND
		mlse.CASE_CATEGORY_ID = dml.CASE_CATEGORY_ID
	   INNER JOIN DIARY_LINE_TEXT dlt ON
		dml.FIELD_NUMBER = dlt.FIELD_NUMBER AND
		dml.DIARY_LINE_TEXT_SEQ = dlt.DIARY_LINE_TEXT_SEQ AND
		dlt.DIARY_LINE_TEXT_LANGUAGE = 3
	   INNER JOIN DIARY_MATRIX dm ON
	        mlse.CASE_CATEGORY_ID = dm.CASE_CATEGORY_ID
	   INNER JOIN DIARY_FIELD df ON
		mlse.FIELD_NUMBER = df.FIELD_NUMBER	   
	   INNER JOIN CASE_CATEGORY cc ON
		mlse.CASE_CATEGORY_ID = cc.CASE_CATEGORY_ID
	   INNER JOIN STATE_NAME sn ON
		cc.STATE_ID = sn.STATE_ID AND
		sn.LANGUAGE_ID = 3	
	   INNER JOIN CASE_MASTER cm ON
		cc.CASE_MASTER_ID = cm.CASE_MASTER_ID	   
	   LEFT OUTER JOIN CASE_TYPE_DEFAULT_STATE ctds ON
		ctds.CASE_TYPE_ID = cc.CASE_MASTER_ID AND
		ctds.STATE_ID = cc.STATE_ID	
	   LEFT OUTER JOIN STATE_NAME sn2 ON
		ctds.DEF_STATE_ID = sn2.STATE_ID AND
		sn2.LANGUAGE_ID = 3						   
	   LEFT OUTER JOIN APPLICATION_TYPE_TEXT att ON
		cc.APPLICATION_TYPE_ID = att.APPLICATION_TYPE_ID AND
	   	att.LANGUAGE_ID = 3	      
	   LEFT OUTER JOIN SERVICE_LEVEL_TEXT slt ON
	   	cc.SERVICE_LEVEL_ID = slt.SERVICE_LEVEL_ID AND
	   	slt.LANGUAGE_ID =3
WHERE mlse.EVENT_SCHEME_ID = @es_id)	 
	 
ORDER BY dml.FIELD_NUMBER,		 
		 cm.CASE_MASTER_LABEL,
		 dm.MATRIX_TITLE

/*** EOF ***/
