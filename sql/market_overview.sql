/*
  MARKET OVERVIEW — Grafana PostgreSQL queries
  Source: public.apartments_analysis

  Grafana variables expected:
    $district   — район
    $rooms      — группа комнат (rooms_group)
    $renovation — тип ремонта
    $floor      — категория этажа (floor_category)
    $metro      — станция метро

  For query variables, use Multi-value + Include All and Custom all value: .*
  Use the same PostgreSQL datasource as the dashboard.
*/

-- =========================================================
-- VARIABLES
-- =========================================================

-- Variable: district
SELECT DISTINCT district AS __text, district AS __value
FROM public.apartments_analysis
WHERE district IS NOT NULL AND BTRIM(district) <> ''
ORDER BY 1;

-- Variable: rooms
SELECT DISTINCT rooms_group AS __text, rooms_group AS __value
FROM public.apartments_analysis
WHERE rooms_group IS NOT NULL AND BTRIM(rooms_group) <> ''
ORDER BY 1;

-- Variable: renovation
SELECT DISTINCT renovation AS __text, renovation AS __value
FROM public.apartments_analysis
WHERE renovation IS NOT NULL AND BTRIM(renovation) <> ''
ORDER BY 1;

-- Variable: floor
SELECT DISTINCT floor_category AS __text, floor_category AS __value
FROM public.apartments_analysis
WHERE floor_category IS NOT NULL AND BTRIM(floor_category) <> ''
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


-- =========================================================
-- COMMON FILTER
-- Paste this WHERE condition into each panel query.
-- =========================================================
-- COALESCE(district, '') ~ '${district:regex}'
-- AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
-- AND COALESCE(renovation, '') ~ '${renovation:regex}'
-- AND COALESCE(floor_category, '') ~ '${floor:regex}'
-- AND (
--     COALESCE(metro_1, '') ~ '${metro:regex}'
--     OR COALESCE(metro_2, '') ~ '${metro:regex}'
--     OR COALESCE(metro_3, '') ~ '${metro:regex}'
-- )


-- =========================================================
-- KPI 1 — Total Listings
-- Visualization: Stat
-- =========================================================
SELECT COUNT(*) AS total_listings
FROM public.apartments_analysis
WHERE COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  );


-- =========================================================
-- KPI 2 — Median Price
-- Visualization: Stat; unit: RUB
-- =========================================================
SELECT ROUND(
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_rub)
) AS median_price_rub
FROM public.apartments_analysis
WHERE price_rub > 0
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  );


-- =========================================================
-- KPI 3 — Average Price
-- Visualization: Stat; unit: RUB
-- =========================================================
SELECT ROUND(AVG(price_rub)) AS average_price_rub
FROM public.apartments_analysis
WHERE price_rub > 0
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  );


-- =========================================================
-- KPI 4 — Median Price per Square Meter
-- Visualization: Stat; unit: RUB/m²
-- =========================================================
SELECT ROUND(
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_per_sqm)
) AS median_price_per_sqm
FROM public.apartments_analysis
WHERE price_per_sqm > 0
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  );


-- =========================================================
-- KPI 5 — Median Area
-- Visualization: Stat; unit: m²
-- =========================================================
SELECT ROUND(
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_area_sqm)::numeric,
    1
) AS median_area_sqm
FROM public.apartments_analysis
WHERE total_area_sqm > 0
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  );


-- =========================================================
-- CHART 1 — Listings by District, Top 10
-- Visualization: Bar chart
-- =========================================================
SELECT district, COUNT(*) AS listings
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY listings DESC
LIMIT 10;


-- =========================================================
-- CHART 2 — Price Distribution by Price Segment
-- Visualization: Bar chart
-- =========================================================
SELECT price_segment, COUNT(*) AS listings
FROM public.apartments_analysis
WHERE price_segment IS NOT NULL
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY price_segment
ORDER BY MIN(price_rub);


-- =========================================================
-- CHART 3 — Median Price per m² by District, Top 10
-- Visualization: Bar chart
-- =========================================================
SELECT
    district,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_per_sqm)) AS median_price_per_sqm
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND price_per_sqm > 0
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY median_price_per_sqm DESC
LIMIT 10;


-- =========================================================
-- TABLE — District Summary
-- Visualization: Table
-- =========================================================
SELECT
    district,
    COUNT(*) AS listings,
    ROUND(AVG(price_rub)) AS average_price_rub,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_rub)) AS median_price_rub,
    ROUND(PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY price_per_sqm)) AS median_price_per_sqm
FROM public.apartments_analysis
WHERE district IS NOT NULL
  AND price_rub > 0
  AND price_per_sqm > 0
  AND COALESCE(district, '') ~ '${district:regex}'
  AND COALESCE(rooms_group, '') ~ '${rooms:regex}'
  AND COALESCE(renovation, '') ~ '${renovation:regex}'
  AND COALESCE(floor_category, '') ~ '${floor:regex}'
  AND (
      COALESCE(metro_1, '') ~ '${metro:regex}'
      OR COALESCE(metro_2, '') ~ '${metro:regex}'
      OR COALESCE(metro_3, '') ~ '${metro:regex}'
  )
GROUP BY district
ORDER BY listings DESC;
