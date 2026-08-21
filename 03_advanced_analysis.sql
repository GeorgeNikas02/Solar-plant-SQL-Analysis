-- Q1: Total Downtime per Plant

SELECT 
	sp.plant_name,
    SUM(m.downtime_hours) AS total_downtime_hours
FROM solar_plants sp
JOIN maintenance m
	ON sp.plant_id = m.plant_id
GROUP BY plant_name;

-- Q2: Production Loss During Downtime

WITH total_downtime AS (
	SELECT
		sp.plant_name,
        sp.capacity_mw,
		SUM(m.downtime_hours) AS total_downtime_hours
	FROM solar_plants sp
	JOIN maintenance m
		ON sp.plant_id = m.plant_id
	GROUP BY sp.plant_name, sp.capacity_mw
)
SELECT
	plant_name,
    capacity_mw,
    total_downtime_hours,
    (capacity_mw * total_downtime_hours) AS estimated_lost_energy_mwh
FROM total_downtime;

-- Q3: Plants with the Highest Downtime

WITH total_downtime_1 AS (
	SELECT
		sp.plant_name,
		SUM(m.downtime_hours) AS total_downtime_hours
	FROM solar_plants sp
	JOIN maintenance m
		ON sp.plant_id = m.plant_id
	GROUP BY sp.plant_name
)
SELECT
	plant_name,
    total_downtime_hours
FROM total_downtime_1
ORDER BY total_downtime_hours DESC
LIMIT 3;

-- Q4: Production Before and After Maintenance

WITH en_before AS (
    SELECT
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date,
        MAX(eg.generation_date) AS generation_date_before
    FROM maintenance m
    JOIN energy_generation eg
        ON m.plant_id = eg.plant_id
    WHERE eg.generation_date < m.maintenance_date
    GROUP BY
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date
),
en_after AS (
    SELECT
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date,
        MIN(eg.generation_date) AS generation_date_after
    FROM maintenance m
    JOIN energy_generation eg
        ON m.plant_id = eg.plant_id
    WHERE eg.generation_date > m.maintenance_date
    GROUP BY
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date
)
SELECT
    sp.plant_name,
    af.maintenance_date,
    eg_bef.energy_mwh AS production_before,
    eg_af.energy_mwh AS production_after,
    eg_af.energy_mwh - eg_bef.energy_mwh AS production_change
FROM en_after af
JOIN en_before be
    ON af.maintenance_id = be.maintenance_id
JOIN energy_generation eg_bef
    ON be.plant_id = eg_bef.plant_id
    AND be.generation_date_before = eg_bef.generation_date
JOIN energy_generation eg_af
    ON af.plant_id = eg_af.plant_id
    AND af.generation_date_after = eg_af.generation_date
JOIN solar_plants sp
    ON af.plant_id = sp.plant_id;
    
-- Q5: Downtime vs Energy Production

WITH downtime AS(
SELECT 
	sp.plant_name,
    SUM(m.downtime_hours) AS total_downtime_hours
FROM solar_plants sp
JOIN maintenance m
	ON sp.plant_id = m.plant_id
GROUP BY plant_name
),
energy AS(
SELECT
    sp.plant_name,
    SUM(eg.energy_mwh) AS total_energy_mwh
FROM solar_plants AS sp
JOIN energy_generation AS eg
    ON sp.plant_id = eg.plant_id
GROUP BY sp.plant_name
)
SELECT
	en.plant_name,
    d.total_downtime_hours,
    en.total_energy_mwh
FROM energy en
JOIN downtime d
	ON en.plant_name = d.plant_name
;

-- Q6: Plants with Above-Average Downtime and Below-Average Production per MW

WITH energy_values AS (
    SELECT
        sp.plant_id,
        sp.plant_name,
        sp.capacity_mw,
        SUM(eg.energy_mwh) AS total_energy_mwh,
        SUM(eg.energy_mwh) / sp.capacity_mw AS energy_per_mw
    FROM solar_plants sp
    JOIN energy_generation eg
        ON sp.plant_id = eg.plant_id
    GROUP BY
        sp.plant_id,
        sp.plant_name,
        sp.capacity_mw
),
 downtime_values AS (
    SELECT
        sp.plant_id,
        sp.plant_name,
        SUM(downtime_hours) AS total_downtime_hours
    FROM solar_plants sp
    JOIN maintenance m
        ON sp.plant_id = m.plant_id
    GROUP BY
        sp.plant_id,
        sp.plant_name
),
average_values AS (
	SELECT
		AVG(energy_per_mw) AS average_energy_per_mw,
        AVG(total_downtime_hours) AS average_downtime_hours
	FROM energy_values ev
    JOIN downtime_values dv
		ON ev.plant_id = dv.plant_id
)
SELECT
	ev.plant_name,
    ev.energy_per_mw,
    dv.total_downtime_hours
FROM energy_values ev
JOIN downtime_values dv
    ON ev.plant_id = dv.plant_id
CROSS JOIN average_values av
WHERE ev.energy_per_mw < av.average_energy_per_mw AND dv.total_downtime_hours > av.average_downtime_hours;

-- Q7: Monthly Production Ranking (top3 per month)

WITH monthly_production AS (
    SELECT
        EXTRACT(MONTH FROM eg.generation_date) AS month,
        sp.plant_name,
        eg.energy_mwh
    FROM energy_generation eg
    JOIN solar_plants sp
        ON sp.plant_id = eg.plant_id
),
ranking AS (
    SELECT
        month,
        plant_name,
        energy_mwh,
        DENSE_RANK() OVER (PARTITION BY month ORDER BY energy_mwh DESC) AS production_rank
    FROM monthly_production
)
SELECT
    month,
    plant_name,
    energy_mwh,
    production_rank
FROM ranking
WHERE production_rank <= 3
ORDER BY month, production_rank;

-- Q8: Monthly Production Change & Growth Rate

WITH monthly_production AS (
    SELECT
        EXTRACT(MONTH FROM eg.generation_date) AS month,
        sp.plant_name,
        eg.energy_mwh
    FROM energy_generation eg
    JOIN solar_plants sp
        ON sp.plant_id = eg.plant_id
),
previous AS (
    SELECT
        month,
        plant_name,
        energy_mwh,
        LAG(energy_mwh) OVER (
            PARTITION BY plant_name
            ORDER BY month
        ) AS previous_month_energy
    FROM monthly_production
)
SELECT
    month,
    plant_name,
    energy_mwh,
    previous_month_energy,
    energy_mwh - previous_month_energy AS production_change,
    ROUND((energy_mwh - previous_month_energy) / previous_month_energy * 100, 2) AS growth_rate_percent
FROM previous;

-- Q9: Rolling 3-Month Average Production

SELECT
	EXTRACT(MONTH FROM eg.generation_date) AS month,
    sp.plant_name,
    eg.energy_mwh,
	ROUND(AVG(eg.energy_mwh) OVER (PARTITION BY sp.plant_name 
		ORDER BY eg.generation_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3_month_avg
FROM energy_generation eg
JOIN solar_plants sp
	ON sp.plant_id = eg.plant_id;

-- Q10: Production Increase After Maintenance

WITH en_before AS (
    SELECT
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date,
        MAX(eg.generation_date) AS generation_date_before
    FROM maintenance m
    JOIN energy_generation eg
        ON m.plant_id = eg.plant_id
    WHERE eg.generation_date < m.maintenance_date
    GROUP BY
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date
),
en_after AS (
    SELECT
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date,
        MIN(eg.generation_date) AS generation_date_after
    FROM maintenance m
    JOIN energy_generation eg
        ON m.plant_id = eg.plant_id
    WHERE eg.generation_date > m.maintenance_date
    GROUP BY
        m.maintenance_id,
        eg.plant_id,
        m.maintenance_date
)
SELECT
    sp.plant_name,
    af.maintenance_date,
    eg_bef.energy_mwh AS production_before,
    eg_af.energy_mwh AS production_after,
    eg_af.energy_mwh - eg_bef.energy_mwh AS production_change,
    ROUND((eg_af.energy_mwh - eg_bef.energy_mwh) / eg_bef.energy_mwh * 100, 2) AS change_pct
FROM en_after af
JOIN en_before be
    ON af.maintenance_id = be.maintenance_id
JOIN energy_generation eg_bef
    ON be.plant_id = eg_bef.plant_id
    AND be.generation_date_before = eg_bef.generation_date
JOIN energy_generation eg_af
    ON af.plant_id = eg_af.plant_id
    AND af.generation_date_after = eg_af.generation_date
JOIN solar_plants sp
    ON af.plant_id = sp.plant_id
WHERE eg_af.energy_mwh - eg_bef.energy_mwh > 0;

-- Q11: Plant Performance Summary

WITH energy_values AS (
    SELECT
        sp.plant_id,
        sp.plant_name,
        sp.capacity_mw,
        SUM(eg.energy_mwh) AS total_energy_mwh,
        SUM(eg.energy_mwh) / sp.capacity_mw AS energy_per_mw
    FROM solar_plants sp
    JOIN energy_generation eg
        ON sp.plant_id = eg.plant_id
    GROUP BY
        sp.plant_id,
        sp.plant_name,
        sp.capacity_mw
),
 downtime_values AS (
    SELECT
        sp.plant_id,
        sp.plant_name,
        SUM(downtime_hours) AS total_downtime_hours
    FROM solar_plants sp
    JOIN maintenance m
        ON sp.plant_id = m.plant_id
    GROUP BY
        sp.plant_id,
        sp.plant_name
),
average_values AS (
	SELECT
		AVG(energy_per_mw) AS average_energy_per_mw,
        AVG(total_downtime_hours) AS average_downtime_hours
	FROM energy_values ev
    JOIN downtime_values dv
		ON ev.plant_id = dv.plant_id
)
SELECT 
	ev.plant_name,
    ev.capacity_mw,
    ev.total_energy_mwh,
    dv.total_downtime_hours,
    ev.energy_per_mw,
    DENSE_RANK()  OVER (ORDER BY ev.total_energy_mwh DESC) AS production_rank,
    CASE
		WHEN ev.energy_per_mw >= av.average_energy_per_mw
			AND dv.total_downtime_hours <= av.average_downtime_hours
				THEN 'High Performer'
		WHEN ev.energy_per_mw < av.average_energy_per_mw
			AND dv.total_downtime_hours > av.average_downtime_hours
				THEN 'Low Performer'
		ELSE 'Average Performer'
END AS performance_category
FROM energy_values ev
JOIN downtime_values dv
    ON ev.plant_id = dv.plant_id
CROSS JOIN average_values av;