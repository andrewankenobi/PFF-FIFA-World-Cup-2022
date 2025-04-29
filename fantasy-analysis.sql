-- =============================================================================
-- File: fantasy-analysis.sql
-- Description: SQL queries focused on Fantasy Football relevant metrics
--              from the FIFA World Cup 2022 dataset.
-- Project: FIFA World Cup 2022 GCP Project
-- Author: AI Assistant & User
-- Last Updated: 2025-04-29
-- =============================================================================
-- Notes:
--   * Queries assume the dataset 'fifa_world_cup_2022' in project 'awesome-advice-420021'.
--   * Event type codes (e.g., 'SH', 'G', 'PA', 'CH', 'S') are based on previous analysis.
--   * Player positions are taken from the 'rosters' table.
--   * Clean sheet logic is derived by counting goals per team per match from 'events'.
-- =============================================================================

-- =============================================
-- Query 1: Top Goal Scorers (Overall)
-- Description: Players with the most goals scored.
-- =============================================
SELECT
    e.possessionEvents.shooterPlayerName AS player_name,
    COUNT(*) AS goals_scored
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Shot Events
    AND e.possessionEvents.shotOutcomeType = 'G'  -- Goal outcomes
    AND e.possessionEvents.shooterPlayerName IS NOT NULL
GROUP BY 1
ORDER BY goals_scored DESC
LIMIT 20;

-- =============================================
-- Query 2: Top Goal Scorers (Midfielders)
-- Description: Midfielders (CM, DM, AM, RM, LM) with the most goals scored.
-- =============================================
SELECT
    e.possessionEvents.shooterPlayerName AS player_name,
    r.positionGroupType AS position,
    COUNT(*) AS goals_scored
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
INNER JOIN
    `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    ON e.match_id = r.match_id AND CAST(e.possessionEvents.shooterPlayerId AS STRING) = r.player.id
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Shot Events
    AND e.possessionEvents.shotOutcomeType = 'G'  -- Goal outcomes
    AND e.possessionEvents.shooterPlayerName IS NOT NULL
    AND r.positionGroupType IN ('CM', 'DM', 'AM', 'RM', 'LM') -- Filter for Midfielder codes
GROUP BY 1, 2
ORDER BY goals_scored DESC
LIMIT 10;

-- =============================================
-- Query 3: Top Goal Scorers (Defenders)
-- Description: Defenders (LCB, MCB, RCB, LB, RB, LWB, RWB) with the most goals scored.
-- =============================================
SELECT
    e.possessionEvents.shooterPlayerName AS player_name,
    r.positionGroupType AS position,
    COUNT(*) AS goals_scored
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
INNER JOIN
    `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    ON e.match_id = r.match_id AND CAST(e.possessionEvents.shooterPlayerId AS STRING) = r.player.id
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Shot Events
    AND e.possessionEvents.shotOutcomeType = 'G'  -- Goal outcomes
    AND e.possessionEvents.shooterPlayerName IS NOT NULL
    AND r.positionGroupType IN ('LCB', 'MCB', 'RCB', 'LB', 'RB', 'LWB', 'RWB') -- Filter for Defender codes
GROUP BY 1, 2
ORDER BY goals_scored DESC
LIMIT 10;

-- =============================================
-- Query 4: Most Shots on Target (Overall)
-- Description: Players with the most shots resulting in Goal ('G') or Save ('S').
-- =============================================
SELECT
    e.possessionEvents.shooterPlayerName AS player_name,
    COUNT(*) AS shots_on_target
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Shot Events
    AND e.possessionEvents.shotOutcomeType IN ('G', 'S')  -- Goal or Saved
    AND e.possessionEvents.shooterPlayerName IS NOT NULL
GROUP BY 1
ORDER BY shots_on_target DESC
LIMIT 20;

-- =============================================
-- Query 5: Highest Pass Completion % (Midfielders, Min 100 Attempts)
-- Description: Pass completion rate for midfielders.
-- =============================================
WITH MidfielderPasses AS (
    SELECT
        e.possessionEvents.passerPlayerName AS player_name,
        COUNT(*) AS total_passes,
        COUNTIF(e.possessionEvents.passOutcomeType IS NULL OR e.possessionEvents.passOutcomeType NOT IN ('I', 'O')) AS successful_passes
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    INNER JOIN
        `awesome-advice-420021.fifa_world_cup_2022.rosters` r
        ON e.match_id = r.match_id AND CAST(e.possessionEvents.passerPlayerId AS STRING) = r.player.id
    WHERE
        e.possessionEvents.possessionEventType = 'PA' -- Pass Events
        AND e.possessionEvents.passerPlayerName IS NOT NULL
        AND r.positionGroupType = 'Midfielder' -- Filter for Midfielders
    GROUP BY 1
)
SELECT
    player_name,
    total_passes,
    successful_passes,
    ROUND(SAFE_DIVIDE(successful_passes, total_passes) * 100, 1) AS completion_percentage
FROM MidfielderPasses
WHERE total_passes >= 100 -- Minimum 100 pass attempts
ORDER BY completion_percentage DESC
LIMIT 20;

-- =============================================
-- Query 6: Most Tackles Won (Defenders)
-- Description: Defenders (LCB, MCB, RCB, LB, RB, LWB, RWB) with the most successful challenges ('CH' outcome 'S').
-- =============================================
SELECT
    e.possessionEvents.challengerPlayerName AS player_name,
    r.positionGroupType AS position,
    COUNT(*) AS tackles_won
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
INNER JOIN
    `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    ON e.match_id = r.match_id AND CAST(e.possessionEvents.challengerPlayerId AS STRING) = r.player.id
WHERE
    e.possessionEvents.possessionEventType = 'CH' -- Challenge Events
    AND e.possessionEvents.challengeOutcomeType = 'S' -- Inferred Successful outcome
    AND e.possessionEvents.challengerPlayerName IS NOT NULL
    AND r.positionGroupType IN ('LCB', 'MCB', 'RCB', 'LB', 'RB', 'LWB', 'RWB') -- Filter for Defender codes
GROUP BY 1, 2
ORDER BY tackles_won DESC
LIMIT 10;

-- =============================================
-- Query 7: Most Tackles Won (Midfielders)
-- Description: Midfielders (CM, DM, AM, RM, LM) with the most successful challenges ('CH' outcome 'S').
-- =============================================
SELECT
    e.possessionEvents.challengerPlayerName AS player_name,
    r.positionGroupType AS position,
    COUNT(*) AS tackles_won
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
INNER JOIN
    `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    ON e.match_id = r.match_id AND CAST(e.possessionEvents.challengerPlayerId AS STRING) = r.player.id
WHERE
    e.possessionEvents.possessionEventType = 'CH' -- Challenge Events
    AND e.possessionEvents.challengeOutcomeType = 'S' -- Inferred Successful outcome
    AND e.possessionEvents.challengerPlayerName IS NOT NULL
    AND r.positionGroupType IN ('CM', 'DM', 'AM', 'RM', 'LM') -- Filter for Midfielder codes
GROUP BY 1, 2
ORDER BY tackles_won DESC
LIMIT 10;

-- =============================================
-- Query 8: Most Saves (Goalkeepers)
-- Description: Goalkeepers credited with the most saves ('SH' outcome 'S').
-- =============================================
SELECT
    e.possessionEvents.keeperPlayerName AS player_name,
    COUNT(*) AS saves_made
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Shot Events
    AND e.possessionEvents.shotOutcomeType = 'S'  -- Saved outcomes
    AND e.possessionEvents.keeperPlayerName IS NOT NULL
GROUP BY 1
ORDER BY saves_made DESC
LIMIT 10;

-- =============================================
-- Query 9: Most Clean Sheets (Goalkeepers - Started)
-- Description: Goalkeepers (GK) who started matches where their team kept a clean sheet.
-- =============================================
WITH MatchGoalsAgainst AS (
    -- Determine goals conceded by each team in each match
    SELECT
        e.match_id,
        -- Identify the team that CONCEDED the goal
        CASE
            WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id THEN m.awayTeam.id -- Goal scored by home, conceded by away
            WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id THEN m.homeTeam.id -- Goal scored by away, conceded by home
            ELSE NULL -- Should not happen if teamId is correct
        END as conceding_team_id,
        COUNT(*) as goals_conceded
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    INNER JOIN
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m ON e.match_id = m.id
    WHERE
        e.possessionEvents.possessionEventType = 'SH' -- Shot Events
        AND e.possessionEvents.shotOutcomeType = 'G'  -- Goal outcomes
        AND e.gameEvents.teamId IS NOT NULL
    GROUP BY 1, 2
),
TeamCleanSheets AS (
    -- Identify matches where a team conceded 0 goals
    SELECT
        m.id as match_id,
        m.homeTeam.id AS team_id,
        m.homeTeam.name AS team_name
    FROM `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN MatchGoalsAgainst mga ON m.id = mga.match_id AND m.homeTeam.id = mga.conceding_team_id
    WHERE mga.match_id IS NULL -- No conceded goals means clean sheet for home team
    UNION ALL
    SELECT
        m.id as match_id,
        m.awayTeam.id AS team_id,
        m.awayTeam.name AS team_name
    FROM `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN MatchGoalsAgainst mga ON m.id = mga.match_id AND m.awayTeam.id = mga.conceding_team_id
    WHERE mga.match_id IS NULL -- No conceded goals means clean sheet for away team
)
SELECT
    r.player.nickname AS player_name, -- Using nickname from roster
    COUNT(DISTINCT tcs.match_id) AS clean_sheets
FROM TeamCleanSheets tcs
INNER JOIN `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    ON tcs.match_id = r.match_id AND tcs.team_id = r.team.id
WHERE
    r.positionGroupType = 'GK' -- Use code 'GK' for Goalkeeper
    AND r.started = TRUE -- Player started the match
GROUP BY 1
ORDER BY clean_sheets DESC
LIMIT 10;

-- =============================================
-- Query 10: Most Clean Sheets (Defenders - Started)
-- Description: Defenders (LCB, MCB, RCB, LB, RB, LWB, RWB) who started matches where their team kept a clean sheet.
-- =============================================
WITH MatchGoalsAgainst AS (
    -- Determine goals conceded by each team in each match
    SELECT
        e.match_id,
        -- Identify the team that CONCEDED the goal
        CASE
            WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id THEN m.awayTeam.id -- Goal scored by home, conceded by away
            WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id THEN m.homeTeam.id -- Goal scored by away, conceded by home
            ELSE NULL -- Should not happen if teamId is correct
        END as conceding_team_id,
        COUNT(*) as goals_conceded
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    INNER JOIN
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m ON e.match_id = m.id
    WHERE
        e.possessionEvents.possessionEventType = 'SH' -- Shot Events
        AND e.possessionEvents.shotOutcomeType = 'G'  -- Goal outcomes
        AND e.gameEvents.teamId IS NOT NULL
    GROUP BY 1, 2
),
TeamCleanSheets AS (
    -- Identify matches where a team conceded 0 goals
    SELECT
        m.id as match_id,
        m.homeTeam.id AS team_id,
        m.homeTeam.name AS team_name
    FROM `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN MatchGoalsAgainst mga ON m.id = mga.match_id AND m.homeTeam.id = mga.conceding_team_id
    WHERE mga.match_id IS NULL -- No conceded goals means clean sheet for home team
    UNION ALL
    SELECT
        m.id as match_id,
        m.awayTeam.id AS team_id,
        m.awayTeam.name AS team_name
    FROM `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN MatchGoalsAgainst mga ON m.id = mga.match_id AND m.awayTeam.id = mga.conceding_team_id
    WHERE mga.match_id IS NULL -- No conceded goals means clean sheet for away team
)
SELECT
    r.player.nickname AS player_name, -- Using nickname from roster
    COUNT(DISTINCT tcs.match_id) AS clean_sheets
FROM TeamCleanSheets tcs
INNER JOIN `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    ON tcs.match_id = r.match_id AND tcs.team_id = r.team.id
WHERE
    r.positionGroupType IN ('LCB', 'MCB', 'RCB', 'LB', 'RB', 'LWB', 'RWB') -- Use Defender codes
    AND r.started = TRUE -- Player started the match
GROUP BY 1
ORDER BY clean_sheets DESC
LIMIT 10;

-- =============================================================================
-- End of File
-- =============================================================================
