setwd('C:/Users/DarkZ/OneDrive/Desktop/NUS MSBA/Modules/SPH5104/Group Project')

exposure <- read.csv('icustays_exposure_group.csv',header=T,stringsAsFactors=F)
non_exposure <- read.csv('icustays_non_exposure_group.csv',header=T,stringsAsFactors=F)

exposure$expose = 1
non_exposure$expose = 0
combined <- rbind(exposure, non_exposure)
combined[,'intime'] <- as.POSIXct(combined[,'intime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
combined[,'outtime'] <- as.POSIXct(combined[,'outtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
combined[,'admittime'] <- as.POSIXct(combined[,'admittime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
combined[,'dischtime'] <- as.POSIXct(combined[,'dischtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
combined[,'deathtime'] <- as.POSIXct(combined[,'deathtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
combined[,'edregtime'] <- as.POSIXct(combined[,'edregtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
combined[,'edouttime'] <- as.POSIXct(combined[,'edouttime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")

combined <- combined[order(combined[,'subject_id'],combined[,'intime'],decreasing=F),]
combined <- combined[which(!duplicated(combined[,'subject_id'])),]

write.csv(combined,'studyCohort_base.csv',row.names=F)

age <- read.csv('studyCohort_age.csv',header=T,stringsAsFactors=F)
mtch <- match(combined$hadm_id,age$hadm_id)
mean(is.na(mtch)) # no missing data
combined$age <- age$age[mtch]

gender <- read.csv('studyCohort_gender.csv',header=T,stringsAsFactors=F)
mtch <- match(combined$subject_id,gender$subject_id)
mean(is.na(mtch)) # no missing data
combined$gender <- gender$gender[mtch]

height <- read.csv('studyCohort_height.csv',header=T,stringsAsFactors=F)
mtch <- match(combined$stay_id,height$stay_id)
mean(is.na(mtch)) # 26% missing data
tapply(mtch,combined$expose,function(x) mean(!is.na(x))) # 20+% missing for both expose and non-expose
combined$height <- height$height[mtch]

weight <- read.csv('studyCohort_weight.csv',header=T,stringsAsFactors=F)
mtch <- match(combined$stay_id,weight$stay_id)
mean(is.na(mtch)) # 0.3% missing data
combined$weight <- weight$patientweight[mtch]

vital <- read.csv('studyCohort_vitalSigns.csv',header=T,stringsAsFactors=F)
vital[,'charttime'] <- as.POSIXct(vital[,'charttime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
vital <- vital[,which(!grepl('temperature_site',colnames(vital)))]
for(i in 4:ncol(vital)) vital[,i] <- as.numeric(vital[,i])
r = NULL
for(i in 1:nrow(combined)){
	index <- which(vital$stay_id==combined$stay_id[i] &
		as.numeric(difftime(vital$charttime, combined$intime[i], units = "days")) <= 1)

	mean_value <- apply(vital[index,4:ncol(vital)],2,mean,na.rm=T)
	names(mean_value) <- paste(names(mean_value),'_first24h_mean',sep='')
	max_value <- apply(vital[index,4:ncol(vital)],2,max,na.rm=T)
	names(max_value) <- paste(names(max_value),'_first24h_max',sep='')
	min_value <- apply(vital[index,4:ncol(vital)],2,min,na.rm=T)
	names(min_value) <- paste(names(min_value),'_first24h_min',sep='')
	if(sum(mean_value=='NaN') > 0) mean_value[which(mean_value=='NaN')] <- NA
	if(sum(max_value=='-Inf') > 0) max_value[which(max_value=='-Inf')] <- NA
	if(sum(min_value=='Inf') > 0) min_value[which(min_value=='Inf')] <- NA

	r = rbind(r, c(combined$subject_id[i], combined$hadm_id[i], combined$stay_id[i],
		mean_value, max_value, min_value))
}

combined <- cbind(combined,r[,-(1:3)])

charlson <- read.csv('studyCohort_charlson.csv',header=T,stringsAsFactors=F)
mtch <- match(combined$hadm_id,charlson$hadm_id)
mean(is.na(mtch)) # no missing data
combined$charlson_comorbidity_index <- weight$charlson_comorbidity_index[mtch]

library(chron)
combined$icu_entrydate_weekend = is.weekend(combined$intime)

rhythm <- read.csv('studyCohort_rhythm.csv',header=T,stringsAsFactors=F)
rhythm[,'charttime'] <- as.POSIXct(rhythm[,'charttime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")

combined$heart_rhythm_first24h_firstRecorded <- NA
combined$heart_rhythm_first24h_numTypeRecorded <- NA
for(i in 1:nrow(combined)){
	index <- which(rhythm$subject_id==combined$subject_id[i] &
		rhythm$charttime >= combined$intime[i] &
	 	rhythm$charttime <= combined$intime[i] + 60*60*24)
	if(length(index)==0) next
	temp <- rhythm[index,]
	temp <- temp[which(temp$heart_rhythm!='NULL'),]
	temp <- temp[order(temp$charttime,decreasing=F),]
	combined$heart_rhythm_first24h_firstRecorded[i] <- temp$heart_rhythm[1]
	combined$heart_rhythm_first24h_numTypeRecorded[i] <- length(unique(temp$heart_rhythm))
}

combined[,'discharge_location'][which(combined[,'discharge_location']=='NULL')] <- NA
combined[,'language'][which(combined[,'language']=='?')] <- NA
combined[,'marital_status'][which(combined[,'marital_status']=='NULL')] <- NA
combined[,'ethnicity'][which(combined[,'ethnicity']=='UNKNOWN')] <- NA
combined[,'ethnicity'][which(combined[,'ethnicity']=='UNABLE TO OBTAIN')] <- NA

head(combined[,-(1:18)])
mean(is.na(combined[,62]))
table(combined[,62]);sum(table(combined[,62]))

write.csv(combined,'studyCohort_final.csv',row.names=F)

missingness <- apply(combined,2,function(x) round(mean(is.na(x)),2))
missingness <- sort(missingness[which(missingness>0)],decreasing=T)
missingness <- missingness[which(!grepl('time',names(missingness)))]
par(mar = c(18, 4, 1, 1))
barplot(missingness*100,las = 2,ylab='% missing')



########## Cohort version 2
combined <- read.csv('studyCohort_final.csv',header=T,stringsAsFactors=F)
head(combined)

combined[,'intime'] <- as.POSIXct(combined[,'intime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'outtime'] <- as.POSIXct(combined[,'outtime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'admittime'] <- as.POSIXct(combined[,'admittime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'dischtime'] <- as.POSIXct(combined[,'dischtime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'deathtime'] <- as.POSIXct(combined[,'deathtime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'edregtime'] <- as.POSIXct(combined[,'edregtime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'edouttime'] <- as.POSIXct(combined[,'edouttime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'last_gcs_charttime'] <- as.POSIXct(combined[,'last_gcs_charttime'], format="%d/%m/%Y %H:%M", tz="UTC")
combined[,'first_gcs_charttime'] <- as.POSIXct(combined[,'first_gcs_charttime'], format="%d/%m/%Y %H:%M", tz="UTC")

#combined[,'intime'] <- as.POSIXct(combined[,'intime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'outtime'] <- as.POSIXct(combined[,'outtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'admittime'] <- as.POSIXct(combined[,'admittime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'dischtime'] <- as.POSIXct(combined[,'dischtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'deathtime'] <- as.POSIXct(combined[,'deathtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'edregtime'] <- as.POSIXct(combined[,'edregtime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'edouttime'] <- as.POSIXct(combined[,'edouttime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'last_gcs_charttime'] <- as.POSIXct(combined[,'last_gcs_charttime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")
#combined[,'first_gcs_charttime'] <- as.POSIXct(combined[,'first_gcs_charttime'], format="%Y-%m-%d %H:%M:%S", tz="UTC")

cohort_13APR <- read.csv('studyCohort_13Apr.csv',header=T,stringsAsFactors=F)
mtch <- match(combined$stay_id,cohort_13APR$stay_id)
combined <- combined[which(!is.na(mtch)),]
table(combined$expose)


write.csv(combined,'studyCohort_final_13APR.csv',row.names=F)

