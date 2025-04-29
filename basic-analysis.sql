-- =============================================================================
-- File: basic-analysis.sql
-- Description: Exploratory SQL queries for the FIFA World Cup 2022 dataset.
-- Project: FIFA World Cup 2022 GCP Project
-- Author: AI Assistant & User
-- Last Updated: 2025-04-29
-- =============================================================================
-- Notes:
--   * These queries are intended for basic exploration and analysis.
--   * Table names assume the dataset 'fifa_world_cup_2022' in project 'awesome-advice-420021'.
--   * Some queries include LIMIT clauses for testing/performance; remove for full results.
-- =============================================================================

-- =============================================
-- Query 1: Total Event Count per Match
-- Description: Counts the total number of granular event records for each match.
-- =============================================
SELECT
    match_id,
    COUNT(*) AS total_events -- Each row in the events table represents one granular event
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events`
GROUP BY
    match_id
ORDER BY
    total_events DESC;

-- =============================================
-- Query 2: Players per Team
-- Description: Lists distinct players associated with each team using roster data.
-- =============================================
SELECT distinct
  p.firstName,
  p.lastName,
  r.team.name AS team_name
FROM
  `awesome-advice-420021.fifa_world_cup_2022.players` AS p
INNER JOIN
  `awesome-advice-420021.fifa_world_cup_2022.rosters` AS r
ON
  CAST(p.id AS STRING) = r.player.id -- Join player ID (INT64) with roster player ID (STRING)
ORDER BY
    team_name, p.lastName; -- Order by team, then player last name

-- =============================================
-- Query 3: Match Details with Competition Info
-- Description: Retrieves core match metadata and joins with competition details.
-- =============================================
SELECT
    m.id AS match_id,
    m.date AS match_date,
    m.homeTeam.id AS home_team_id,
    m.homeTeam.name AS home_team_name,
    m.homeTeam.shortName AS home_team_short_name,
    m.awayTeam.id AS away_team_id,
    m.awayTeam.name AS away_team_name,
    m.awayTeam.shortName AS away_team_short_name,
    m.season AS season,
    m.week AS week,
    m.stadium.id AS stadium_id,
    m.stadium.name AS stadium_name,
    m.fps AS video_fps,
    m.videoUrl AS video_url,
    c.name AS competition_name
FROM
    `awesome-advice-420021.fifa_world_cup_2022.match_metadata` AS m
INNER JOIN
    `awesome-advice-420021.fifa_world_cup_2022.competitions` AS c
ON
    m.competition.id = CAST(c.id AS STRING) -- Join metadata competition ID (STRING) with competitions ID (INT64)
LIMIT 10;

-- =============================================
-- Query 4: Top 10 Goal Scorers
-- Description: Identifies players with the most goals based on 'SH' (Shot) events
--              with outcome 'G' (Goal).
-- =============================================
SELECT
    e.possessionEvents.shooterPlayerName AS player_name,
    COUNT(*) AS goals_scored
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Filter for Shot events
    AND e.possessionEvents.shotOutcomeType = 'G'  -- Filter for Goal outcomes
    AND e.possessionEvents.shooterPlayerName IS NOT NULL -- Ensure player name exists
GROUP BY
    1 -- Group by player_name (using column index)
ORDER BY
    goals_scored DESC
LIMIT 10;

-- =============================================
-- Query 5: Team Match Results (Wins, Draws, Losses)
-- Description: Calculates the final W/D/L record for each team by deriving scores
--              from goal events in the 'events' table.
-- =============================================
WITH MatchGoals AS (
    -- Step 1: Count goals scored by each team within each match.
    -- Uses teamId from the gameEvents struct associated with the goal event.
    SELECT
        e.match_id,
        e.gameEvents.teamId AS team_id,
        COUNT(*) as goals_scored
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    WHERE
        e.possessionEvents.possessionEventType = 'SH' -- Filter for Shot events
        AND e.possessionEvents.shotOutcomeType = 'G'  -- Filter for Goal outcomes
        AND e.gameEvents.teamId IS NOT NULL -- Ensure the scoring team ID is recorded
    GROUP BY
        1, 2 -- Group by match and scoring team
),
MatchScores AS (
    -- Step 2: Aggregate goals per match for home and away teams.
    -- Joins the goal counts with match metadata.
    SELECT
        m.id AS match_id,
        m.homeTeam.name AS home_team_name,
        m.awayTeam.name AS away_team_name,
        -- Sum goals if the scoring team ID matches the home team ID (cast types first)
        COALESCE(SUM(CASE WHEN CAST(mg.team_id AS STRING) = m.homeTeam.id THEN mg.goals_scored ELSE 0 END), 0) as home_score,
        -- Sum goals if the scoring team ID matches the away team ID (cast types first)
        COALESCE(SUM(CASE WHEN CAST(mg.team_id AS STRING) = m.awayTeam.id THEN mg.goals_scored ELSE 0 END), 0) as away_score
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN
        MatchGoals mg ON m.id = mg.match_id -- Join on match ID (both STRING)
    GROUP BY
        1, 2, 3 -- Group by match, home team name, away team name
),
MatchOutcomes AS (
    -- Step 3: Determine the winner based on the calculated scores.
    SELECT
        home_team_name,
        away_team_name,
        CASE
            WHEN home_score > away_score THEN home_team_name
            WHEN away_score > home_score THEN away_team_name
            ELSE 'Draw'
        END AS winner
    FROM
        MatchScores
),
TeamResults AS (
    -- Step 4: Unpivot the results to get one record per team per match result (Win/Draw/Loss).
    -- This makes final aggregation easier.
    SELECT home_team_name AS team_name,
           CASE WHEN winner = home_team_name THEN 'Win' WHEN winner = 'Draw' THEN 'Draw' ELSE 'Loss' END AS result_type
    FROM MatchOutcomes
    UNION ALL
    SELECT away_team_name AS team_name,
           CASE WHEN winner = away_team_name THEN 'Win' WHEN winner = 'Draw' THEN 'Draw' ELSE 'Loss' END AS result_type
    FROM MatchOutcomes
)
-- Step 5: Final aggregation to get total Wins, Draws, Losses per team.
SELECT
    team_name,
    COUNTIF(result_type = 'Win') AS wins,
    COUNTIF(result_type = 'Draw') AS draws,
    COUNTIF(result_type = 'Loss') AS losses
FROM
    TeamResults
WHERE team_name IS NOT NULL -- Exclude any potential NULL team names
GROUP BY
    team_name
ORDER BY
    wins DESC, draws DESC, losses ASC;

-- =============================================
-- Query 6: Top 10 Players by Successful Tackles
-- Description: Counts successful tackles per player, interpreting a 'Challenge' event
--              with outcome 'Won' as a successful tackle.
--              NOTE: Outcome code for 'Won' is inferred as 'S'.
-- =============================================
SELECT
    e.possessionEvents.challengerPlayerName AS player_name,
    COUNT(*) AS tackles_won
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'CH' -- Filter for Challenge events (CH code)
    AND e.possessionEvents.challengeOutcomeType = 'S' -- Filter for 'S' outcome (Inferred as Won/Success)
    AND e.possessionEvents.challengerPlayerName IS NOT NULL
GROUP BY
    1 -- Group by player_name
ORDER BY
    tackles_won DESC
LIMIT 10;

-- =============================================
-- Query 7: Top 10 Players by Successful Passes
-- Description: Counts successful passes per player, excluding passes marked as
--              'Incomplete' or 'Out'. Assumes NULL outcome is successful.
-- =============================================
SELECT
    e.possessionEvents.passerPlayerName AS player_name,
    COUNT(*) AS successful_passes
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'PA' -- Filter for Pass events (PA code)
    AND (e.possessionEvents.passOutcomeType IS NULL OR e.possessionEvents.passOutcomeType NOT IN ('Incomplete', 'Out'))
    AND e.possessionEvents.passerPlayerName IS NOT NULL
GROUP BY
    1 -- Group by player_name
ORDER BY
    successful_passes DESC
LIMIT 10;

-- =============================================
-- Query 8: Group Stage Standings
-- Description: Calculates points, goal difference, and goals for each team
--              based *only* on matches played in the group stage (Weeks 1-3).
--              Orders teams as they would appear in a standings table.
-- =============================================
WITH GroupMatchGoals AS (
    -- Step 1: Count goals scored by each team within each GROUP STAGE match.
    SELECT
        e.match_id,
        e.gameEvents.teamId AS team_id,
        COUNT(*) as goals_scored
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    INNER JOIN -- Join with match_metadata to filter by week
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` AS m ON e.match_id = m.id
    WHERE
        e.possessionEvents.possessionEventType = 'SH' -- Filter for Shot events
        AND e.possessionEvents.shotOutcomeType = 'G'  -- Filter for Goal outcomes
        AND e.gameEvents.teamId IS NOT NULL
        AND m.week BETWEEN 1 AND 3 -- *** Filter for Group Stage Weeks ***
    GROUP BY
        1, 2
),
GroupMatchScores AS (
    -- Step 2: Aggregate goals per GROUP STAGE match for home and away teams.
    SELECT
        m.id AS match_id,
        m.homeTeam.name AS home_team_name,
        m.awayTeam.name AS away_team_name,
        m.week, -- Keep week for reference if needed
        COALESCE(SUM(CASE WHEN CAST(mg.team_id AS STRING) = m.homeTeam.id THEN mg.goals_scored ELSE 0 END), 0) as home_score,
        COALESCE(SUM(CASE WHEN CAST(mg.team_id AS STRING) = m.awayTeam.id THEN mg.goals_scored ELSE 0 END), 0) as away_score
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN
        GroupMatchGoals mg ON m.id = mg.match_id
    WHERE
        m.week BETWEEN 1 AND 3 -- *** Filter for Group Stage Weeks ***
    GROUP BY
        1, 2, 3, 4
),
GroupMatchOutcomes AS (
    -- Step 3: Determine points and goals for/against for each team per GROUP STAGE match.
    SELECT
        home_team_name AS team_name,
        home_score AS goals_for,
        away_score AS goals_against,
        CASE
            WHEN home_score > away_score THEN 3 -- Win
            WHEN home_score = away_score THEN 1 -- Draw
            ELSE 0 -- Loss
        END AS points
    FROM GroupMatchScores
    WHERE home_team_name IS NOT NULL
    UNION ALL
    SELECT
        away_team_name AS team_name,
        away_score AS goals_for,
        home_score AS goals_against,
        CASE
            WHEN away_score > home_score THEN 3 -- Win
            WHEN away_score = home_score THEN 1 -- Draw
            ELSE 0 -- Loss
        END AS points
    FROM GroupMatchScores
    WHERE away_team_name IS NOT NULL
)
-- Step 4: Final aggregation for Group Stage Standings.
SELECT
    team_name,
    COUNT(*) AS matches_played,
    SUM(points) AS points,
    SUM(CASE WHEN points = 3 THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN points = 1 THEN 1 ELSE 0 END) AS draws,
    SUM(CASE WHEN points = 0 THEN 1 ELSE 0 END) AS losses,
    SUM(goals_for) AS goals_for,
    SUM(goals_against) AS goals_against,
    SUM(goals_for) - SUM(goals_against) AS goal_difference
FROM
    GroupMatchOutcomes
GROUP BY
    team_name
ORDER BY
    points DESC,           -- Primary sort: Points
    goal_difference DESC,  -- Tie-breaker 1: Goal Difference
    goals_for DESC;        -- Tie-breaker 2: Goals For

-- =============================================
-- Query 9: Top 10 Goalkeepers by Saves
-- Description: Counts saves made by goalkeepers based on 'SH' (Shot) events
--              where the outcome is 'S' (Saved - assumption, check data).
--              Uses the 'keeperPlayerName' field from possessionEvents.
-- =============================================
SELECT
    e.possessionEvents.keeperPlayerName AS goalkeeper_name,
    COUNT(*) AS saves_made
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'SH' -- Filter for Shot events
    AND e.possessionEvents.shotOutcomeType = 'S'  -- *** Filter for 'Saved' outcome (ASSUMPTION - verify 'S' is correct code) ***
    AND e.possessionEvents.keeperPlayerName IS NOT NULL -- Ensure goalkeeper name exists
GROUP BY
    1 -- Group by goalkeeper_name
ORDER BY
    saves_made DESC
LIMIT 10;
