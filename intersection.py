import pandas as pd
# 1. Загрузка данных из трёх CSV файлов
df_changes = pd.read_csv('/top_files_changes_repo_32.csv')
df_authors = pd.read_csv('/top_files_by_authors_repo_32.csv')
df_bugfix = pd.read_csv('/top_files_bugfix_repo_32.csv')
# 2. Расчёт рангов для каждого критерия
df_changes['rank_changes'] = df_changes['changes'].rank(ascending=False, method='min')
df_authors['rank_authors'] = df_authors['developer_count'].rank(ascending=False, method='min')
df_bugfix['rank_bugfix'] = df_bugfix['bugfix_change_count'].rank(ascending=False, method='min')
# 3. Поиск пересечений (аналог INNER JOIN)
df_intersection = df_changes.merge(df_authors, on='file_path', how='inner').merge(df_bugfix, on='file_path', how='inner')
# 4. Расчёт среднего ранга
df_intersection['avg_rank'] = (df_intersection['rank_changes'] + df_intersection['rank_authors'] + df_intersection['rank_bugfix']) / 3
# 5. Отбор топ-10 и сохранение
df_top10 = df_intersection.sort_values('avg_rank').head(10)
df_top10.to_csv('/top-10_intersection.csv', index=False)