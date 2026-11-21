/*
  LOCATION & INFRASTRUCTURE — Grafana PostgreSQL queries
  Source: public.apartments_analysis

  Grafana variables expected:
    $city, $district, $metro, $parking

  Query variables: Multi-value + Include All; Custom all value: .*
*/

-- =========================================================
-- VARIABLES
-- =========================================================

-- Variable: city
SELECT DISTINCT city AS __text, city AS __value
FROM public.apartments_analysis
WHERE city IS NOT NULL AND BTRIM(city) <> ''
ORDER BY 1;

-- Variable: district
SELECT DISTINCT district AS __text, district AS __value
FROM public.apartments_analysis
WHERE district IS NOT NULL AND BTRIM(district) <> ''
ORDER BY 1;

-- Variable: metro
SELECT metro AS __text, metro AS __value
FROM (
    SELECT metro_1 AS metro FROM public.apartments_analysis
    UNION
    SELECT metro_2 FROM public.apartments_analysis
    UNION
    SELECT metro_3 FROM public.apartments_analysis
) AS stations
WHERE metro IS NOT NULL AND BTRIM(metro) <> ''
ORDER BY 1;

-- Variable: parking
SELECT DISTINCT parking AS __text, parking AS __value
FROM public.apartments_analysis
WHERE parking IS NOT NULL AND BTRIM(parking) <> ''
ORDER BY 1;


-- =========================================================
-- COMMON FILTER
-- =========================================================
-- COALESCE(city, '') ~ '${city:regex}'
-- AND COALESCE(district, '') ~ '${district:regex}'
-- AND COALESCE(parking, '') ~ '${parking:regex}'
-- AND (
--     COALESCE(metro_1, '') ~ '${metro:regex}'
--     OR COALESCE(metro_2, '') ~ '${metro:regex}'
--     OR COALESCE(metro_3, '') ~ '${metro:regex}'
-- )


-- =========================================================
-- PANEL 1 — Listings by District
-- Visualization: Bar chart
-- =========================================================
SELECT district, COUNT(*) AS listings
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND COALESCE(city, '') ~ '${city:regex}'
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(parking, '') ~ '${parking:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY listings DESC;


-- =========================================================
-- PANEL 2 — Median Price by District
-- Visualization: Bar chart; unit: RUB
-- =========================================================
SELECT
    district,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_rub)) AS median_price_rub
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND price_rub > 0
  AND COALESCE(city, '') ~ '${city:regex}'
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(parking, '') ~ '${parking:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY median_price_rub DESC;


-- =========================================================
-- PANEL 3 — Median Price per m² by District
-- Visualization: Bar chart; unit: RUB/m²
-- =========================================================
SELECT
    district,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_per_sqm)) AS median_price_per_sqm
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND price_per_sqm > 0
  AND COALESCE(city, '') ~ '${city:regex}'
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(parking, '') ~ '${parking:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY median_price_per_sqm DESC;


-- =========================================================
-- PANEL 4 — Average Time to Selected Metro
-- Uses the closest selected station per listing, not all station entries.
-- Visualization: Stat; unit: minutes
-- =========================================================
WITH filtered AS (
    SELECT *
    FROM public.apartments_analysis
    WHERE COALESCE(city, '') ~ '${city:regex}'
      AND COALESCE(district, '') ~ '${district:regex}'
      AND COALESCE(parking, '') ~ '${parking:regex}'
      AND (
          COALESCE(metro_1, '') ~ '${metro:regex}'
          OR COALESCE(metro_2, '') ~ '${metro:regex}'
          OR COALESCE(metro_3, '') ~ '${metro:regex}'
      )
),
station_times AS (
    SELECT f.listing_id, v.station, v.time_min
    FROM filtered f
    CROSS JOIN LATERAL (VALUES
        (f.metro_1, f.metro_time_min),
        (f.metro_2, f.metro_2_time_min),
        (f.metro_3, f.metro_3_time_min)
    ) AS v(station, time_min)
),
nearest AS (
    SELECT listing_id, MIN(time_min) AS access_time
    FROM station_times
    WHERE station IS NOT NULL
      AND station ~ '${metro:regex}'
      AND time_min IS NOT NULL
    GROUP BY listing_id
)
SELECT ROUND(AVG(access_time), 1) AS average_metro_time_min
FROM nearest;


-- =========================================================
-- PANEL 5 — Listings by Metro Access Time
-- Visualization: Bar chart
-- =========================================================
WITH filtered AS (
    SELECT *
    FROM public.apartments_analysis
    WHERE COALESCE(city, '') ~ '${city:regex}'
      AND COALESCE(district, '') ~ '${district:regex}'
      AND COALESCE(parking, '') ~ '${parking:regex}'
      AND (
          COALESCE(metro_1, '') ~ '${metro:regex}'
          OR COALESCE(metro_2, '') ~ '${metro:regex}'
          OR COALESCE(metro_3, '') ~ '${metro:regex}'
      )
),
station_times AS (
    SELECT f.listing_id, v.station, v.time_min
    FROM filtered f
    CROSS JOIN LATERAL (VALUES
        (f.metro_1, f.metro_time_min),
        (f.metro_2, f.metro_2_time_min),
        (f.metro_3, f.metro_3_time_min)
    ) AS v(station, time_min)
),
nearest AS (
    SELECT listing_id, MIN(time_min) AS access_time
    FROM station_times
    WHERE station IS NOT NULL
      AND station ~ '${metro:regex}'
      AND time_min IS NOT NULL
    GROUP BY listing_id
)
SELECT
    CASE
        WHEN access_time <= 5 THEN '0–5 min'
        WHEN access_time <= 10 THEN '6–10 min'
        WHEN access_time <= 15 THEN '11–15 min'
        WHEN access_time <= 20 THEN '16–20 min'
        ELSE '20+ min'
    END AS metro_access,
    COUNT(*) AS listings
FROM nearest
GROUP BY 1
ORDER BY MIN(access_time);


-- =========================================================
-- PANEL 6 — Most Popular Metro Stations
-- Visualization: Bar chart; top 15
-- =========================================================
WITH filtered AS (
    SELECT *
    FROM public.apartments_analysis
    WHERE COALESCE(city, '') ~ '${city:regex}'
      AND COALESCE(district, '') ~ '${district:regex}'
      AND COALESCE(parking, '') ~ '${parking:regex}'
),
stations AS (
    SELECT f.listing_id, v.station
    FROM filtered f
    CROSS JOIN LATERAL (VALUES
        (f.metro_1), (f.metro_2), (f.metro_3)
    ) AS v(station)
)
SELECT station, COUNT(DISTINCT listing_id) AS listings
FROM stations
WHERE station IS NOT NULL
  AND BTRIM(station) <> ''
  AND station ~ '${metro:regex}'
GROUP BY station
ORDER BY listings DESC
LIMIT 15;


-- =========================================================
-- PANEL 7 — Passenger Lift Count
-- Visualization: Pie chart
-- passenger_lift is numeric in the supplied schema.
-- =========================================================
SELECT
    CASE
        WHEN passenger_lift = 0 THEN '0'
        WHEN passenger_lift = 1 THEN '1'
        WHEN passenger_lift = 2 THEN '2'
        ELSE '3+'
    END AS lift_count,
    COUNT(*) AS listings
FROM public.apartments_analysis
WHERE passenger_lift IS NOT NULL
  AND COALESCE(city, '') ~ '${city:regex}'
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(parking, '') ~ '${parking:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY 1
ORDER BY MIN(passenger_lift);


-- =========================================================
-- PANEL 8 — Parking Types
-- Visualization: Pie chart; top 10
-- =========================================================
SELECT parking, COUNT(*) AS listings
FROM public.apartments_analysis
WHERE parking IS NOT NULL
  AND BTRIM(parking) <> ''
  AND COALESCE(city, '') ~ '${city:regex}'
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(parking, '') ~ '${parking:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY parking
ORDER BY listings DESC
LIMIT 10;


-- =========================================================
-- PANEL 9 — Infrastructure Summary by District
-- Visualization: Table
-- =========================================================
SELECT
    district,
    COUNT(*) AS listings,
    ROUND(AVG(LEAST(
        metro_time_min,
        metro_2_time_min,
        metro_3_time_min
    )), 1) AS avg_nearest_metro_min,
    ROUND(AVG(passenger_lift), 2) AS avg_passenger_lifts,
    COUNT(*) FILTER (
        WHERE parking IS NOT NULL AND BTRIM(parking) <> ''
    ) AS listings_with_parking,
    COUNT(*) FILTER (
        WHERE yard IS NOT NULL AND BTRIM(yard) <> ''
    ) AS listings_with_yard_info
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND COALESCE(city, '') ~ '${city:regex}'
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(parking, '') ~ '${parking:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY listings DESC;
