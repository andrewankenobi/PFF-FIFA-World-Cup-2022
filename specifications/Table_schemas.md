# BigQuery Table Schemas for FIFA World Cup 2022 Analysis

This document details the schemas for the BigQuery tables used in the FIFA World Cup 2022 analysis project, derived from `specifications-table_schemas.csv`. It provides a detailed, descriptive overview of each table and its columns, including the structure of nested fields.

---

## Table: `competitions`

Stores information about the competitions included in the dataset.

| Column Name | Data Type | Description |
|---|---|---|
| `games` | `STRING` | Identifier or list related to games within the competition. |
| `id` | `INT64` | Unique numerical identifier for the competition. |
| `name` | `STRING` | The name of the competition (e.g., "FIFA World Cup"). |

---

## Table: `events`

This is a core table containing granular, time-stamped event data for each match. Each row often represents a specific action or observation within a possession or game event.

| Column Name | Data Type | Description |
|---|---|---|
| `match_id` | `STRING` | Identifier linking the event to a specific match in `match_metadata`. |
| `gameId` | `INT64` | Game identifier, potentially synonymous with `match_id` but numerical. |
| `gameEventId` | `INT64` | Unique identifier for a broader game event (e.g., a player's entire possession). |
| `possessionEventId` | `INT64` | Unique identifier for a specific action within a game event (e.g., a pass, shot, tackle). |
| `startTime` | `FLOAT64` | Start time of the event in seconds (likely relative to match/period start). |
| `endTime` | `FLOAT64` | End time of the event in seconds. |
| `duration` | `FLOAT64` | Duration of the event in seconds (`endTime` - `startTime`). |
| `eventTime` | `FLOAT64` | Specific timestamp associated with the event, possibly the key moment. |
| `gameEvents` | `STRUCT` | Details about game-level events.<br> - `gameEventType`: `STRING` (Type of game event: KICKOFF, END, G, OFF, ON, OTB, OUT, SUB, VID, etc.)<br> - `initialNonEvent`: `BOOL`<br> - `startGameClock`: `FLOAT64`<br> - `startFormattedGameClock`: `STRING`<br> - `period`: `INT64`<br> - `videoMissing`: `BOOL`<br> - `teamId`: `INT64`<br> - `teamName`: `STRING`<br> - `playerId`: `INT64`<br> - `playerName`: `STRING`<br> - `touches`: `INT64`<br> - `touchesInBox`: `INT64`<br> - `setpieceType`: `STRING`<br> - `earlyDistribution`: `BOOL`<br> - `videoUrl`: `STRING`<br> - `endType`: `STRING`<br> - `outType`: `STRING`<br> - `subType`: `STRING`<br> - `playerOffId`: `INT64`<br> - `playerOffName`: `STRING`<br> - `playerOffType`: `STRING`<br> - `playerOnId`: `INT64`<br> - `playerOnName`: `STRING` |
| `initialTouch` | `STRUCT` | Details describing the initial touch a player takes.<br> - `initialBodyType`: `STRING`<br> - `initialHeightType`: `STRING`<br> - `facingType`: `STRING`<br> - `initialTouchType`: `STRING`<br> - `initialPressureType`: `STRING`<br> - `initialPressurePlayerId`: `INT64`<br> - `initialPressurePlayerName`: `STRING` |
| `possessionEvents` | `STRUCT` | **Crucial Field:** Details describing the specific action performed during a possession.<br> - `possessionEventType`: `STRING` (Type of possession event: BC, CH, CL, CR, PA, RE, SH)<br> - `nonEvent`: `BOOL`<br> - `gameClock`: `FLOAT64`<br> - `formattedGameClock`: `STRING`<br> - `eventVideoUrl`: `STRING`<br> - `ballHeightType`: `STRING`<br> - `bodyType`: `STRING`<br> - `highPointType`: `STRING`<br> _Pass Fields:_<br> - `passerPlayerId`: `INT64`<br> - `passerPlayerName`: `STRING`<br> - `passType`: `STRING`<br> - `passOutcomeType`: `STRING`<br> _Cross Fields:_<br> - `crosserPlayerId`: `INT64`<br> - `crosserPlayerName`: `STRING`<br> - `crossType`: `STRING`<br> - `crossZoneType`: `STRING`<br> - `crossOutcomeType`: `STRING`<br> _Reception/Target Fields:_<br> - `targetPlayerId`: `INT64`<br> - `targetPlayerName`: `STRING`<br> - `targetFacingType`: `STRING`<br> - `receiverPlayerId`: `INT64`<br> - `receiverPlayerName`: `STRING`<br> - `receiverFacingType`: `STRING`<br> _Defense/Interference Fields:_<br> - `defenderPlayerId`: `INT64`<br> - `defenderPlayerName`: `STRING`<br> - `blockerPlayerId`: `INT64`<br> - `blockerPlayerName`: `STRING`<br> - `deflectorPlayerId`: `INT64`<br> - `deflectorPlayerName`: `STRING`<br> - `failedBlockerPlayerId`: `INT64`<br> - `failedBlockerPlayerName`: `STRING`<br> - ... (additional failed blockers)<br> _Pass/Shot Details:_<br> - `accuracyType`: `STRING`<br> - `incompletionReasonType`: `STRING`<br> - `secondIncompletionReasonType`: `STRING`<br> - `linesBrokenType`: `STRING`<br> _Shot Fields:_<br> - `shooterPlayerId`: `INT64`<br> - `shooterPlayerName`: `STRING`<br> - `bodyMovementType`: `STRING`<br> - `ballMoving`: `BOOL`<br> - `shotType`: `STRING`<br> - `shotNatureType`: `STRING`<br> - `shotInitialHeightType`: `STRING`<br> - `shotOutcomeType`: `STRING` (e.g., 'G' for Goal, 'S' for Saved)<br> _Goalkeeper Fields:_<br> - `keeperPlayerId`: `INT64`<br> - `keeperPlayerName`: `STRING`<br> - `saveHeightType`: `STRING`<br> - `saveReboundType`: `STRING`<br> - `keeperTouchType`: `STRING`<br> - `badParry`: `BOOL`<br> - `saveable`: `BOOL`<br> _Clearance Fields:_<br> - `glClearerPlayerId`: `INT64`<br> - `glClearerPlayerName`: `STRING`<br> - `clearerPlayerId`: `INT64`<br> - `clearerPlayerName`: `STRING`<br> - `clearanceOutcomeType`: `STRING`<br> _Carry/Dribble Fields:_<br> - `carrierPlayerId`: `INT64`<br> - `carrierPlayerName`: `STRING`<br> - `dribblerPlayerId`: `INT64`<br> - `dribblerPlayerName`: `STRING`<br> - `carryType`: `STRING`<br> - `ballCarryOutcome`: `STRING`<br> - `carryDefenderPlayerId`: `INT64`<br> - `carryDefenderPlayerName`: `STRING`<br> - `carryIntent`: `STRING`<br> - `carrySuccessful`: `BOOL`<br> _Challenge/Duel Fields:_<br> - `challengeType`: `STRING`<br> - `dribbleType`: `STRING`<br> - `tackleAttemptType`: `STRING`<br> - `trickType`: `STRING`<br> - `challengerPlayerId`: `INT64`<br> - `challengerPlayerName`: `STRING`<br> - ... (additional challengers, duelers)<br> - `challengeKeeperPlayerId`: `INT64`<br> - `challengeKeeperPlayerName`: `STRING`<br> - `challengeWinnerPlayerId`: `INT64`<br> - `challengeWinnerPlayerName`: `STRING`<br> - `challengeOutcomeType`: `STRING` (e.g., 'S' for Successful/Won)<br> _Touch/Rebound Fields:_<br> - `ballCarrierPlayerId`: `INT64`<br> - `ballCarrierPlayerName`: `STRING`<br> - `touchPlayerId`: `INT64`<br> - `touchPlayerName`: `STRING`<br> - `touchType`: `STRING`<br> - `touchOutcomeType`: `STRING`<br> - `rebounderPlayerId`: `INT64`<br> - `rebounderPlayerName`: `STRING`<br> - `originateType`: `STRING`<br> - `reboundOutcomeType`: `STRING`<br> - `missedTouchType`: `STRING`<br> - `missedTouchPlayerId`: `INT64`<br> - `missedTouchPlayerName`: `STRING`<br> _Pressure/Opportunity Fields:_<br> - `pressureType`: `STRING`<br> - `pressurePlayerId`: `INT64`<br> - `pressurePlayerName`: `STRING`<br> - `opportunityType`: `STRING`<br> - `betterOptionType`: `STRING`<br> - `betterOptionTime`: `FLOAT64`<br> - `betterOptionPlayerId`: `INT64`<br> - `betterOptionPlayerName`: `STRING`<br> _Spatial/Positional Fields:_<br> - `createsSpace`: `BOOL`<br> - `csPlayerId`: `INT64`<br> - `csPlayerName`: `STRING`<br> - `csGrade`: `STRING`<br> - ... (multiple positionPlayer fields)<br> - ... (multiple closingDownPlayer fields)<br> - ... (multiple movementPlayer fields)<br> - ... (multiple disciplinePlayer fields)<br> - ... (multiple failed action player fields) |
| `fouls` | `STRUCT` | Details about any foul associated with the event.<br> - `onFieldCulpritPlayerId`: `INT64`<br> - `onFieldCulpritPlayerName`: `STRING`<br> - `finalCulpritPlayerId`: `INT64`<br> - `finalCulpritPlayerName`: `STRING`<br> - `victimPlayerId`: `INT64`<br> - `victimPlayerName`: `STRING`<br> - `foulType`: `STRING`<br> - `onFieldOffenseType`: `STRING`<br> - `finalOffenseType`: `STRING`<br> - `onFieldFoulOutcomeType`: `STRING`<br> - `finalFoulOutcomeType`: `STRING`<br> - `var`: `BOOL`<br> - `varReasonType`: `STRING`<br> - `correctDecision`: `BOOL` |
| `grades` | `STRUCT` | Performance grades assigned to players involved in the event.<br> - `additionalDuelerGrade`: `FLOAT64`<br> - `additionalDueler2Grade`: `FLOAT64`<br> - `awayDuelGrade`: `FLOAT64`<br> - `ballCarrierGrade`: `FLOAT64`<br> - `blockerGrade`: `FLOAT64`<br> - `carrierGrade`: `FLOAT64`<br> - `carryDefenderGrade`: `FLOAT64`<br> - `challengerGrade`: `FLOAT64`<br> - `challenger2Grade`: `FLOAT64`<br> - `challengeKeeperGrade`: `FLOAT64`<br> - `clearerGrade`: `FLOAT64`<br> - `glClearerGrade`: `FLOAT64`<br> - `closingDownGrade`: `FLOAT64`<br> - `closingDown2Grade`: `FLOAT64`<br> - `crosserGrade`: `FLOAT64`<br> - `csGrade`: `STRING`<br> - `dabGrade`: `FLOAT64`<br> - `dab2Grade`: `FLOAT64`<br> - `defenderGrade`: `FLOAT64`<br> - `deflectorGrade`: `FLOAT64`<br> - `disciplineGrade`: `FLOAT64`<br> - `discipline2Grade`: `FLOAT64`<br> - `discipline3Grade`: `FLOAT64`<br> - `dribblerGrade`: `FLOAT64`<br> - `failedBlockerGrade`: `FLOAT64`<br> - `failedBlocker2Grade`: `FLOAT64`<br> - `failedBlocker3Grade`: `FLOAT64`<br> - `failedClearerGrade`: `FLOAT64`<br> - `failedCrosserGrade`: `FLOAT64`<br> - `failedPasserGrade`: `FLOAT64`<br> - `failedShooterGrade`: `FLOAT64`<br> - `homeDuelGrade`: `FLOAT64`<br> - `keeperGrade`: `FLOAT64`<br> - `movementGrade`: `FLOAT64`<br> - `movement2Grade`: `FLOAT64`<br> - `movement3Grade`: `FLOAT64`<br> - `passerGrade`: `FLOAT64`<br> - `positionGrade`: `FLOAT64`<br> - `position2Grade`: `FLOAT64`<br> - `position3Grade`: `FLOAT64`<br> - `position4Grade`: `FLOAT64`<br> - `position5Grade`: `FLOAT64`<br> - `receiverGrade`: `FLOAT64`<br> - `shooterGrade`: `FLOAT64`<br> - `targetGrade`: `FLOAT64`<br> - `touchGrade`: `FLOAT64` |
| `homePlayers` | `ARRAY<STRUCT>` | Array of tracking data for each home team player at the event time.<br> _Per Player:_<br> - `jerseyNum`: `INT64`<br> - `confidence`: `STRING`<br> - `visibility`: `STRING`<br> - `x`: `FLOAT64` (Position)<br> - `y`: `FLOAT64` (Position)<br> - `speed`: `FLOAT64`<br> - `playerId`: `INT64` |
| `awayPlayers` | `ARRAY<STRUCT>` | Array of tracking data for each away team player at the event time.<br> _Per Player:_<br> - `jerseyNum`: `INT64`<br> - `confidence`: `STRING`<br> - `visibility`: `STRING`<br> - `x`: `FLOAT64` (Position)<br> - `y`: `FLOAT64` (Position)<br> - `speed`: `FLOAT64`<br> - `playerId`: `INT64` |
| `ball` | `ARRAY<STRUCT>` | Array (usually 1 element) of tracking data for the ball.<br> _Per Ball:_<br> - `visibility`: `STRING`<br> - `x`: `FLOAT64` (Position)<br> - `y`: `FLOAT64` (Position)<br> - `z`: `FLOAT64` (Height) |

---

## Table: `match_metadata`

Contains high-level information about each match.

| Column Name | Data Type | Description |
|---|---|---|
| `awayTeam` | `STRUCT` | Details of the away team.<br> - `id`: `STRING`<br> - `name`: `STRING`<br> - `shortName`: `STRING` |
| `awayTeamKit` | `STRUCT` | Away team's kit details.<br> - `name`: `STRING`<br> - `primaryColor`: `STRING`<br> - `primaryTextColor`: `STRING`<br> - `secondaryColor`: `STRING`<br> - `secondaryTextColor`: `STRING` |
| `competition` | `STRUCT` | Competition details.<br> - `id`: `STRING`<br> - `name`: `STRING` |
| `date` | `TIMESTAMP` | The date and time when the match was played. |
| `endPeriod1` | `TIMESTAMP` | Timestamp marking the end of the first period (half). |
| `endPeriod2` | `TIMESTAMP` | Timestamp marking the end of the second period (half). |
| `halfPeriod` | `TIMESTAMP` | Timestamp related to the half-time interval. |
| `homeTeam` | `STRUCT` | Details of the home team.<br> - `id`: `STRING`<br> - `name`: `STRING`<br> - `shortName`: `STRING` |
| `homeTeamKit` | `STRUCT` | Home team's kit details.<br> - `name`: `STRING`<br> - `primaryColor`: `STRING`<br> - `primaryTextColor`: `STRING`<br> - `secondaryColor`: `STRING`<br> - `secondaryTextColor`: `STRING` |
| `homeTeamStartLeft` | `BOOL` | Flag indicating if the home team started playing from left-to-right in the first half (relative to main camera). |
| `homeTeamStartLeftExtraTime` | `BOOL` | Flag indicating if the home team started playing from left-to-right in extra time. |
| `id` | `STRING` | Unique identifier for the match (likely links to `events.match_id`). |
| `period1` | `TIMESTAMP` | Timestamp marking the start of the first period (half). |
| `period2` | `TIMESTAMP` | Timestamp marking the start of the second period (half). |
| `season` | `STRING` | Identifier for the season (e.g., "2022"). |
| `stadium` | `STRUCT` | Stadium details.<br> - `id`: `STRING`<br> - `name`: `STRING`<br> - `pitches`: `ARRAY<STRUCT>` (Details about the pitch used)<br>   _Per Pitch:_<br>   - `endDate`: `TIMESTAMP`<br>   - `id`: `STRING`<br>   - `length`: `FLOAT64`<br>   - `startDate`: `DATE`<br>   - `width`: `FLOAT64` |
| `startPeriod1` | `TIMESTAMP` | Alias or alternative timestamp for the start of the first period. |
| `startPeriod2` | `TIMESTAMP` | Alias or alternative timestamp for the start of the second period. |
| `week` | `INT64` | Identifier for the match week or stage of the competition (e.g., 1, 2, 3 for group stage). |
| `fps` | `FLOAT64` | Frames per second of the associated match video. |
| `videoUrl` | `STRING` | URL link to the match video footage. |

---

## Table: `players`

Contains information about individual players.

| Column Name | Data Type | Description |
|---|---|---|
| `dob` | `DATE` | Player's date of birth. |
| `firstName` | `STRING` | Player's first name. |
| `height` | `FLOAT64` | Player's height (likely in meters or cm). |
| `id` | `INT64` | Unique numerical identifier for the player. |
| `lastName` | `STRING` | Player's last name. |
| `nickname` | `STRING` | Player's common name or nickname. |
| `positionGroupType` | `STRING` | Player's primary position group (e.g., 'Forward', 'Midfielder', 'Defender', 'GK'). |

---

## Table: `rosters`

Defines the player roster for each team in each specific match.

| Column Name | Data Type | Description |
|---|---|---|
| `match_id` | `STRING` | Identifier linking the roster entry to a specific match. |
| `player` | `STRUCT` | Player details for this roster.<br> - `id`: `STRING` (Player ID, links to `players.id` after casting)<br> - `nickname`: `STRING` |
| `positionGroupType` | `STRING` | The position group the player was assigned for this specific match. |
| `shirtNumber` | `INT64` | The jersey number worn by the player in this match. |
| `started` | `BOOL` | Flag indicating whether the player started the match (TRUE) or was a substitute (FALSE). |
| `team` | `STRUCT` | Team details for this roster.<br> - `id`: `STRING`<br> - `name`: `STRING` |

---

## Table: `tracking_data`

Contains detailed, frame-by-frame positional data for players and the ball, synchronized with event data.

| Column Name | Data Type | Description |
|---|---|---|
| `possession_event` | `STRUCT` | Details of the possession event linked to this frame.<br> - `start_frame`: `INT64`<br> - `updated_at`: `TIMESTAMP`<br> - `inserted_at`: `TIMESTAMP`<br> - `start_time`: `FLOAT64`<br> - `formatted_game_clock`: `STRING`<br> - `possession_event_type`: `STRING`<br> - `game_event_id`: `INT64`<br> - `game_id`: `INT64` |
| `balls` | `ARRAY<STRUCT>` | Array (usually 1 element) of *original* (unsmoothed) ball tracking data.<br> _Per Ball:_<br> - `z`: `FLOAT64` (Height)<br> - `y`: `FLOAT64` (Position)<br> - `x`: `FLOAT64` (Position)<br> - `visibility`: `STRING` |
| `awayPlayersSmoothed` | `ARRAY<STRUCT>` | Array of *smoothed* tracking data for away team players.<br> _Per Player:_<br> - `visibility`: `STRING`<br> - `confidence`: `STRING`<br> - `y`: `FLOAT64` (Position)<br> - `x`: `FLOAT64` (Position)<br> - `jerseyNum`: `INT64` |
| `awayPlayers` | `ARRAY<STRUCT>` | Array of *original* (unsmoothed) tracking data for away team players.<br> _Per Player:_<br> - `speed`: `FLOAT64`<br> - `visibility`: `STRING`<br> - `confidence`: `STRING`<br> - `y`: `FLOAT64` (Position)<br> - `x`: `FLOAT64` (Position)<br> - `jerseyNum`: `INT64` |
| `period` | `INT64` | The period (half) of the match this frame belongs to (1, 2, 3, 4). |
| `possession_event_id` | `FLOAT64` | Identifier linking this frame to a specific possession event in the `events` table. |
| `game_event_id` | `FLOAT64` | Identifier linking this frame to a specific game event in the `events` table. |
| `gameRefId` | `FLOAT64` | Game identifier, likely synonymous with `match_id`. |
| `frameNum` | `INT64` | The sequential frame number since the start of the video feed. |
| `generatedTime` | `TIMESTAMP` | Timestamp when the original Sportlogiq tracking file was generated. |
| `ballsSmoothed` | `STRUCT` | *Smoothed* ball position data for this frame.<br> - `z`: `FLOAT64` (Height)<br> - `y`: `FLOAT64` (Position)<br> - `x`: `FLOAT64` (Position)<br> - `visibility`: `STRING` |
| `homePlayers` | `ARRAY<STRUCT>` | Array of *original* (unsmoothed) tracking data for home team players.<br> _Per Player:_<br> - `speed`: `FLOAT64`<br> - `visibility`: `STRING`<br> - `confidence`: `STRING`<br> - `y`: `FLOAT64` (Position)<br> - `x`: `FLOAT64` (Position)<br> - `jerseyNum`: `INT64` |
| `videoTimeMs` | `FLOAT64` | Time in milliseconds since the start of the video feed. |
| `game_event` | `STRUCT` | Details of the broader game event linked to this frame.<br> - `start_frame`: `INT64`<br> - `sequence`: `INT64`<br> - `home_team`: `INT64` (Boolean-like: 1 or 0?)<br> - `video_url`: `STRING`<br> - `end_frame`: `INT64`<br> - `updated_at`: `TIMESTAMP`<br> - `duration`: `FLOAT64`<br> - `player_name`: `STRING`<br> - `position_group_type`: `STRING`<br> - `end_time`: `FLOAT64`<br> - `home_ball`: `BOOL`<br> - `inserted_at`: `TIMESTAMP`<br> - `start_time`: `FLOAT64`<br> - `team_id`: `INT64`<br> - `formatted_game_clock`: `STRING`<br> - `game_event_type`: `STRING`<br> - `team_name`: `STRING`<br> - `shirt_number`: `INT64`<br> - `player_id`: `INT64`<br> - `game_id`: `INT64` |
| `smoothedTime` | `TIMESTAMP` | Timestamp when the smoothing process was applied to the tracking data. |
| `homePlayersSmoothed` | `ARRAY<STRUCT>` | Array of *smoothed* tracking data for home team players.<br> _Per Player:_<br> - `visibility`: `STRING`<br> - `confidence`: `STRING`<br> - `y`: `FLOAT64` (Position)<br> - `x`: `FLOAT64` (Position)<br> - `jerseyNum`: `INT64` |
| `periodGameClockTime` | `FLOAT64` | Estimated game clock time in seconds within the current period. |
| `periodElapsedTime` | `FLOAT64` | Time elapsed in seconds since the start of the current period. |
| `version` | `STRING` | Version identifier for the Sportlogiq tracking data format. | 