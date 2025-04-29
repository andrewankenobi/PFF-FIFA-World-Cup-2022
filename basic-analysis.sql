--events per match
SELECT
    match_id, -- Assuming an event_id or similar column exists in events
    COUNT(*) AS total_events
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events`
GROUP BY
    match_id
ORDER BY
    total_events DESC;

---players per team 
SELECT distinct
  players.firstName,
  players.lastName,
  rosters.team.name
FROM
  `awesome-advice-420021`.`fifa_world_cup_2022`.`players` AS players
INNER JOIN
  `awesome-advice-420021`.`fifa_world_cup_2022`.`rosters` AS rosters
ON
  CAST(players.id AS STRING) = rosters.player.id
order by 3,2;


-- This query should Get match details with competition information:
SELECT
    match_metadata.id AS match_id,
    match_metadata.date AS match_date,
    match_metadata.homeTeam.id AS home_team_id,
    match_metadata.homeTeam.name AS home_team_name,
    match_metadata.homeTeam.shortName AS home_team_short_name,
    match_metadata.awayTeam.id AS away_team_id,
    match_metadata.awayTeam.name AS away_team_name,
    match_metadata.awayTeam.shortName AS away_team_short_name,
    match_metadata.season AS season,
    match_metadata.week AS week,
    match_metadata.stadium.id AS stadium_id,
    match_metadata.stadium.name AS stadium_name,
    match_metadata.fps AS video_fps,
    match_metadata.videoUrl AS video_url,
    competitions.name AS competition_name
FROM
    `awesome-advice-420021`.`fifa_world_cup_2022`.`match_metadata` AS match_metadata
INNER JOIN
    `awesome-advice-420021`.`fifa_world_cup_2022`.`competitions` AS competitions
ON
    match_metadata.competition.id = CAST(competitions.id AS STRING)
LIMIT 10;


-- Query to find the top 10 goal scorers
SELECT
    e.possessionEvents.shooterPlayerName AS player_name,
    COUNT(*) AS goals_scored
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'Shot' 
    AND e.possessionEvents.shotOutcomeType = 'Goal' 
    AND e.possessionEvents.shooterPlayerName IS NOT NULL
GROUP BY
    1 -- Group by player_name
ORDER BY
    goals_scored DESC
LIMIT 10;


-- Query to calculate Wins, Draws, Losses for each team (Corrected - derives score from events)
WITH MatchGoals AS (
    -- Count goals for each shooter in each match
    SELECT
        e.match_id,
        e.possessionEvents.shooterPlayerId AS shooter_player_id, -- Use shooter ID
        COUNT(*) as goals_scored
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.events` AS e
    WHERE
        e.possessionEvents.possessionEventType = 'Shot' 
        AND e.possessionEvents.shotOutcomeType = 'Goal'
        AND e.possessionEvents.shooterPlayerId IS NOT NULL -- Ensure shooter ID is available
    GROUP BY
        1, 2
),
MatchScores AS (
    -- Combine goals with match metadata and rosters to get home/away scores
    SELECT
        m.id AS match_id,
        m.homeTeam.name AS home_team_name,
        m.awayTeam.name AS away_team_name,
        -- Join MatchGoals with rosters to get team_id, then compare
        COALESCE(SUM(CASE WHEN r.team.id = m.homeTeam.id THEN mg.goals_scored ELSE 0 END), 0) as home_score,
        COALESCE(SUM(CASE WHEN r.team.id = m.awayTeam.id THEN mg.goals_scored ELSE 0 END), 0) as away_score
    FROM
        `awesome-advice-420021.fifa_world_cup_2022.match_metadata` m
    LEFT JOIN 
        MatchGoals mg ON m.id = mg.match_id
    LEFT JOIN 
        `awesome-advice-420021.fifa_world_cup_2022.rosters` r 
        ON mg.match_id = r.match_id AND CAST(mg.shooter_player_id AS STRING) = r.player.id -- Join roster to get team of shooter
    GROUP BY
        1, 2, 3
),
MatchOutcomes AS (
    -- Determine winner/loser based on derived scores
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
    -- Unpivot results to get one row per team outcome
    SELECT home_team_name AS team_name, 
           CASE WHEN winner = home_team_name THEN 'Win' WHEN winner = 'Draw' THEN 'Draw' ELSE 'Loss' END AS result_type
    FROM MatchOutcomes
    UNION ALL
    SELECT away_team_name AS team_name, 
           CASE WHEN winner = away_team_name THEN 'Win' WHEN winner = 'Draw' THEN 'Draw' ELSE 'Loss' END AS result_type
    FROM MatchOutcomes
)
-- Final aggregation of Wins, Draws, Losses
SELECT
    team_name,
    COUNTIF(result_type = 'Win') AS wins,
    COUNTIF(result_type = 'Draw') AS draws,
    COUNTIF(result_type = 'Loss') AS losses
FROM
    TeamResults
WHERE team_name IS NOT NULL -- Filter out any potential null team names
GROUP BY
    team_name
ORDER BY
    wins DESC, draws DESC, losses ASC;


-- Query to find the top 10 players by successful tackles (Replaces Assists)
-- Note: This interprets a won 'Challenge' as a successful tackle.
SELECT
    e.possessionEvents.challengerPlayerName AS player_name,
    COUNT(*) AS tackles_won
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'Challenge' 
    AND e.possessionEvents.challengeOutcomeType = 'Won'
    AND e.possessionEvents.challengerPlayerName IS NOT NULL
GROUP BY
    1 -- Group by player_name
ORDER BY
    tackles_won DESC
LIMIT 10;


-- Query to find the top 10 players by successful passes (Corrected for new schema)
SELECT
    e.possessionEvents.passerPlayerName AS player_name,
    COUNT(*) AS successful_passes
FROM
    `awesome-advice-420021.fifa_world_cup_2022.events` AS e
WHERE
    e.possessionEvents.possessionEventType = 'Pass' 
    AND e.possessionEvents.passOutcomeType NOT IN ('Incomplete', 'Out') -- Assumes other outcomes (like NULL) are successful
    AND e.possessionEvents.passerPlayerName IS NOT NULL
GROUP BY
    1 -- Group by player_name
ORDER BY
    successful_passes DESC
LIMIT 10;