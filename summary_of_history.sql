-- Получение сводной информации об истории изменений по указанной директории  (при изменении условий иожет использоваться для поиска по функции в файле  или по методу класса).
-- С уточнением интервала времени разработки, автора, сообщениях коммитов, а так же связи изменений с pull request и issues, их описанием и ссылками. 
WITH
target_commits AS (
    SELECT DISTINCT c.id, c.repo_id, c.commit_created_at
    FROM commits c
    JOIN file_changes fc ON c.id = fc.commit_id
    WHERE
        c.repo_id = 32
--        AND fc.diff IS NOT null  -- Нужен если поиск по полю diff
        -- Поиск по директории
         AND fc.file_path LIKE 'some_dir/notifications/%' 
        -- Поиск по классу
--         AND fc.diff ~ '(^|\n)@@[^\n]*[[:space:]]class[[:space:]]+Notificator([^[:alnum:]_]|$)'
        -- Поиск по методу класса
--         AND fc.diff ~ '(^|\n)@@[^\n]*[[:space:]]class[[:space:]]+Notificator([^[:alnum:]_]|$)[\s\S]*add_notification([^[:alnum:]_]|$)'
        -- Поиск по функции в файле
--        AND (
--            fc.file_path = 'some_dir/notifications/handlers.py'
--            OR fc.old_path = 'some_dir/notifications/handlers.py'
--        )
--        AND (
--		    fc.diff ~ '(^|\n)@@[^\n]*get_data([^[:alnum:]_]|$)'
--		    OR fc.diff ~ '(^|\n)[ +\-][^\n]*get_data([^[:alnum:]_]|$)'
--		)
),
commits_with_first_parent AS (
    SELECT DISTINCT
        c.hash AS current_commit_hash,
        c.repo_id AS commit_repo_id,
        CASE
            WHEN c.parent_hashes IS NULL OR array_length(c.parent_hashes, 1) = 0 THEN NULL
            ELSE c.parent_hashes[1]
        END AS first_parent_hash,
        c.commit_created_at AS current_commit_time,
        c.author_name,
        c.message AS commit_message,
        c.pull_request_id,
        c.repo_id
    FROM commits c
    JOIN target_commits tc ON c.id = tc.id AND c.repo_id = tc.repo_id
),
aggregated_issues AS (
    SELECT
        pr.id AS pr_id_for_issues,
        ARRAY_AGG(DISTINCT i.issue_id) FILTER (WHERE i.issue_id IS NOT NULL) AS related_issue_issue_ids,
        ARRAY_AGG(DISTINCT i.title) FILTER (WHERE i.title IS NOT NULL) AS related_issue_titles,
        ARRAY_AGG(DISTINCT i.description) FILTER (WHERE i.description IS NOT NULL) AS related_issue_descriptions,
        ARRAY_AGG(DISTINCT i.url) FILTER (WHERE i.url IS NOT NULL) AS related_issue_urls
    FROM pull_requests pr
    LEFT JOIN issues i ON i.id = ANY(pr.issue_ids) AND i.repo_id = pr.repo_id
    GROUP BY pr.id
)
SELECT
    cwp.repo_id,
    (cwp.current_commit_time - p.commit_created_at) AS time_interval,
    cwp.current_commit_time,
    p.commit_created_at AS parent_commit_time,
    cwp.author_name,
    cwp.commit_message,
    cwp.current_commit_hash,
    cwp.first_parent_hash,
    cwp.pull_request_id AS pr_id,
    pr.title AS pr_title,
    pr.url AS pr_url,
    ai.related_issue_issue_ids,
    ai.related_issue_titles,
    ai.related_issue_descriptions,
    ai.related_issue_urls
FROM commits_with_first_parent cwp
JOIN commits p ON p.hash = cwp.first_parent_hash AND p.repo_id = cwp.commit_repo_id
LEFT JOIN pull_requests pr ON cwp.pull_request_id = pr.id
LEFT JOIN aggregated_issues ai ON pr.id = ai.pr_id_for_issues
WHERE cwp.first_parent_hash IS NOT NULL
ORDER BY cwp.current_commit_time DESC
--LIMIT 10;
