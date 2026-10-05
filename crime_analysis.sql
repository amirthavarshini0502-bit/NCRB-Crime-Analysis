state_name,
    district_name,
    total_cases,
    RANK() OVER (
        PARTITION BY state_name
        ORDER BY total_cases DESC
    ) AS district_rank
FROM district_totals
ORDER BY
    state_name,
    district_rank;

##Year-Over-Year Analysis
WITH yearly_totals AS (
    SELECT
        year,
        SUM(crime_count) AS total_cases
    FROM vw_crime_long
    GROUP BY year
),
comparison AS (
    SELECT
        year,
        total_cases,
        LAG(total_cases) OVER (
            ORDER BY year
        ) AS previous_year_cases
    FROM yearly_totals
)
SELECT
    year,
    total_cases,
    previous_year_cases,
    total_cases - previous_year_cases AS change_in_cases,
    ROUND(
        (
            (total_cases - previous_year_cases)
            * 100.0
            / NULLIF(previous_year_cases, 0)
        )::numeric,
        2
    ) AS yoy_growth_percentage
FROM comparison
ORDER BY year;

##Category-Wise Year-Over-Year
WITH yearly_category AS (
    SELECT
        year,
        crime_category,
        SUM(crime_count) AS total_cases
    FROM vw_crime_long
    GROUP BY
        year,
        crime_category
),
comparison AS (
    SELECT
        year,
        crime_category,
        total_cases,
        LAG(total_cases) OVER (
            PARTITION BY crime_category
            ORDER BY year
        ) AS previous_year_cases
    FROM yearly_category
)
SELECT
    year,
    crime_category,
    total_cases,
    previous_year_cases,
    total_cases - previous_year_cases AS change_in_cases,
    ROUND(
        (
            (total_cases - previous_year_cases)
            * 100.0
            / NULLIF(previous_year_cases, 0)
        )::numeric,
        2
    ) AS yoy_growth_percentage
FROM comparison
ORDER BY
    crime_category,
    year;

##Cybercrime Analysis
SELECT
    year,
    crime_category,
    SUM(crime_count) AS total_cases
FROM vw_crime_long
WHERE crime_category IN (
    'cybercrime',
    'cyber_fraud',
    'identity_privacy_crimes',
    'cyber_harassment_threats',
    'online_sexual_obscene_crimes'
)
GROUP BY
    year,
    crime_category
ORDER BY
    year,
    total_cases DESC;

##Creating Power Bi views
CREATE VIEW vw_pbi_yearly AS
SELECT
    year,
    crime_category,
    SUM(crime_count) AS total_cases
FROM vw_crime_long
GROUP BY
    year,
    crime_category;

##State
CREATE VIEW vw_pbi_state AS
SELECT
    state_name,
    crime_category,
    SUM(crime_count) AS total_cases
FROM vw_crime_long
GROUP BY
    state_name,
    crime_category;

##District
CREATE VIEW vw_pbi_district AS
SELECT
    state_name,
    district_name,
    crime_category,
    SUM(crime_count) AS total_cases
FROM vw_crime_long
GROUP BY
    state_name,
    district_name,
    crime_category;

##Year-Over-Year
CREATE VIEW vw_pbi_yoy AS
WITH yearly_category AS (
    SELECT
        year,
        crime_category,
        SUM(crime_count) AS total_cases
    FROM vw_crime_long
    GROUP BY
        year,
        crime_category
)
SELECT
    year,
    crime_category,
    total_cases,
    LAG(total_cases) OVER (
        PARTITION BY crime_category
        ORDER BY year
    ) AS previous_year_cases,
    ROUND(
        (
            (
                total_cases
                - LAG(total_cases) OVER (
                    PARTITION BY crime_category
                    ORDER BY year
                )
            )
            * 100.0
            /
            NULLIF(
                LAG(total_cases) OVER (
                    PARTITION BY crime_category
                    ORDER BY year
                ),
                0
            )
        )::numeric,
        2
    ) AS yoy_growth_percentage
FROM yearly_category;

##FINAL VERIFICATION##
SELECT * FROM vw_pbi_yearly LIMIT 10;
SELECT * FROM vw_pbi_state LIMIT 10;
SELECT * FROM vw_pbi_district LIMIT 10;
SELECT * FROM vw_pbi_yoy LIMIT 10;