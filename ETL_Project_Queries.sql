/*1. Find the state with the greatest number of homicides per population*/
SELECT SUM(homicide) as state_homicide_total, state_abbr, SUM(population)/10 as avg_pop, round(cast(SUM(homicide) as decimal)/(SUM(population)/10), 6) as homicide_per_pop  
FROM summary
GROUP BY state_abbr
ORDER BY homicide_per_pop DESC

/*2. What year had the most arrests for all crimes across the United States?*/
SELECT year, SUM(violent_crime)+SUM(homicide)+SUM(robbery)+SUM(aggravated_assault)+SUM(property_crime)+SUM(burglary)+SUM(larceny)+SUM(motor_vehicle_theft)+SUM(arson) as total_crime_arrests
FROM summary
GROUP BY year
ORDER BY total_crime_arrests desc

/*3. What state has the best ratio of police employment to violent crimes?*/
SELECT e.state_abbr, round(cast(avg(e.pe_ct_per_1000) as decimal), 2) as avg_pe_ct_per_1000, round(avg(cast(s.violent_crime as decimal)/(s.population/1000)), 2) as avg_violent_crime_ct_per_1000, round(cast((avg(cast(s.violent_crime as decimal)/(s.population/1000)))/(avg(e.pe_ct_per_1000)) as decimal), 2) as ratio 
FROM employment_new as e
LEFT JOIN summary as s
	ON s.year = e.data_year
    AND s.state_abbr = e.state_abbr
GROUP BY e.state_abbr 
ORDER BY ratio 

/*4. How do arrested violent crime counts from the crime_new table compare to the cleared and actual crime totals from the summarized_crime_new table?*/
SELECT c.state, SUM(c.value) as arrested_crime_total, SUM(sc.cleared) as cleared_crime_total, SUM(sc.actual) as actual_crime_total
FROM crime_new as c
LEFT JOIN summarized_crime_new as sc
	ON c.data_year = sc.data_year
	AND c.state = sc.state_abbr
WHERE c.key = 'Aggravated Assault' OR c.key='Murder and Nonnegligent Manslaughter' OR c.key='Rape' OR c.key='Simple Assault' AND sc.offense = 'violent crime'
GROUP BY c.state


