-- =============================================================================
-- File: grades-analysis.sql
-- Description: SQL queries focused on analyzing PFF player performance grades
--              from the FIFA World Cup 2022 dataset.
-- Project: FIFA World Cup 2022 GCP Project
-- Author: AI Assistant & User
-- Last Updated: 2025-04-29
-- =============================================================================
-- Notes:
--   * Queries assume the dataset 'fifa_world_cup_2022' in project 'awesome-advice-420021'.
--   * Grades are typically associated with specific event types (e.g., passerGrade for PA).
--   * NULL grades should be handled appropriately (e.g., using AVG ignores NULLs).
-- =============================================================================

-- =============================================
-- Query 1: Average Passer Grade for Top Passers (by volume)
-- Description: Calculates the average passerGrade for players with the most pass attempts.
-- =============================================
WITH PlayerPasses AS (
    SELECT
        e.possessionEvents.passerPlayerName AS player_name,
        COUNT(*) AS pass_attempts,
        AVG(e.grades.passerGrade) AS avg_passer_grade -- AVG ignores NULL grades
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    WHERE
        e.possessionEvents.possessionEventType = 'PA' -- Pass Events
        AND e.possessionEvents.passerPlayerName IS NOT NULL
    GROUP BY
        1
)
SELECT
    player_name,
    pass_attempts,
    avg_passer_grade
FROM
    PlayerPasses
WHERE
    pass_attempts > 100 -- Filter for players with a minimum number of passes for meaningful average
ORDER BY
    pass_attempts DESC,
    avg_passer_grade DESC
LIMIT 20;

-- =============================================
-- Query 2: Average Shooter Grade for Top Shooters (by volume)
-- Description: Calculates the average shooterGrade for players with the most shot attempts.
-- =============================================
WITH PlayerShots AS (
    SELECT
        e.possessionEvents.shooterPlayerName AS player_name,
        COUNT(*) AS shot_attempts,
        AVG(e.grades.shooterGrade) AS avg_shooter_grade -- AVG ignores NULL grades
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    WHERE
        e.possessionEvents.possessionEventType = 'SH' -- Shot Events
        AND e.possessionEvents.shooterPlayerName IS NOT NULL
    GROUP BY
        1
)
SELECT
    player_name,
    shot_attempts,
    avg_shooter_grade
FROM
    PlayerShots
WHERE
    shot_attempts > 5 -- Filter for players with a minimum number of shots
ORDER BY
    shot_attempts DESC,
    avg_shooter_grade DESC
LIMIT 20;

-- =============================================
-- Query 3: Highest Graded Individual Challenges
-- Description: Finds specific challenge events with the highest challengerGrade.
-- =============================================
SELECT
    e.match_id,
    e.possessionEvents.formattedGameClock AS game_time,
    e.possessionEvents.challengerPlayerName AS challenger_name,
    e.possessionEvents.challengeOutcomeType AS outcome,
    e.grades.challengerGrade AS challenger_grade
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'CH' -- Challenge Events
    AND e.grades.challengerGrade IS NOT NULL
ORDER BY
    challenger_grade DESC
LIMIT 20;

-- =============================================
-- Query 4: Average Shooter Grade: Goals vs. Non-Goals
-- Description: Compares the average shooter grade for shots that resulted in a goal (G)
--              versus those that did not.
-- =============================================
SELECT
    CASE
        WHEN e.possessionEvents.shotOutcomeType = 'G' THEN 'Goal'
        ELSE 'No Goal'
    END AS shot_result,
    COUNT(*) AS number_of_shots,
    AVG(e.grades.shooterGrade) AS avg_shooter_grade
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Shot Events
    AND e.grades.shooterGrade IS NOT NULL
    AND e.possessionEvents.shotOutcomeType IS NOT NULL -- Exclude shots with unknown outcomes
GROUP BY
    1 -- Group by shot_result
ORDER BY
    shot_result;

-- =============================================
-- Query 5: Passer Grade Distribution
-- Description: Shows the distribution of passerGrade values in buckets.
-- =============================================
WITH GradeBuckets AS (
    SELECT
        e.grades.passerGrade AS grade,
        CASE
            WHEN e.grades.passerGrade < -1.0 THEN '1. < -1.0'
            WHEN e.grades.passerGrade >= -1.0 AND e.grades.passerGrade < -0.5 THEN '2. [-1.0, -0.5)'
            WHEN e.grades.passerGrade >= -0.5 AND e.grades.passerGrade < 0.0 THEN '3. [-0.5, 0.0)'
            WHEN e.grades.passerGrade >= 0.0 AND e.grades.passerGrade < 0.5 THEN '4. [0.0, 0.5)'
            WHEN e.grades.passerGrade >= 0.5 AND e.grades.passerGrade < 1.0 THEN '5. [0.5, 1.0)'
            WHEN e.grades.passerGrade >= 1.0 THEN '6. >= 1.0'
            ELSE '7. NULL or Other'
        END AS grade_bucket
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    WHERE
        e.possessionEvents.possessionEventType = 'PA' -- Pass Events
)
SELECT
    grade_bucket,
    COUNT(*) AS count,
    ROUND(AVG(grade), 3) AS avg_grade_in_bucket
FROM
    GradeBuckets
GROUP BY
    grade_bucket
ORDER BY
    grade_bucket;

-- =============================================
-- Query 6: Average Passer Grade vs. Pass Outcome
-- Description: Calculates the average passerGrade for different pass outcomes.
-- =============================================
SELECT
    e.possessionEvents.passOutcomeType AS pass_outcome,
    COUNT(*) AS number_of_passes,
    ROUND(AVG(e.grades.passerGrade), 3) AS avg_passer_grade -- AVG ignores NULL grades
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'PA' -- Pass Events
    AND e.grades.passerGrade IS NOT NULL
    -- AND e.possessionEvents.passOutcomeType IS NOT NULL -- Optional: Exclude passes with NULL outcomes
GROUP BY
    1 -- Group by pass_outcome
ORDER BY
    avg_passer_grade DESC;

-- =============================================
-- Query 7: Lowest Graded Individual Passes
-- Description: Finds specific pass events with the lowest passerGrade.
-- =============================================
SELECT
    e.match_id,
    e.possessionEvents.formattedGameClock AS game_time,
    e.possessionEvents.passerPlayerName AS passer_name,
    e.possessionEvents.passOutcomeType AS outcome,
    e.grades.passerGrade AS passer_grade
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'PA' -- Pass Events
    AND e.grades.passerGrade IS NOT NULL
ORDER BY
    passer_grade ASC -- Order ascending to get lowest grades first
LIMIT 20;

-- =============================================
-- Query 8: Average Passer Grade per Team
-- Description: Calculates the average passerGrade for each team.
-- Requires joining Events with Rosters to link player to team.
-- =============================================
WITH TeamPassGrades AS (
    SELECT
        r.team.name AS team_name,
        e.grades.passerGrade AS passer_grade
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    INNER JOIN
        `awesome-advice-420021.fifa_world_cup_2022.rosters` r
        ON e.match_id = r.match_id AND CAST(e.possessionEvents.passerPlayerId AS STRING) = r.player.id
    WHERE
        e.possessionEvents.possessionEventType = 'PA' -- Pass Events
        AND e.grades.passerGrade IS NOT NULL
        AND e.possessionEvents.passerPlayerId IS NOT NULL
        AND r.team.name IS NOT NULL
)
SELECT
    team_name,
    COUNT(passer_grade) AS number_of_graded_passes,
    ROUND(AVG(passer_grade), 3) AS avg_team_passer_grade
FROM
    TeamPassGrades
GROUP BY
    team_name
ORDER BY
    avg_team_passer_grade DESC;

-- =============================================
-- Query 9: Average Passer Grade by Position Group
-- Description: Calculates the average passerGrade grouped by player position.
-- Requires joining Events with Rosters.
-- =============================================
WITH PositionPassGrades AS (
    SELECT
        r.positionGroupType AS position_group, -- Position from rosters table
        e.grades.passerGrade AS passer_grade
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    INNER JOIN
        `awesome-advice-420021.fifa_world_cup_2022.rosters` r
        ON e.match_id = r.match_id AND CAST(e.possessionEvents.passerPlayerId AS STRING) = r.player.id
    WHERE
        e.possessionEvents.possessionEventType = 'PA' -- Pass Events
        AND e.grades.passerGrade IS NOT NULL
        AND e.possessionEvents.passerPlayerId IS NOT NULL
        AND r.positionGroupType IS NOT NULL
)
SELECT
    position_group,
    COUNT(passer_grade) AS number_of_graded_passes,
    ROUND(AVG(passer_grade), 3) AS avg_position_passer_grade
FROM
    PositionPassGrades
GROUP BY
    position_group
ORDER BY
    avg_position_passer_grade DESC;

-- =============================================
-- Query 10: Highest Average Passer Grade in a Single Match (Min 20 Passes)
-- Description: Finds player-match combinations with the highest average passerGrade,
--              requiring a minimum number of passes in that match.
-- =============================================
WITH MatchPlayerPassGrades AS (
    SELECT
        e.match_id,
        e.possessionEvents.passerPlayerName AS player_name,
        AVG(e.grades.passerGrade) AS avg_match_passer_grade,
        COUNT(*) AS passes_in_match
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    WHERE
        e.possessionEvents.possessionEventType = 'PA' -- Pass Events
        AND e.grades.passerGrade IS NOT NULL
        AND e.possessionEvents.passerPlayerName IS NOT NULL
    GROUP BY
        1, 2
)
SELECT
    match_id,
    player_name,
    passes_in_match,
    ROUND(avg_match_passer_grade, 3) AS avg_match_passer_grade
FROM
    MatchPlayerPassGrades
WHERE
    passes_in_match >= 20 -- Minimum passes filter
ORDER BY
    avg_match_passer_grade DESC
LIMIT 20;

-- =============================================================================
-- End of File - Final v2
-- =============================================================================
