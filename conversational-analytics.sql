-- =============================================================================
-- File: conversational-analytics.sql
-- Description: Views and potentially other SQL artifacts to support
--              Looker Studio Conversational Analytics / Data Agents.
-- Project: FIFA World Cup 2022 GCP Project
-- Author: AI Assistant & User
-- Last Updated: 2025-04-29
-- =============================================================================

-- =============================================
-- View 1: vw_player_tournament_summary
-- Description: Aggregates key player statistics across the tournament and includes
--              K-Means cluster ID for similarity analysis.
-- Purpose: Primary data source for player-focused conversational queries.
-- =============================================

CREATE OR REPLACE VIEW `awesome-advice-420021.fifa_world_cup_2022.vw_player_tournament_summary` AS

WITH PlayerPasses AS (
    -- Aggregate passes per player
    SELECT
        possessionEvents.passerPlayerId AS player_id,
        COUNT(*) AS total_passes,
        -- Assuming NULL or not Incomplete/Out is successful, align with fantasy query
        COUNTIF(e.possessionEvents.passOutcomeType IS NULL OR e.possessionEvents.passOutcomeType NOT IN ('I', 'O')) AS successful_passes
    FROM `awesome-advice-420021.fifa_world_cup_2022.events` e
    WHERE possessionEvents.possessionEventType = 'PA' AND possessionEvents.passerPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerShots AS (
    -- Aggregate shots per player
    SELECT
        possessionEvents.shooterPlayerId AS player_id,
        COUNT(*) AS total_shots,
        COUNTIF(e.possessionEvents.shotOutcomeType = 'G') AS goals_scored,
        COUNTIF(e.possessionEvents.shotOutcomeType IN ('G', 'S')) AS shots_on_target -- Goal or Saved
    FROM `awesome-advice-420021.fifa_world_cup_2022.events` e
    WHERE possessionEvents.possessionEventType = 'SH' AND possessionEvents.shooterPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerTacklesWon AS (
    -- Aggregate successful challenges (tackles) per player
    SELECT
        possessionEvents.challengerPlayerId AS player_id,
        COUNT(*) AS tackles_won -- Keep original name here, will rename in CombinedPlayerStats
    FROM `awesome-advice-420021.fifa_world_cup_2022.events` e
    WHERE possessionEvents.possessionEventType = 'CH' AND possessionEvents.challengeOutcomeType = 'S' AND possessionEvents.challengerPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerSaves AS (
    -- Aggregate saves per player (relevant for GKs)
    SELECT
        possessionEvents.keeperPlayerId AS player_id,
        COUNT(*) AS saves
    FROM `awesome-advice-420021.fifa_world_cup_2022.events` e
    WHERE possessionEvents.possessionEventType = 'SH' AND possessionEvents.shotOutcomeType = 'S' AND possessionEvents.keeperPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerMatchInfo AS (
    -- Get matches played and first team association from rosters
    SELECT
        CAST(player.id AS INT64) AS player_id,
        COUNT(DISTINCT match_id) AS matches_played,
        -- Get the team name associated with the player in their first match (arbitrary choice for simplicity)
        ARRAY_AGG(team.name ORDER BY m.date ASC LIMIT 1)[OFFSET(0)] AS team_name
    FROM `awesome-advice-420021.fifa_world_cup_2022.rosters` r
    JOIN `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m ON r.match_id = m.id
    WHERE player.id IS NOT NULL
    GROUP BY 1
),
CombinedPlayerStats AS (
    -- Combine all stats, using the base players table
    SELECT
        p.id AS player_id,
        p.nickname AS player_name, -- Use nickname as primary display name
        p.positionGroupType AS position_group,
        COALESCE(pmi.team_name, 'Unknown') AS team_name,
        COALESCE(pmi.matches_played, 0) AS matches_played,
        COALESCE(ps.total_shots, 0) AS total_shots,
        COALESCE(ps.goals_scored, 0) AS goals_scored,
        COALESCE(ps.shots_on_target, 0) AS shots_on_target,
        COALESCE(pp.total_passes, 0) AS total_passes,
        COALESCE(pp.successful_passes, 0) AS successful_passes,
        SAFE_DIVIDE(COALESCE(pp.successful_passes, 0), COALESCE(pp.total_passes, 1)) AS pass_completion_rate, -- Avoid divide by zero
        -- Rename tackles_won here to match the model's expected feature name
        COALESCE(ptw.tackles_won, 0) AS total_challenges_won,
        COALESCE(psv.saves, 0) AS saves
    FROM `awesome-advice-420021.fifa_world_cup_2022.players` p
    LEFT JOIN PlayerMatchInfo pmi ON p.id = pmi.player_id
    LEFT JOIN PlayerPasses pp ON p.id = pp.player_id
    LEFT JOIN PlayerShots ps ON p.id = ps.player_id
    LEFT JOIN PlayerTacklesWon ptw ON p.id = ptw.player_id
    LEFT JOIN PlayerSaves psv ON p.id = psv.player_id
)
-- Final SELECT: Add cluster ID using ML.PREDICT
SELECT
    s.*,
    pred.centroid_id AS player_cluster_id
FROM CombinedPlayerStats s
JOIN ML.PREDICT(MODEL `awesome-advice-420021.fifa_world_cup_2022.player_clusters_kmeans`, (
    -- Select the features the K-Means model expects, using the correct name
    SELECT
        player_id,
        total_passes,
        total_shots,
        total_challenges_won -- Use the corrected name here
    FROM CombinedPlayerStats
)) pred ON s.player_id = pred.player_id;

-- Note: The team_name is based on the player's first recorded match roster in this dataset.
-- Consider refining team logic if players switch teams mid-dataset.
