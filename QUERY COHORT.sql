-- -- INCLUSION -- --
SELECT COUNT(DISTINCT subject_id) AS subject_id_count, COUNT(DISTINCT hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT stay_id) AS stay_id_count
FROM mimic_icu.icustays;
-- 76,540 ICU stays of 69,211 unique admissions from 53,150 patients admitted to 
-- Beth Israel Deaconess Medical Center (BIDMC) between 2008 and 2019.

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count, COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_derived.age a ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE a.age >= 18;
-- everyone in the icustays dataset were adults

-- check icd_codes for Cardiac Arrest 
SELECT *
FROM mimic_hosp.d_icd_diagnoses
WHERE LOWER(icd_code) LIKE '%i46%' OR LOWER(icd_code) LIKE '%4275%'
ORDER BY icd_code ASC;

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s 
WHERE s.hadm_id IN
	(SELECT DISTINCT d.hadm_id 
	 	FROM mimic_hosp.diagnoses_icd d
	 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
	);
-- 1,751 adult patients with CA from 2,180 icu stays

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
	(SELECT DISTINCT d.hadm_id 
	 	FROM mimic_hosp.diagnoses_icd d
	 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
	));
-- 1,465 adult patients with CA from 1,849 icu stays survived first 24 hours of ICU stay

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g LEFT OUTER JOIN mimic_icu.icustays s9
		 		ON (s9.stay_id = g.stay_id)
			WHERE (g.gcs_motor + g.gcs_eyes <= 5) AND
		 		(g.charttime <= (s9.intime + interval '1 day'))
		)
	 );
-- 1,072 adult patients with CA from 1,172 icu stays with GCS(2 components)<=5 survived first 24 hours of ICU stay


-- -- EXCLUSION -- --

-- check for thrombolytic
SELECT *
FROM mimic_icu.d_items
WHERE LOWER(label) LIKE '%thrombolytic%'
ORDER BY label ASC;

SELECT *
FROM mimic_icu.chartevents
WHERE itemid = 227056;
-- no icu stays with thrombolytic therapy

SELECT *
FROM mimic_hosp.pharmacy
WHERE LOWER(medication) LIKE '%streptokinase%' OR 
	LOWER(medication) LIKE '%streptas%' OR
	LOWER(medication) LIKE '%kabikinase%' OR
	LOWER(medication) LIKE '%eminase%' OR
	LOWER(medication) LIKE '%anistreplase%' OR
	LOWER(medication) LIKE '%retavase%' OR
	LOWER(medication) LIKE '%reteplase%';
-- no thrombolytic med dispensed

SELECT *
FROM mimic_hosp.d_icd_procedures
WHERE LOWER(long_title) LIKE '%thrombolytic%'
ORDER BY long_title ASC;
-- various thrombolytic-related procedures

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  );
-- 1,048 adult patients from 1,147 icu stays with GCS(2 components)<=5,
-- no thrombolytic
-- survived first 24 hours of ICU stay

-- check for cardiogenic shocks
SELECT *
FROM mimic_hosp.d_icd_diagnoses
WHERE LOWER(long_title) LIKE '%cardiogenic shock%' 
ORDER BY long_title ASC;
-- R570 (ICD 10), 78551  (ICD9)

SELECT COUNT(DISTINCT subject_id)
FROM mimic_hosp.diagnoses_icd
WHERE (icd_version = '10' AND icd_code = 'R570') OR (icd_version = '9' AND icd_code = '78551') 
LIMIT 100;

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  ) AND 
	  (s.hadm_id NOT IN
	   	(SELECT DISTINCT de.hadm_id
			FROM mimic_hosp.diagnoses_icd de
	 		WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551'))
		)
	  );
-- 894 adult patients from 975 icu stays with GCS(2 components)<=5,
-- no thrombolytic, no cardiogenic shock
-- survived first 24 hours of ICU stay

-- check for hypoxemia
-- check for hypoxemia/SaO2-related itemid
SELECT *
FROM mimic_icu.d_items
WHERE LOWER(label) LIKE '%sao2%'
ORDER BY label ASC;
-- 224719	"SaO2 < 90% > 2 min"

SELECT DISTINCT value, valuenum
FROM mimic_icu.chartevents
WHERE itemid = 224719
ORDER BY valuenum;
-- no data

SELECT *
FROM mimic_hosp.d_icd_diagnoses
WHERE LOWER(long_title) LIKE '%hypoxemia%' 
ORDER BY long_title ASC;
-- R0902 (ICD 10), 79902  (ICD9)

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  ) AND 
	  (s.hadm_id NOT IN
	   	(SELECT DISTINCT de.hadm_id
			FROM mimic_hosp.diagnoses_icd de
	 		WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551')) OR
		 		((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902'))
		)
	  );
-- 878 adult patients from 956 icu stays with GCS(2 components)<=5,
-- no thrombolytic, no cardiogenic shock, no hypoxemia
-- survived first 24 hours of ICU stay

-- check for chronic hepatic failure
SELECT *
FROM mimic_hosp.d_icd_diagnoses
WHERE LOWER(long_title) LIKE '%chronic hepatic failure%' OR LOWER(long_title) LIKE '%chronic liver%'
ORDER BY icd_code ASC;
-- K721, K7210, K7211 (ICD 10)

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  ) AND 
	  (s.hadm_id NOT IN
	   	(SELECT DISTINCT de.hadm_id
			FROM mimic_hosp.diagnoses_icd de
	 		WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551')) OR
		 		((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902')) OR
		 		(de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211'))
		)
	  );
-- 878 adult patients from 956 icu stays with GCS(2 components)<=5,
-- no thrombolytic, no cardiogenic shock, no hypoxemia, (no one with chronic hepatic failure among the 835)
-- survived first 24 hours of ICU stay

-- check for chronic kidney failure
SELECT *
FROM mimic_hosp.d_icd_diagnoses
WHERE LOWER(long_title) LIKE '%chronic kidney disease%'
ORDER BY icd_code ASC;

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  ) AND 
	  (s.hadm_id NOT IN
	   	(SELECT DISTINCT de.hadm_id
			FROM mimic_hosp.diagnoses_icd de
	 		WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551')) OR
		 		((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902')) OR
		 		(de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) OR
		 	 	(de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) OR
	 			(de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189'))
		)
	  );
-- 718 adult patients from 780 icu stays with GCS(2 components)<=5,
-- no thrombolytic, no cardiogenic shock, no hypoxemia, (no one with chronic hepatic failure among the 835)
-- no severe chronic kidney failure
-- survived first 24 hours of ICU stay

SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  ) AND 
	  (s.hadm_id NOT IN
	   	(SELECT DISTINCT de.hadm_id
			FROM mimic_hosp.diagnoses_icd de
	 		WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551')) OR
		 		((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902')) OR
		 		(de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) OR
		 	 	(de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) OR
	 			(de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189'))
		)
	  ) AND ( 
	  (s.stay_id NOT IN
		(SELECT DISTINCT c.stay_id
			FROM mimic_icu.chartevents c
		 	WHERE c.itemid = 227632
		 	GROUP BY c.stay_id
		 	HAVING MAX(c.valuenum) < 32 OR MIN(c.valuenum) > 36
		 UNION
		 (SELECT DISTINCT c2.stay_id
			FROM mimic_icu.chartevents c2
		 	WHERE c2.itemid = 227634
		 	GROUP BY c2.stay_id
		 	HAVING MAX(c2.valuenum) < 32 OR MIN(c2.valuenum) > 36
		)
	  )
	  )
	);

-- 700 adult patients from 760 icu stays with GCS(2 components)<=5,
-- no thrombolytic, no cardiogenic shock, no hypoxemia, (no one with chronic hepatic failure among the 835)
-- no severe chronic kidney failure
-- survived first 24 hours of ICU stay
-- Paitents not on Arctic Sun + Patients on Arctic Sun that reach 32-36 at any point during ICU Stay

-- check count if exclude G00-G99 (Diseases of the Nervous System)
SELECT COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s LEFT OUTER JOIN mimic_core.admissions a 
		ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day')) AND
	(s.hadm_id IN
		(SELECT DISTINCT d.hadm_id 
	 		FROM mimic_hosp.diagnoses_icd d
		 	WHERE LOWER(d.icd_code) LIKE '%i46%' OR (d.icd_version = '9' AND d.icd_code = '4275')
		)
	) AND 
	(s.stay_id IN
		(SELECT DISTINCT g.stay_id
			FROM mimic_derived.gcs g
			WHERE (g.gcs_motor + g.gcs_eyes <= 5)
		)
	 ) AND 
	 (s.hadm_id NOT IN
		(SELECT DISTINCT p.hadm_id
			FROM mimic_hosp.procedures_icd p LEFT OUTER JOIN mimic_hosp.d_icd_procedures r ON
		 		(p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
		 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
		)
	  ) AND 
	  (s.hadm_id NOT IN
	   	(SELECT DISTINCT de.hadm_id
			FROM mimic_hosp.diagnoses_icd de
	 		WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551')) OR
		 		((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902')) OR
		 		(de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) OR
		 	 	(de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) OR
	 			(de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189')) OR
		 		(LOWER(de.icd_code) LIKE 'g%')
		)
	  );




-- -- Exposure check
-- check for temperature-related itemid
SELECT *
FROM mimic_icu.d_items
WHERE LOWER(label) LIKE '%temp%' AND unitname = '°C'
ORDER BY label ASC;
-- 223762	"Temperature Celsius"
-- 227632	"Arctic Sun/Alsius Temp #1 C"
-- 227634	"Arctic Sun/Alsius Temp #2 C"

-- Non-Exposure
SELECT
	COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s
	LEFT OUTER JOIN mimic_core.admissions a 
	ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day'))
	AND (s.hadm_id IN
			(SELECT DISTINCT d.hadm_id 
	 			FROM mimic_hosp.diagnoses_icd d
		 		WHERE LOWER(d.icd_code) LIKE '%i46%'
			 		OR (d.icd_version = '9' AND d.icd_code = '4275')
			)
		)
	AND (s.stay_id IN
			(SELECT DISTINCT g.stay_id
				FROM mimic_derived.gcs g
				WHERE (g.gcs_motor + g.gcs_eyes <= 5)
			)
	 	)
	AND (s.hadm_id NOT IN
			(SELECT DISTINCT p.hadm_id
				FROM mimic_hosp.procedures_icd p 
			 		LEFT OUTER JOIN mimic_hosp.d_icd_procedures r
			 		ON (p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
			 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
			)
	  	)
	AND (s.hadm_id NOT IN
	   		(SELECT DISTINCT de.hadm_id
				FROM mimic_hosp.diagnoses_icd de
	 			WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551'))
			 		OR ((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902'))
			 		OR (de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) 
			 		OR (de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) 
			 		OR (de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189'))
			)
	  	)
	AND (s.stay_id NOT IN
			(SELECT DISTINCT c.stay_id
				FROM mimic_icu.chartevents c
		 		WHERE c.itemid = 227632
		 		GROUP BY c.stay_id
		 		HAVING MAX(c.valuenum) < 32 OR MIN(c.valuenum) > 36
		 	UNION
		 	SELECT DISTINCT c2.stay_id
				FROM mimic_icu.chartevents c2
		 		WHERE c2.itemid = 227634
		 		GROUP BY c2.stay_id
		 		HAVING MAX(c2.valuenum) < 32 OR MIN(c2.valuenum) > 36
			)
	  )
	AND (s.stay_id NOT IN
			(SELECT DISTINCT c3.stay_id
				FROM mimic_icu.chartevents c3
		 		WHERE c3.itemid = 227632 OR c3.itemid = 227634 
			)
		);

SELECT *
FROM mimic_icu.icustays s
	LEFT OUTER JOIN mimic_core.admissions a 
	ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day'))
	AND (s.hadm_id IN
			(SELECT DISTINCT d.hadm_id 
	 			FROM mimic_hosp.diagnoses_icd d
		 		WHERE LOWER(d.icd_code) LIKE '%i46%'
			 		OR (d.icd_version = '9' AND d.icd_code = '4275')
			)
		)
	AND (s.stay_id IN
			(SELECT DISTINCT g.stay_id
				FROM mimic_derived.gcs g
				WHERE (g.gcs_motor + g.gcs_eyes <= 5)
			)
	 	)
	AND (s.hadm_id NOT IN
			(SELECT DISTINCT p.hadm_id
				FROM mimic_hosp.procedures_icd p 
			 		LEFT OUTER JOIN mimic_hosp.d_icd_procedures r
			 		ON (p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
			 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
			)
	  	)
	AND (s.hadm_id NOT IN
	   		(SELECT DISTINCT de.hadm_id
				FROM mimic_hosp.diagnoses_icd de
	 			WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551'))
			 		OR ((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902'))
			 		OR (de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) 
			 		OR (de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) 
			 		OR (de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189'))
			)
	  	)
	AND (s.stay_id NOT IN
			(SELECT DISTINCT c.stay_id
				FROM mimic_icu.chartevents c
		 		WHERE c.itemid = 227632
		 		GROUP BY c.stay_id
		 		HAVING MAX(c.valuenum) < 32 OR MIN(c.valuenum) > 36
		 	UNION
		 	SELECT DISTINCT c2.stay_id
				FROM mimic_icu.chartevents c2
		 		WHERE c2.itemid = 227634
		 		GROUP BY c2.stay_id
		 		HAVING MAX(c2.valuenum) < 32 OR MIN(c2.valuenum) > 36
			)
	  )
	AND (s.stay_id NOT IN
			(SELECT DISTINCT c3.stay_id
				FROM mimic_icu.chartevents c3
		 		WHERE c3.itemid = 227632 OR c3.itemid = 227634 
			)
		);


-- Exposure
SELECT
	COUNT(DISTINCT s.subject_id) AS subject_id_count,
	COUNT(DISTINCT s.hadm_id) AS hadm_id_count, 
	COUNT(DISTINCT s.stay_id) AS stay_id_count
FROM mimic_icu.icustays s
	LEFT OUTER JOIN mimic_core.admissions a 
	ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day'))
	AND (s.hadm_id IN
			(SELECT DISTINCT d.hadm_id 
	 			FROM mimic_hosp.diagnoses_icd d
		 		WHERE LOWER(d.icd_code) LIKE '%i46%'
			 		OR (d.icd_version = '9' AND d.icd_code = '4275')
			)
		)
	AND (s.stay_id IN
			(SELECT DISTINCT g.stay_id
				FROM mimic_derived.gcs g
				WHERE (g.gcs_motor + g.gcs_eyes <= 5)
			)
	 	)
	AND (s.hadm_id NOT IN
			(SELECT DISTINCT p.hadm_id
				FROM mimic_hosp.procedures_icd p 
			 		LEFT OUTER JOIN mimic_hosp.d_icd_procedures r
			 		ON (p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
			 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
			)
	  	)
	AND (s.hadm_id NOT IN
	   		(SELECT DISTINCT de.hadm_id
				FROM mimic_hosp.diagnoses_icd de
	 			WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551'))
			 		OR ((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902'))
			 		OR (de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) 
			 		OR (de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) 
			 		OR (de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189'))
			)
	  	)
	AND (s.stay_id NOT IN
			(SELECT DISTINCT c.stay_id
				FROM mimic_icu.chartevents c
		 		WHERE c.itemid = 227632
		 		GROUP BY c.stay_id
		 		HAVING MAX(c.valuenum) < 32 OR MIN(c.valuenum) > 36
		 	UNION
		 	SELECT DISTINCT c2.stay_id
				FROM mimic_icu.chartevents c2
		 		WHERE c2.itemid = 227634
		 		GROUP BY c2.stay_id
		 		HAVING MAX(c2.valuenum) < 32 OR MIN(c2.valuenum) > 36
			)
	  )
	AND (s.stay_id IN
			(SELECT DISTINCT c3.stay_id
				FROM mimic_icu.chartevents c3
		 		WHERE c3.itemid = 227632 OR c3.itemid = 227634 
			)
		);

SELECT *
FROM mimic_icu.icustays s
	LEFT OUTER JOIN mimic_core.admissions a 
	ON (s.subject_id = a.subject_id AND s.hadm_id = a.hadm_id)
WHERE (a.deathtime ISNULL OR a.deathtime > (s.intime + interval '1 day'))
	AND (s.hadm_id IN
			(SELECT DISTINCT d.hadm_id 
	 			FROM mimic_hosp.diagnoses_icd d
		 		WHERE LOWER(d.icd_code) LIKE '%i46%'
			 		OR (d.icd_version = '9' AND d.icd_code = '4275')
			)
		)
	AND (s.stay_id IN
			(SELECT DISTINCT g.stay_id
				FROM mimic_derived.gcs g
				WHERE (g.gcs_motor + g.gcs_eyes <= 5)
			)
	 	)
	AND (s.hadm_id NOT IN
			(SELECT DISTINCT p.hadm_id
				FROM mimic_hosp.procedures_icd p 
			 		LEFT OUTER JOIN mimic_hosp.d_icd_procedures r
			 		ON (p.icd_code = r.icd_code AND p.icd_version = r.icd_version)
			 	WHERE LOWER(r.long_title) LIKE '%thrombolytic%'
			)
	  	)
	AND (s.hadm_id NOT IN
	   		(SELECT DISTINCT de.hadm_id
				FROM mimic_hosp.diagnoses_icd de
	 			WHERE ((de.icd_version = '10' AND de.icd_code = 'R570') OR (de.icd_version = '9' AND de.icd_code = '78551'))
			 		OR ((de.icd_version = '10' AND de.icd_code = 'R0902') OR (de.icd_version = '9' AND de.icd_code = '79902'))
			 		OR (de.icd_version = '10' AND (de.icd_code = 'K721' OR de.icd_code = 'K7210' OR de.icd_code = 'K7211')) 
			 		OR (de.icd_version = '9' AND (de.icd_code = '5854' OR de.icd_code = '5855' OR de.icd_code = '5856' OR de.icd_code = '5859')) 
			 		OR (de.icd_version = '10' AND (de.icd_code = 'N184' OR de.icd_code = 'N185' OR de.icd_code = 'N189'))
			)
	  	)
	AND (s.stay_id NOT IN
			(SELECT DISTINCT c.stay_id
				FROM mimic_icu.chartevents c
		 		WHERE c.itemid = 227632
		 		GROUP BY c.stay_id
		 		HAVING MAX(c.valuenum) < 32 OR MIN(c.valuenum) > 36
		 	UNION
		 	SELECT DISTINCT c2.stay_id
				FROM mimic_icu.chartevents c2
		 		WHERE c2.itemid = 227634
		 		GROUP BY c2.stay_id
		 		HAVING MAX(c2.valuenum) < 32 OR MIN(c2.valuenum) > 36
			)
	  )
	AND (s.stay_id IN
			(SELECT DISTINCT c3.stay_id
				FROM mimic_icu.chartevents c3
		 		WHERE c3.itemid = 227632 OR c3.itemid = 227634 
			)
		);











