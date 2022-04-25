-- Extract Age
SELECT subject_id, hadm_id, age
FROM mimic_derived.age
WHERE hadm_id IN
(SELECT s.hadm_id
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
	  ));


-- Extract Gender
SELECT subject_id, gender
FROM mimic_core.patients 
WHERE subject_id IN
(SELECT s.subject_id
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
	  ));

-- Extract Height
SELECT subject_id, stay_id, height
FROM mimic_derived.height
WHERE subject_id IN
(SELECT s.subject_id
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
	  ));


-- Extract Weight
SELECT subject_id, stay_id, MIN(storetime), patientweight
FROM mimic_icu.inputevents
WHERE stay_id IN
(SELECT s.stay_id
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
	  ))
GROUP BY stay_id, subject_id, patientweight;



-- Extract VitalSigns
SELECT *
FROM mimic_derived.vitalsign
WHERE stay_id IN
(SELECT s.stay_id
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
	  ));


-- Extract charlson
SELECT subject_id, hadm_id, charlson_comorbidity_index
FROM mimic_derived.charlson
WHERE hadm_id IN
(SELECT s.hadm_id
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
	  ));



-- Extract heart rhythm
SELECT subject_id, charttime, heart_rhythm
FROM mimic_derived.rhythm
WHERE subject_id IN
(SELECT s.subject_id
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
	  ));




-- Extract GCS
SELECT subject_id, stay_id, charttime, gcs_motor, gcs_verbal, gcs_eyes
FROM mimic_derived.gcs
WHERE stay_id IN
(SELECT s.stay_id
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
	  ));


-- Extract apsiii
SELECT stay_id, apsiii
FROM mimic_derived.apsiii
WHERE stay_id IN
(SELECT s.stay_id
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
	  ));