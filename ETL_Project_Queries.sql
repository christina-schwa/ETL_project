/*1. Find the state with the greatest number of homicides per population.*/
SELECT SUM(homicide) AS state_homicide_total, state_abbr, SUM(population)/10 AS avg_pop, round(cast(SUM(homicide) AS decimal)/(SUM(population)/100000), 6) AS homicide_per_pop  
FROM summary
GROUP BY state_abbr
ORDER BY homicide_per_pop DESC;
/*Louisiana has the highest number of homicides relative to its population: 11.16 homicides per 100,000 residents.*/

/*2. What year had the most arrests for all crimes across the United States?*/
SELECT year, SUM(violent_crime)+SUM(homicide)+SUM(robbery)+SUM(aggravated_assault)+SUM(property_crime)+SUM(burglary)+SUM(larceny)+SUM(motor_vehicle_theft)+SUM(arson) AS total_crime_arrests
FROM summary
GROUP BY year
ORDER BY total_crime_arrests DESC;
/*Within the range of 2010 to 2019, the year with the highest homicide rate was 2010. For all 50 states combined, there were 20,624,562 murders reported in 2010.*/

/*3. What state has the lowest ratio of violent crimes to police employment?*/
SELECT e.state_abbr, round(cast(avg(e.pe_ct_per_1000) AS decimal), 2) AS avg_pe_ct_per_1000, round(avg(cast(s.violent_crime AS decimal)/(s.population/1000)), 2) AS avg_violent_crime_ct_per_1000, round(cast((avg(cast(s.violent_crime AS decimal)/(s.population/1000)))/(avg(e.pe_ct_per_1000)) AS decimal), 2) AS ratio 
FROM employment_new AS e
LEFT JOIN summary AS s
	ON s.year = e.data_year
    AND s.state_abbr = e.state_abbr
GROUP BY e.state_abbr 
ORDER BY ratio;
/*Vermont has the lowest violent crime rate relative to the number of police employed. There are, on average, 0.50 violent crimes per police employee.*/

/*4. How do arrested violent crime counts from the crime_new table compare to the cleared and actual violent crime totals from the summarized_crime_new table?*/
SELECT c.state, SUM(c.value) AS arrested_violent_crime_total, SUM(sc.cleared) AS cleared_violent_crime_total, SUM(sc.actual) AS actual_violent_crime_total
FROM crime_new AS c
LEFT JOIN summarized_crime_new AS sc
	ON c.data_year = sc.data_year
	AND c.state = sc.state_abbr
WHERE c.key = 'Aggravated Assault' OR c.key='Murder and Nonnegligent Manslaughter' OR c.key='Rape' OR c.key='Simple Assault' AND sc.offense = 'violent-crime'
GROUP BY c.state;
/*It is apparent from this table that the "violent-crime" category in the offense summary data does not contain all instances of the more specific violent crimes listed in the arrest data. In most cases, the "actual violent crime" total is significantly lower than the sum of all arrests for specific violent crimes (both grouped by state).*/

/*5. How do arrested property crime counts from the crime_new table compare to the cleared and actual property crime totals from the summarized_crime_new table?*/
SELECT c.state, SUM(c.value) AS arrested_property_crime_total, SUM(sc.cleared) AS cleared_property_crime_total, SUM(sc.actual) AS actual_property_crime_total
FROM crime_new AS c
LEFT JOIN summarized_crime_new AS sc
	ON c.data_year = sc.data_year
	AND c.state = sc.state_abbr
WHERE c.key = 'Burglary' OR c.key='Embezzlement' OR c.key='Forgery and Counterfeiting' OR c.key='Fraud' OR c.key='Larceny - Theft' OR c.key='Motor Vehicle Theft' OR c.key='Robbery' OR c.key='Stolen Property: Buying, Receiving, Possessing' OR c.key='Vandalism' AND sc.offense = 'property-crime'
GROUP BY c.state;
/*There appears to be even less of a correlation between the sum of all arrests for specific property crimes and the total offenses marked as "violent crime." In a few states (e.g., Alaska), these numbers are close, but in many others (e.g., North Carolina) they are extremely different.

/*6. How do the reports of "rape_legacy" versus "rape_revised" compare from year to year? How long did it take for agencie to shift from the old definition to the new definition?*/
SELECT year, sum(rape_legacy) AS r_old_definition, sum(rape_revised) AS r_new_definition
FROM summary
GROUP BY year
ORDER BY year;
/*The FBI altered their definition of rape in 2011, but the data shows that the shift to the new definition was gradual. Agencies reported all cases of rape from 2010 tto 2012 according to the old definition through 2012. In the following 4 years (2013-2016), all cases were reported as both rape_legacy and rape_revised (i.e., the old and new definitions), but by 2017, all agencies had shifted to using the new definition exclusively.*/

/*7. In which states did the highest number of agencies report employment data, relative to population (i.e., agencies per 100,000 residents)?*/
SELECT state_name, 
	CAST(AVG(agency_count_pe_submitting) AS integer) AS avg_agency_count_pe_submitting, 
	CAST(AVG(population) AS integer) AS avg_population,
	ROUND(CAST((AVG(agency_count_pe_submitting * 10000) / (AVG(population))) AS decimal), 4) AS agency_to_pop_reporting_ratio
FROM employment_new
GROUP BY state_name
ORDER BY agency_to_pop_reporting_ratio DESC;
/* Vermont had the highest number of agencies report employment data, relative to population: 14.53 agencies per 100,000 residents.*/

/*8. Which state and year had the highest percentage of female employees?*/
SELECT e.state_abbr,
	e.data_year,
	SUM(e.female_total_ct) AS sum_female_total_ct,
	SUM(e.total_pe_ct) AS sum_total_pe_ct,
	(SELECT SUM(e.female_total_ct)*100 / SUM(e.total_pe_ct) AS percent_female_pe)
FROM employment_new AS e
GROUP BY e.state_abbr, e.data_year
ORDER BY percent_female_pe DESC;
/*The highest percentage of female employees (54%) were employed in Oregon in 2011.*/

/*9. How do Missouri and its neighboring states compare with regard to crime rate and the number of agencies per capita that reported employment statistics? Is there any correlation between these two features, and if so, how can we deetermine that?*/
SELECT e.state_name,
	e.state_abbr,
	CAST(AVG(e.agency_count_pe_submitting) AS integer) AS avg_agency_count_pe_submitting, 
	CAST(AVG(e.population) AS integer) AS avg_population,
	ROUND(CAST((AVG(e.agency_count_pe_submitting * 1000) / (AVG(e.population))) AS decimal), 3) AS agency_to_1000_pop_report_ratio,
	ROUND(CAST((SUM(c.value * 1000) / (SUM(e.population))) AS decimal), 3) AS crime_to_1000_pop_ratio
INTO missouri_and_neighbors
FROM employment_new AS e
JOIN crime_new AS c
ON e.data_year = c.data_year
WHERE e.state_abbr IN ('MO', 'KS', 'IL', 'IA', 'KY', 'TN', 'AR', 'OK', 'NE')
GROUP BY e.state_name, e.state_abbr
ORDER BY agency_to_1000_pop_report_ratio DESC;

SELECT *, 
((SELECT ROUND(CAST(agency_to_1000_pop_report_ratio / crime_to_1000_pop_ratio AS decimal), 3) WHERE crime_to_1000_pop_ratio > 0)) AS agency_to_crime_report_ratio
FROM missouri_and_neighbors;
/*We created a new table that joins arrest data and employment data for only Missouri and the states that border it. This new table shows how many agencies per 1000 residents reported employment data and how many arrests were reported per 1000 residents in nine states. An additional query was run to attempt to calculate a ratio of agencies reporting employment statistics to crime rate (both per 1000 residents). There did not appear to be a strong correlation between these figures, but we would need to run statistical analyses to be sure. Even though these results weren't very enlightening, the queries demonstrate how data can be filtered and new tables can be created within the database.*/