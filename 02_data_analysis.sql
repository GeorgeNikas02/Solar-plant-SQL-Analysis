-- Q1 - Total Energy Production Per Solar Plant

SELECT
    sp.plant_name,
    SUM(eg.energy_mwh) AS total_energy_mwh
FROM solar_plants AS sp
JOIN energy_generation AS eg
    ON sp.plant_id = eg.plant_id
GROUP BY sp.plant_name;

-- Q2 - Highest Producing Solar Plant

SELECT
    sp.plant_name,
    SUM(eg.energy_mwh) AS total_energy_mwh
FROM solar_plants AS sp
JOIN energy_generation AS eg
    ON sp.plant_id = eg.plant_id
GROUP BY sp.plant_name
ORDER BY total_energy_mwh DESC
LIMIT 1;

-- Q3: Energy Production Per MW

SELECT
    sp.plant_name,
    sp.capacity_mw,
    SUM(eg.energy_mwh) AS total_energy_mwh,
    SUM(eg.energy_mwh) / sp.capacity_mw AS energy_per_mw
FROM solar_plants sp
JOIN energy_generation eg
    ON sp.plant_id = eg.plant_id
GROUP BY
    sp.plant_name,
    sp.capacity_mw;

-- Q4: Highest Energy Production Per MW

SELECT
    sp.plant_name,
    sp.capacity_mw,
    SUM(eg.energy_mwh) AS total_energy_mwh,
    SUM(eg.energy_mwh) / sp.capacity_mw AS energy_per_mw
FROM solar_plants sp
JOIN energy_generation eg
    ON sp.plant_id = eg.plant_id
GROUP BY
    sp.plant_name,
    sp.capacity_mw
ORDER BY energy_per_mw DESC
LIMIT 1;

-- Q5: Monthly Energy Production

SELECT 
	EXTRACT(MONTH FROM eg.generation_date) AS month,
    SUM(eg.energy_mwh) AS total_energy_mwh
FROM energy_generation eg
GROUP BY
    month
ORDER BY 
	month;

-- Q6: Highest Monthly Energy Production

SELECT 
	EXTRACT(MONTH FROM eg.generation_date) AS month,
    SUM(eg.energy_mwh) AS total_energy_mwh
FROM energy_generation eg
GROUP BY
    month
ORDER BY 
	total_energy_mwh DESC
LIMIT 1;

-- Q7: Monthly Production Change

WITH total_energy_per_month AS (
    SELECT
        EXTRACT(MONTH FROM generation_date) AS month,
        SUM(energy_mwh) AS total_energy_mwh
    FROM energy_generation
    GROUP BY month
),
monthly_comparison AS (
    SELECT
        month,
        total_energy_mwh,
        LAG(total_energy_mwh) OVER (ORDER BY month) AS previous_month
    FROM total_energy_per_month
)
SELECT
    month,
    total_energy_mwh,
    previous_month,
    total_energy_mwh - previous_month AS production_change
FROM monthly_comparison
ORDER BY month;

-- Q8: Plants Above Average Production

WITH total_energy_per_plant AS (
	SELECT
		sp.plant_name,
		SUM(eg.energy_mwh) AS total_energy_mwh
	FROM solar_plants AS sp
	JOIN energy_generation AS eg
		ON sp.plant_id = eg.plant_id
	GROUP BY sp.plant_name
),
average_production AS (
	SELECT AVG(total_energy_mwh) AS average_energy
    FROM total_energy_per_plant
)
SELECT
    tep.plant_name,
    tep.total_energy_mwh
FROM total_energy_per_plant tep
CROSS JOIN average_production ap
WHERE tep.total_energy_mwh > ap.average_energy;

-- Q9: Plant Production Ranking

WITH total_energy_per_plant AS (
	SELECT
		sp.plant_name,
		SUM(eg.energy_mwh) AS total_energy_mwh
	FROM solar_plants AS sp
	JOIN energy_generation AS eg
		ON sp.plant_id = eg.plant_id
	GROUP BY sp.plant_name
)
SELECT 
	plant_name,
    total_energy_mwh,
    DENSE_RANK() OVER (ORDER BY total_energy_mwh DESC) AS production_rank
FROM total_energy_per_plant;

-- Q10: Top 3 Solar Plants by Energy Production

WITH total_energy_per_plant AS (
	SELECT
		sp.plant_name,
		SUM(eg.energy_mwh) AS total_energy_mwh
	FROM solar_plants AS sp
	JOIN energy_generation AS eg
		ON sp.plant_id = eg.plant_id
	GROUP BY sp.plant_name
)
SELECT 
	plant_name,
    total_energy_mwh
FROM total_energy_per_plant
ORDER BY total_energy_mwh DESC
LIMIT 3;

-- Q11: High Capacity, Low Efficiency Plants (underperforming)

WITH energy_values AS(
SELECT
    sp.plant_name,
    sp.capacity_mw,
    SUM(eg.energy_mwh) AS total_energy_mwh,
    SUM(eg.energy_mwh) / sp.capacity_mw AS energy_per_mw
FROM solar_plants sp
JOIN energy_generation eg
    ON sp.plant_id = eg.plant_id
GROUP BY
    sp.plant_name,
    sp.capacity_mw
),
average_values AS(
SELECT 
	AVG(capacity_mw) AS average_capacity_mw,
    AVG(energy_per_mw) AS average_energy_per_mw
FROM energy_values
)
SELECT 
	ev.plant_name,
    ev.capacity_mw,
    ev.total_energy_mwh,
    ev.energy_per_mw
FROM energy_values ev
CROSS JOIN average_values av
WHERE ev.capacity_mw > av.average_capacity_mw AND ev.energy_per_mw < av.average_energy_per_mw;

-- Q12: Overall Plant Production Ranking

WITH energy_values AS(
SELECT
    sp.plant_name,
    sp.capacity_mw,
    SUM(eg.energy_mwh) AS total_energy_mwh,
    SUM(eg.energy_mwh) / sp.capacity_mw AS energy_per_mw
FROM solar_plants sp
JOIN energy_generation eg
    ON sp.plant_id = eg.plant_id
GROUP BY
    sp.plant_name,
    sp.capacity_mw
)
SELECT
	plant_name,
    capacity_mw,
    total_energy_mwh,
    energy_per_mw,
    DENSE_RANK() OVER (ORDER BY total_energy_mwh DESC) AS production_rank
FROM energy_values;