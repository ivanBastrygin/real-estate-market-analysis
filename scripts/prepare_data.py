import pandas as pd
import numpy as np
from pathlib import Path
import sys

input_file = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("avito_clean_final_full.xlsx")
output_file = Path("apartments_clean.csv")

df = pd.read_excel(input_file)
df = df.drop_duplicates(subset=["url"], keep="first")

mapping = {
    "Район":"district", "city":"city", "price":"price_rub",
    "Количество комнат":"rooms_raw", "rooms_count":"rooms_count",
    "Общая площадь":"total_area_sqm", "Площадь кухни":"kitchen_area_sqm",
    "Жилая площадь":"living_area_sqm", "floor_current":"floor",
    "floor_total":"building_floors", "Тип дома":"building_type",
    "Год постройки":"year_built", "Ремонт":"renovation",
    "Балкон или лоджия":"balcony", "Санузел":"bathroom",
    "Тип комнат":"room_layout", "Высота потолков":"ceiling_height_m",
    "Metro1":"metro_1", "Time1":"metro_time_min",
    "Metro2":"metro_2", "Time2":"metro_2_time_min",
    "Metro3":"metro_3", "Time3":"metro_3_time_min",
    "Пассажирский лифт":"passenger_lift", "Грузовой лифт":"freight_lift",
    "Парковка":"parking", "Двор":"yard", "Отделка":"finishing",
    "Название новостройки":"residential_complex", "Срок сдачи":"completion_date",
    "renovation_cost":"renovation_cost_rub"
}
out = df[list(mapping)].rename(columns=mapping).copy()
out.insert(0, "listing_id", range(1, len(out)+1))
for col in ["price_rub","rooms_count","total_area_sqm","kitchen_area_sqm",
            "living_area_sqm","floor","building_floors","year_built",
            "ceiling_height_m","metro_time_min","metro_2_time_min",
            "metro_3_time_min","passenger_lift","freight_lift","renovation_cost_rub"]:
    out[col] = pd.to_numeric(out[col], errors="coerce")
out["price_per_sqm"] = np.where(
    (out.price_rub > 0) & (out.total_area_sqm > 0),
    out.price_rub / out.total_area_sqm, np.nan
)
out["floor_category"] = np.select(
    [out.floor.isna(), out.floor.eq(1), out.floor.eq(out.building_floors), out.floor.le(3)],
    ["Не указано", "Первый", "Последний", "Низкий"], default="Средний"
)
out["price_segment"] = pd.qcut(
    out.price_rub.rank(method="first"), 3,
    labels=["Бюджетный", "Средний", "Высокий"]
)
out.to_csv(output_file, index=False, encoding="utf-8-sig")
print(f"Готово: {output_file.resolve()} | строк: {len(out)} | столбцов: {len(out.columns)}")
