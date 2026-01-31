-- Анализ частоты изменений: Top-100 файлов по количеству изменений (без связи с PR, Issue)
select 
	fc.file_path, 
	count(distinct fc.id) as changes   -- Получаем количество изменений для каждого файла
from file_changes fc
inner join commits c on fc.commit_id = c.id
where fc.repo_id = 32 and fc.file_path like 'some_root_dir/%'   -- указываем репозиторий и директорию для интересующего нас сервиса
group by fc.file_path
order by changes desc
limit 100;   -- Ограничиваем количество данных в результате


-- Анализ частоты изменений: Топ-100 файлов по количеству изменений
SELECT 
	fc.file_path,
    COUNT(DISTINCT fc.id) AS changes,
	-- Агрегируем уникальные ID PR и Issue
	ARRAY_AGG(DISTINCT pr.id) FILTER (WHERE pr.id IS NOT NULL) AS related_pr_ids,
    ARRAY_AGG(DISTINCT i.id) FILTER (WHERE i.id IS NOT NULL) AS related_issue_ids
FROM file_changes fc
    INNER JOIN commits c ON fc.commit_id = c.id
    LEFT JOIN pull_requests pr ON c.pull_request_id = pr.id
    LEFT JOIN issues i ON (i.repo_id = pr.repo_id AND i.id = ANY(pr.issue_ids))
WHERE fc.repo_id = 32 and fc.file_path like 'some_root_dir/%'
GROUP BY fc.file_path
ORDER BY changes DESC
LIMIT 100; 


-- Анализ по авторам: Топ-100 файлов, изменяемых большим количеством разработчиков
select
	fc.file_path,
	COUNT(distinct fc.id) as total_changes,
	COUNT(distinct c.author_email) as developer_count,
	STRING_AGG(distinct c.author_name, ', ') as contributing_developers,
	-- Агрегируем уникальные ID PR и Issue
	ARRAY_AGG(DISTINCT pr.id) FILTER (WHERE pr.id IS NOT NULL) AS related_pr_ids,
    ARRAY_AGG(DISTINCT i.id) FILTER (WHERE i.id IS NOT NULL) AS related_issue_ids
from file_changes fc
    INNER JOIN commits c ON fc.commit_id = c.id
    LEFT JOIN pull_requests pr ON c.pull_request_id = pr.id
    LEFT JOIN issues i ON (i.repo_id = pr.repo_id AND i.id = ANY(pr.issue_ids))
where
	fc.repo_id = 32 and fc.file_path like 'some_root_dir/%'
group by
	fc.file_path
order by
	developer_count desc,
	total_changes desc
limit 100;


-- Анализ по типами задач: Топ-100 файлов с наибольшим кол-ом изменений, связанных с исправлением ошибок(bug, fix, err,  исправ, ошиб)
select 
	fc.file_path, COUNT(DISTINCT fc.id) AS bugfix_change_count,
	-- Агрегируем уникальные ID PR и Issue
	ARRAY_AGG(DISTINCT pr.id) FILTER (WHERE pr.id IS NOT NULL) AS related_pr_ids,
    ARRAY_AGG(DISTINCT i.id) FILTER (WHERE i.id IS NOT NULL) AS related_issue_ids
FROM 
    file_changes fc
    INNER JOIN commits c ON fc.commit_id = c.id
    LEFT JOIN pull_requests pr ON c.pull_request_id = pr.id
    LEFT JOIN issues i ON (i.repo_id = pr.repo_id AND i.id = ANY(pr.issue_ids))
WHERE 
    fc.repo_id = 32 and fc.file_path like 'some_root_dir/%'
    AND (
        LOWER(c.message) LIKE '%bug%' OR LOWER(c.message) LIKE '%fix%' OR LOWER(c.message) LIKE '%err%'
        OR LOWER(c.message) LIKE '%исправ%' OR LOWER(c.message) LIKE '%ошиб%'
        OR (pr.title IS NOT NULL AND (
            LOWER(pr.title) LIKE '%bug%' OR LOWER(pr.title) LIKE '%fix%' OR LOWER(pr.title) LIKE '%err%'
            OR LOWER(pr.title) LIKE '%исправ%' OR LOWER(pr.title) LIKE '%ошиб%'))
        OR (i.title IS NOT NULL AND (
            LOWER(i.title) LIKE '%bug%' OR LOWER(i.title) LIKE '%fix%' OR LOWER(i.title) LIKE '%err%'
            OR LOWER(i.title) LIKE '%исправ%' OR LOWER(i.title) LIKE '%ошиб%'))
        OR (i.description IS NOT NULL AND (
            LOWER(i.description) LIKE '%bug%' OR LOWER(i.description) LIKE '%fix%' OR LOWER(i.description) LIKE '%err%'
            OR LOWER(i.description) LIKE '%исправ%' OR LOWER(i.description) LIKE '%ошиб%'))
    )
GROUP BY fc.file_path
ORDER BY bugfix_change_count DESC
LIMIT 100;
