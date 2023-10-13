create table usa_raw.covid_19_vaccination
(
	id bigint auto_increment
		primary key,

	vaers_id  int null,
	form 			varchar(11) null,
	age  			int null,
	sex  			varchar(10) null,
	location  varchar(50) null,

	vaccinated varchar(10) null,
	onset 		 varchar(10) null,
	submitted  varchar(10) null,
	entered    varchar(10) null,

	days_after_vaccination int null,
	days_after_onset       int null,
	days_after_submission  int null,

	tbl_vaccination_manufacturer varchar(75) null,
	tbl_lot 										 varchar(15) null,
	tbl_dose 										 varchar(15) null,
	tbl_site 										 varchar(15) null,
	tbl_route 									 varchar(15) null,

	administered_by varchar(255) null,
	purchased_by 		varchar(255) null,
	symptoms     		text null,

	smqs 								   longtext null,
	life_threatening  	   tinyint(1) null,
	birth_defect  			   tinyint(1) null,
	died  		        	   tinyint(1) null,
	permanent_disability   tinyint(1) null,
	recovered  					   tinyint(1) null,
	office_visit  			   tinyint(1) null,
	er_visit  					   tinyint(1) null,
	er_or_doctor_visit     tinyint(1) null,
	hospitalized   			 	 tinyint(1) null,
	hospitalized_days		 	 int null,
	extended_hospital_stay tinyint(1) null,
	previous_vaccinations  text null,
	other_medications 		 text null,
	current_illness   		 text null,
	preexisting_conditions text null,
	allergies 						 text null,
	diagnostic_lab_data    text null,
	cdc_split_type		     text null,
	writeup		     				 longtext null,

	report_link varchar(100) null,

	scrape_dev_name  varchar(7)   default 'Oleh B.' null,
	scrape_frequency varchar(10)  default 'Weekly' null,
	data_source_url  varchar(100) default 'https://www.medalerts.org/vaersdb/findfield.php?TABLE=ON&GROUP1=STA&EVENTS=ON&VAX=COVID19&DIED=Yes',
	created_at timestamp default CURRENT_TIMESTAMP not null,
	updated_at timestamp default CURRENT_TIMESTAMP not null on update CURRENT_TIMESTAMP,
	run_id int not null,
	touched_run_id int not null,
	deleted tinyint(1) default '0' null
)
collate=utf8mb4_unicode_520_ci
comment 'Creator:Oleh B.';