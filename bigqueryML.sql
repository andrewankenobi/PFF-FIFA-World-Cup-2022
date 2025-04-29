-- =============================================================================
-- File: bigqueryML.sql
-- Description: BigQuery ML model creation examples for the FIFA World Cup 2022 dataset.
-- Project: FIFA World Cup 2022 GCP Project
-- Author: AI Assistant & User
-- Last Updated: 2025-04-29
-- =============================================================================
-- Notes:
--   * These are example models and may require further tuning and feature engineering.
--   * Assumes the dataset 'fifa_world_cup_2022' in project 'awesome-advice-420021'.
--   * Training these models will incur BigQuery processing costs.
-- =============================================================================

-- =============================================
-- Model 1: Predict Match Outcome (Logistic Regression) [Corrected v2]
-- Description: Creates a model to predict the match outcome (Home Win, Away Win, Draw)
--              based on aggregated in-match stats per team.
-- Model Type: Logistic Regression (suited for multi-class classification)
-- Label: match_outcome (Categorical: 'HomeWin', 'AwayWin', 'Draw')
-- Features: home_shots, away_shots, home_passes, away_passes
-- Correction: Moved aggregation logic. Added CAST for team ID comparison.
-- =============================================

CREATE OR REPLACE MODEL `awesome-advice-420021.fifa_world_cup_2022.match_outcome_logistic_reg`
TRANSFORM(
  -- TRANSFORM now just selects the pre-aggregated features the model needs.
  home_shots,
  away_shots,
  home_passes,
  away_passes,
  match_outcome -- Pass the already computed label to the model
)
OPTIONS(
  model_type='LOGISTIC_REG', -- Use Logistic Regression for classification
  input_label_cols=['match_outcome'] -- Specify the target variable column
)
AS
-- The main SELECT query now aggregates features and computes the label per match.
WITH MatchAggregates AS (
  SELECT
    e.match_id,
    -- Aggregate Features (CAST teamId to STRING for comparison)
    SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id AND e.possessionEvents.possessionEventType = 'SH' THEN 1 ELSE 0 END) AS home_shots,
    SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id AND e.possessionEvents.possessionEventType = 'SH' THEN 1 ELSE 0 END) AS away_shots,
    SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id AND e.possessionEvents.possessionEventType = 'PA' THEN 1 ELSE 0 END) AS home_passes,
    SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id AND e.possessionEvents.possessionEventType = 'PA' THEN 1 ELSE 0 END) AS away_passes,
    -- Calculate goals for label determination (CAST teamId to STRING for comparison)
    SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id AND e.possessionEvents.possessionEventType = 'SH' AND e.possessionEvents.shotOutcomeType = 'G' THEN 1 ELSE 0 END) as home_goals,
    SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id AND e.possessionEvents.possessionEventType = 'SH' AND e.possessionEvents.shotOutcomeType = 'G' THEN 1 ELSE 0 END) as away_goals
  FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` e
  JOIN
    `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m ON e.match_id = m.id
  WHERE
      -- Only include relevant event types for feature/label calculation
      e.possessionEvents.possessionEventType IN ('SH', 'PA')
      AND e.gameEvents.teamId IS NOT NULL -- Ensure team ID exists for attribution
      AND (m.homeTeam.id IS NOT NULL AND m.awayTeam.id IS NOT NULL) -- Ensure team IDs exist in metadata
  GROUP BY
      e.match_id, m.homeTeam.id, m.awayTeam.id -- Group by match to aggregate stats
)
-- Select the features and compute the label for the final training data
SELECT
  home_shots,
  away_shots,
  home_passes,
  away_passes,
  CASE
    WHEN home_goals > away_goals THEN 'HomeWin'
    WHEN home_goals < away_goals THEN 'AwayWin'
    ELSE 'Draw'
  END AS match_outcome
FROM MatchAggregates;

-- Note: The above model uses in-match stats to predict the outcome of the *same* match.
-- This is primarily for demonstrating BQML syntax. A more predictive model would typically
-- use features known *before* the match (e.g., historical stats, team rankings).

-- =============================================
-- Model 2: Cluster Players (K-Means)
-- Description: Groups players into clusters based on aggregated actions.
-- Model Type: K-Means (suited for unsupervised clustering)
-- Features: total_passes, total_shots, total_challenges_won
-- =============================================

CREATE OR REPLACE MODEL `awesome-advice-420021.fifa_world_cup_2022.player_clusters_kmeans`
TRANSFORM(
    -- Select features for clustering
    total_passes,
    total_shots,
    total_challenges_won
    -- player_id and player_name are excluded from clustering features but kept for identification
)
OPTIONS(
  model_type='KMEANS',           -- Use K-Means for clustering
  num_clusters=5,                 -- Specify the desired number of clusters (can be tuned)
  standardize_features=TRUE     -- Recommended for K-Means when features have different scales
)
AS
WITH PlayerActions AS (
    -- Aggregate passes per player
    SELECT
        possessionEvents.passerPlayerId AS player_id,
        possessionEvents.passerPlayerName AS player_name,
        COUNT(*) AS passes
    FROM `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE possessionEvents.possessionEventType = 'PA' AND possessionEvents.passerPlayerId IS NOT NULL
    GROUP BY 1, 2
),
PlayerShots AS (
    -- Aggregate shots per player
    SELECT
        possessionEvents.shooterPlayerId AS player_id,
        COUNT(*) AS shots
    FROM `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE possessionEvents.possessionEventType = 'SH' AND possessionEvents.shooterPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerChallengesWon AS (
    -- Aggregate successful challenges per player
    SELECT
        possessionEvents.challengerPlayerId AS player_id,
        COUNT(*) AS challenges_won
    FROM `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE possessionEvents.possessionEventType = 'CH' AND possessionEvents.challengeOutcomeType = 'S' AND possessionEvents.challengerPlayerId IS NOT NULL
    GROUP BY 1
)
-- Combine aggregated stats per player
SELECT
    pa.player_id,
    pa.player_name,
    COALESCE(pa.passes, 0) AS total_passes,
    COALESCE(ps.shots, 0) AS total_shots,
    COALESCE(pcw.challenges_won, 0) AS total_challenges_won
FROM PlayerActions pa
LEFT JOIN PlayerShots ps ON pa.player_id = ps.player_id
LEFT JOIN PlayerChallengesWon pcw ON pa.player_id = pcw.player_id;

-- Note: This K-Means model groups players based on raw action counts.
-- Feature engineering (e.g., stats per 90 mins) or adding more features
-- (dribbles, interceptions, etc.) could yield more insightful clusters.

-- =============================================================================
-- Model 3: Predict Goal Likelihood (Logistic Regression) [Corrected v3]
-- Description: Predicts if a shot is likely to be a goal based on event characteristics.
-- Model Type: Logistic Regression (Binary Classification)
-- Label: is_goal (BOOL)
-- Features: shotType, shotNatureType, bodyMovementType, ballMoving, pressureType
-- Correction: Calculate label in AS SELECT, pass by name to TRANSFORM.
-- =============================================================================

CREATE OR REPLACE MODEL `awesome-advice-420021.fifa_world_cup_2022.goal_likelihood_logistic_reg`
TRANSFORM(
    -- Select the features passed from the main query
    shotType,
    shotNatureType,
    bodyMovementType,
    ballMoving,
    pressureType,
    -- Select the pre-calculated label passed from the main query
    is_goal
)
OPTIONS(
    model_type='LOGISTIC_REG',
    input_label_cols=['is_goal'], -- Specify the target variable column
    auto_class_weights=TRUE -- Useful for imbalanced datasets (likely few goals)
)
AS
-- The main SELECT query now explicitly selects the simple fields AND calculates the label.
SELECT
    possessionEvents.shotType,
    possessionEvents.shotNatureType,
    possessionEvents.bodyMovementType,
    possessionEvents.ballMoving,
    possessionEvents.pressureType,
    -- Calculate the label directly in the main query
    (possessionEvents.shotOutcomeType = 'G') AS is_goal
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events`
WHERE
    possessionEvents.possessionEventType = 'SH' -- Only train on Shot events
    AND possessionEvents.shotOutcomeType IS NOT NULL; -- Ensure outcome is known

-- Note: This model uses limited features. Adding shot location (x,y),
-- distance/angle to goal, and keeper position would likely improve performance significantly.

-- =============================================================================
-- Model 4: Classify Player Role (Logistic Regression) [Corrected]
-- Description: Predicts a player's primary position based on aggregated actions.
-- Model Type: Logistic Regression (Multi-class classification)
-- Label: positionGroupType (from players table)
-- Features: total_passes, total_shots, total_challenges_won
-- Correction: Use output column name in TRANSFORM, not alias.p.
-- =============================================================================

CREATE OR REPLACE MODEL `awesome-advice-420021.fifa_world_cup_2022.player_role_logistic_reg`
TRANSFORM(
    -- Select the aggregated features
    total_passes,
    total_shots,
    total_challenges_won,
    -- Select the label by its output column name
    positionGroupType
)
OPTIONS(
    model_type='LOGISTIC_REG',
    input_label_cols=['positionGroupType'] -- Specify the target variable column
)
AS
WITH PlayerActions AS (
    -- Aggregate passes per player
    SELECT
        possessionEvents.passerPlayerId AS player_id,
        COUNT(*) AS passes
    FROM `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE possessionEvents.possessionEventType = 'PA' AND possessionEvents.passerPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerShots AS (
    -- Aggregate shots per player
    SELECT
        possessionEvents.shooterPlayerId AS player_id,
        COUNT(*) AS shots
    FROM `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE possessionEvents.possessionEventType = 'SH' AND possessionEvents.shooterPlayerId IS NOT NULL
    GROUP BY 1
),
PlayerChallengesWon AS (
    -- Aggregate successful challenges per player
    SELECT
        possessionEvents.challengerPlayerId AS player_id,
        COUNT(*) AS challenges_won
    FROM `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE possessionEvents.possessionEventType = 'CH' AND possessionEvents.challengeOutcomeType = 'S' AND possessionEvents.challengerPlayerId IS NOT NULL
    GROUP BY 1
)
-- Combine aggregated stats and join with players table for the label
SELECT
    COALESCE(pa.passes, 0) AS total_passes,
    COALESCE(ps.shots, 0) AS total_shots,
    COALESCE(pcw.challenges_won, 0) AS total_challenges_won,
    p.positionGroupType -- Label from the players table (output column is named positionGroupType)
FROM `awesome-advice-420021.fifa_world_cup_2022.players` p
-- Use player_id from players table as the primary key
LEFT JOIN PlayerActions pa ON p.id = pa.player_id
LEFT JOIN PlayerShots ps ON p.id = ps.player_id
LEFT JOIN PlayerChallengesWon pcw ON p.id = pcw.player_id
WHERE p.positionGroupType IS NOT NULL; -- Ensure player has a known position

-- Note: Uses the primary position from the players table. Accuracy might be affected
-- by players who played different roles across matches if only one role is listed.

-- =============================================================================
-- Testing Queries (Run AFTER models finish training)
-- =============================================================================

-- ============================
-- Model 1: Match Outcome Evaluation
-- ============================
SELECT * FROM ML.EVALUATE(MODEL `awesome-advice-420021.fifa_world_cup_2022.match_outcome_logistic_reg`);

-- ============================
-- Model 1: Match Outcome Prediction (Sample)
-- ============================
SELECT * FROM ML.PREDICT(MODEL `awesome-advice-420021.fifa_world_cup_2022.match_outcome_logistic_reg`, (
    -- Reuse the same input query structure used for training
    WITH MatchAggregates AS (
      SELECT
        e.match_id,
        SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id AND e.possessionEvents.possessionEventType = 'SH' THEN 1 ELSE 0 END) AS home_shots,
        SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id AND e.possessionEvents.possessionEventType = 'SH' THEN 1 ELSE 0 END) AS away_shots,
        SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id AND e.possessionEvents.possessionEventType = 'PA' THEN 1 ELSE 0 END) AS home_passes,
        SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id AND e.possessionEvents.possessionEventType = 'PA' THEN 1 ELSE 0 END) AS away_passes,
        SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.homeTeam.id AND e.possessionEvents.possessionEventType = 'SH' AND e.possessionEvents.shotOutcomeType = 'G' THEN 1 ELSE 0 END) as home_goals,
        SUM(CASE WHEN CAST(e.gameEvents.teamId AS STRING) = m.awayTeam.id AND e.possessionEvents.possessionEventType = 'SH' AND e.possessionEvents.shotOutcomeType = 'G' THEN 1 ELSE 0 END) as away_goals
      FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` e
      JOIN
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m ON e.match_id = m.id
      WHERE
          e.possessionEvents.possessionEventType IN ('SH', 'PA')
          AND e.gameEvents.teamId IS NOT NULL
          AND (m.homeTeam.id IS NOT NULL AND m.awayTeam.id IS NOT NULL)
      GROUP BY
          e.match_id, m.homeTeam.id, m.awayTeam.id
    )
    SELECT
      match_id, -- Include match_id to identify predictions
      home_shots,
      away_shots,
      home_passes,
      away_passes,
      CASE
        WHEN home_goals > away_goals THEN 'HomeWin'
        WHEN home_goals < away_goals THEN 'AwayWin'
        ELSE 'Draw'
      END AS actual_outcome -- Compare prediction with actual
    FROM MatchAggregates
    LIMIT 10
));

-- ============================
-- Model 2: Player Clusters Evaluation (Centroid Info)
-- ============================
SELECT * FROM ML.CENTROIDS(MODEL `awesome-advice-420021.fifa_world_cup_2022.player_clusters_kmeans`);

-- ============================
-- Model 2: Player Clusters Prediction (Sample)
-- ============================
SELECT * FROM ML.PREDICT(MODEL `awesome-advice-420021.fifa_world_cup_2022.player_clusters_kmeans`, (
    -- Reuse the same input query structure used for training
    WITH PlayerActions AS (
        SELECT possessionEvents.passerPlayerId AS player_id, possessionEvents.passerPlayerName AS player_name, COUNT(*) AS passes
        FROM `awesome-advice-420021.fifa_world_cup_2022.events`
        WHERE possessionEvents.possessionEventType = 'PA' AND possessionEvents.passerPlayerId IS NOT NULL GROUP BY 1, 2
    ), PlayerShots AS (
        SELECT possessionEvents.shooterPlayerId AS player_id, COUNT(*) AS shots
        FROM `awesome-advice-420021.fifa_world_cup_2022.events`
        WHERE possessionEvents.possessionEventType = 'SH' AND possessionEvents.shooterPlayerId IS NOT NULL GROUP BY 1
    ), PlayerChallengesWon AS (
        SELECT possessionEvents.challengerPlayerId AS player_id, COUNT(*) AS challenges_won
        FROM `awesome-advice-420021.fifa_world_cup_2022.events`
        WHERE possessionEvents.possessionEventType = 'CH' AND possessionEvents.challengeOutcomeType = 'S' AND possessionEvents.challengerPlayerId IS NOT NULL GROUP BY 1
    )
    SELECT
        pa.player_id,
        pa.player_name,
        COALESCE(pa.passes, 0) AS total_passes,
        COALESCE(ps.shots, 0) AS total_shots,
        COALESCE(pcw.challenges_won, 0) AS total_challenges_won
    FROM PlayerActions pa
    LEFT JOIN PlayerShots ps ON pa.player_id = ps.player_id
    LEFT JOIN PlayerChallengesWon pcw ON pa.player_id = pcw.player_id
    LIMIT 50 -- Predict for a sample of players
));

-- ============================
-- Model 3: Goal Likelihood Evaluation
-- ============================
SELECT * FROM ML.EVALUATE(MODEL `awesome-advice-420021.fifa_world_cup_2022.goal_likelihood_logistic_reg`);

-- ============================
-- Model 3: Goal Likelihood Prediction (Sample)
-- ============================
SELECT * FROM ML.PREDICT(MODEL `awesome-advice-420021.fifa_world_cup_2022.goal_likelihood_logistic_reg`, (
    SELECT
        possessionEvents,
        (possessionEvents.shotOutcomeType = 'G') AS actual_is_goal -- For comparison
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events`
    WHERE
        possessionEvents.possessionEventType = 'SH'
        AND possessionEvents.shotOutcomeType IS NOT NULL
    LIMIT 100 -- Predict on a sample of shots
));

-- ============================
-- Model 4: Player Role Evaluation
-- ============================
SELECT * FROM ML.EVALUATE(MODEL `awesome-advice-420021.fifa_world_cup_2022.player_role_logistic_reg`);

-- ============================
-- Model 4: Player Role Prediction (Sample)
-- ============================
SELECT * FROM ML.PREDICT(MODEL `awesome-advice-420021.fifa_world_cup_2022.player_role_logistic_reg`, (
    -- Reuse the same input query structure used for training
    WITH PlayerActions AS (
        SELECT possessionEvents.passerPlayerId AS player_id, COUNT(*) AS passes
        FROM `awesome-advice-420021.fifa_world_cup_2022.events`
        WHERE possessionEvents.possessionEventType = 'PA' AND possessionEvents.passerPlayerId IS NOT NULL GROUP BY 1
    ), PlayerShots AS (
        SELECT possessionEvents.shooterPlayerId AS player_id, COUNT(*) AS shots
        FROM `awesome-advice-420021.fifa_world_cup_2022.events`
        WHERE possessionEvents.possessionEventType = 'SH' AND possessionEvents.shooterPlayerId IS NOT NULL GROUP BY 1
    ), PlayerChallengesWon AS (
        SELECT possessionEvents.challengerPlayerId AS player_id, COUNT(*) AS challenges_won
        FROM `awesome-advice-420021.fifa_world_cup_2022.events`
        WHERE possessionEvents.possessionEventType = 'CH' AND possessionEvents.challengeOutcomeType = 'S' AND possessionEvents.challengerPlayerId IS NOT NULL GROUP BY 1
    )
    SELECT
        p.nickname, -- Show player name for context
        COALESCE(pa.passes, 0) AS total_passes,
        COALESCE(ps.shots, 0) AS total_shots,
        COALESCE(pcw.challenges_won, 0) AS total_challenges_won,
        p.positionGroupType AS actual_positionGroupType -- For comparison
    FROM `awesome-advice-420021.fifa_world_cup_2022.players` p
    LEFT JOIN PlayerActions pa ON p.id = pa.player_id
    LEFT JOIN PlayerShots ps ON p.id = ps.player_id
    LEFT JOIN PlayerChallengesWon pcw ON p.id = pcw.player_id
    WHERE p.positionGroupType IS NOT NULL
    LIMIT 50 -- Predict for a sample of players
));

