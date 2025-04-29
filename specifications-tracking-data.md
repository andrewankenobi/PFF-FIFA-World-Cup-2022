# PFF FC Tracking Data Specification

**Version 2.2**

*October, 2023*

---
*PFFA Acquisition LLC proprietary information*
---

## 1. Introduction [cite: 38]

This data specification contains a description of the structure and content of PFF's tracking data, which is a synchronized combination of PFF event data and Sportlogiq broadcast tracking data. [cite: 38]
PFF event data consists of game events and possession events. [cite: 39] Game events capture when a player has control over the ball, while possession events capture the action the player performs. [cite: 39, 40] Game events can consist of multiple possession events. [cite: 41] For example, a player that is challenged and attempts a pass during one control of the ball has two possession events (challenge & pass) during one game event. [cite: 41] Frames with multiple associated possession events are duplicated. [cite: 42]

Sportlogiq delivers broadcast tracking data containing the coordinates of the tracked players and the ball. [cite: 42] The estimated locations of "offscreen" players not detected by the tracking system are estimated from context. [cite: 43] Some portions of the ball trajectory are also estimated from context, particularly when the ball is in the air. [cite: 44] After receiving the broadcast tracking data from Sportlogiq, PFF applies two smoothing techniques: (1) a Kalman filter is applied to all player location trajectories and (2) ball locations are smoothened using the PFF events by placing the ball at the location of the ball ball carrier with a linear interpolation between events. [cite: 45] Both the original player and ball locations and smoothed player and ball locations are available in the tracking data files. [cite: 46] Next to the tracking data files, metadata is available to interpret the tracking data, including the pitch dimensions (length and width) and frames per second (fps) rate of the video. [cite: 47] See sections 7 and 8. [cite: 48]

---
*PFFA Acquisition LLC proprietary information | 2*
---

## 2. Data Specification [cite: 49]


| Name                  | Type     | Description                                                                                                |
| :-------------------- | :------- | :--------------------------------------------------------------------------------------------------------- |
| version               | string   | Version of Sportlogiq tracking output.                                                                     |
| gameRefId             | int      | Unique game identifier, should always match game_id in game_event and possession_event.                    |
| generatedTime         | datetime | Date and time Sportlogiq tracking file was generated (ISO 8601 UTC).                                       |
| smoothedTime          | datetime | Date and time tracking file was smoothed (ISO 8601 UTC).                                                   |
| videoTimeMs           | float    | Time in milliseconds since the start of the video.                                                         |
| frameNum              | int      | Number of frames since the start of the video (starting at 0).                                             |
| period                | int      | Sequence number of game halves, counting up from 1. Periods 3 and 4 indicate extra time.                   |
| periodElapsedTime     | float    | Time in seconds since the start of the current half (floor 0).                                             |
| periodGameClockTime   | float    | Current estimated game clock time in seconds.                                                              |
| homePlayers           | list     | List of home team player information. Each entry is a dict containing player identification (jerseyNum, confidence, visibility) as well as x and y coordinates. See section 3. |
| homePlayersSmoothed   | list     | Smoothened home player coordinates using Kalman Filter.                                                      |
| awayPlayers           | list     | List of away team player information. Each entry is a dict containing player identification (jerseyNum, confidence, visibility) as well as x and y coordinates. See section 3. |
| awayPlayersSmoothed   | list     | Smoothened away player coordinates using Kalman Filter.                                                      |
| balls                 | list     | List of ball information. During normal play only the estimated in-play ball is given. Each entry is a dict containing visibility as well as x, y and z coordinates. See section 4. |
| ballsSmoothed         | list     | Smoothened ball coordinates using event data.                                                                |
| game_event_id         | int      | Unique game event identifier.                                                                              |
| possession_event_id   | int      | Unique possession event identifier.                                                                        |
| game_event            | dict     | Dict of game event information. See section 5.                                                             |
| possession_event      | dict     | Dict of possession event information. See section 6.                                                         |

---
*PFFA Acquisition LLC proprietary information | 3*
---

## 3. Player Locations [cite: 52]


| Name       | Type   | Description                                                                                                                         |
| :--------- | :----- | :---------------------------------------------------------------------------------------------------------------------------------- |
| jerseyNum  | int    | Estimated jersey number of the player.                                                                                              |
| confidence | string | Player jersey number confidence - may be ""LOW"", ""MEDIUM"" or ""HIGH"".                                                               |
| visibility | string | Whether the track is tracked in the video or estimated based on the position of visible players and objects may be ""VISIBLE"" or ""ESTIMATED"". |
| X          | float  | Location of player along the X-axis in meters. This runs along the touchlines, increasing from left to right.                         |
| y          | float  | Location of player along the Y-axis in meters. This runs along the end lines, increasing from bottom to the top.                      |

## 4. Ball Location [cite: 54]


| Name       | Type   | Description                                                                                                                         |
| :--------- | :----- | :---------------------------------------------------------------------------------------------------------------------------------- |
| visibility | string | Whether the track is tracked in the video or estimated based on the position of visible players and objects may be ""VISIBLE"" or ""ESTIMATED"". |
| X          | float  | Location of the ball along the X-axis in meters. This runs along the touchlines, increasing from left to right.                       |
| y          | float  | Location of the ball along the Y-axis in meters. This runs along the end lines, increasing from bottom to the top.                    |
| Z          | float  | Vertical distance between the ball and the pitch, in meters.                                                                        |

---
*PFFA Acquisition LLC proprietary information | 4*
---

## 5. Game Events [cite: 57]


| Name                   | Type    | Description                                                                                                                                                                                                      |
| :--------------------- | :------ | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| game_id                | int     | Unique game identifier, should always match gameRefId.                                                                                                                                                           |
| game_event_type        | string  | Type of game event may be ""FIRSTKICKOFF"" (first half kick-off), ""SECONDKICKOFF"" (second half kick-off), ""END"" (end of half), ""G"" (ball hits post, bar or corner flag and stays in play), ""OFF"" (player off), ""ON"" (player on), ""OTB"" (on-the-ball event), ""OUT"" (ball out-of-play), ""SUB"" (substitution) or ""VID"" (video missing). |
| formatted_game_clock   | string  | Formatted game clock for start time of the game event.                                                                                                                                                           |
| player_id              | int     | Unique player identifier.                                                                                                                                                                                        |
| player_name            | string  | Name of player with control over the ball.                                                                                                                                                                       |
| team_id                | int     | Unique team identifier.                                                                                                                                                                                          |
| team_name              | string  | Name of team of the player with control over the ball.                                                                                                                                                           |
| start_time             | float   | Start time of the game event in seconds.                                                                                                                                                                         |
| end_time               | float   | End time of the game event in seconds.                                                                                                                                                                           |
| duration               | float   | Duration of the game event in seconds.                                                                                                                                                                           |
| inserted_at            | datetime| Date and time the game event was collected.                                                                                                                                                                      |
| updated_at             | datetime| Date and time the game event was last updated.                                                                                                                                                                   |
| video_url              | string  | Link to video.                                                                                                                                                                                                   |
| home_team              | boolean | Indicates if the player with control over the ball is part of the home team.                                                                                                                                     |
| sequence               | int     | Possession sequence indicator.                                                                                                                                                                                   |
| home_ball              | boolean | Indicates if the home team has control over the ball during the possession sequence.                                                                                                                             |
| start_frame            | int     | The frameNum at which the game event starts.                                                                                                                                                                     |
| end_frame              | int     | The frameNum at which the game event ends.                                                                                                                                                                       |

---
*PFFA Acquisition LLC proprietary information | 5*
---

## 6. Possession Events [cite: 60]


| Name                   | Type     | Description                                                                                                                                                                        |
| :--------------------- | :------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| game_id                | int      | Unique game identifier, should always match gameRefId.                                                                                                                             |
| game_event_id          | int      | Unique game event identifier, should always match game_event_id in game_event.                                                                                                   |
| possession_event_type  | string   | Type of game event may be ""BC"" (ball carry), ""CH"" (challenge), ""CL"" (clearance), ""CR"" (cross), ""PA"", ""RE"" (rebound) or ""SH"" (shot). Note that dribbles are captured as part of challenges. |
| formatted_game_clock   | string   | Formatted game clock for start time of the possession event.                                                                                                                       |
| start_time             | float    | Start time of the possession event in seconds.                                                                                                                                     |
| inserted_at            | datetime | Date and time the possession event was collected.                                                                                                                                  |
| updated_at             | datetime | Date and time the possession event was last updated.                                                                                                                               |
| start_frame            | int      | The frameNum at which the possession event starts.                                                                                                                                 |
| end_frame              | int      | The frameNum at which the possession event ends.                                                                                                                                   |

---
*PFFA Acquisition LLC proprietary information | 6*
---

## 7. Pitch coordinates [cite: 63]

The tracking data includes the x and y coordinates of players as well as the x, y and z coordinates of the ball during main camera segments. [cite: 63]
The coordinate system is defined as follows: [cite: 64]

* The origin (0, 0, 0) is located at the center of the pitch. [cite: 64]
* X-axis (x) runs along the touchlines, where x increases from left to right, as seen by the main camera. [cite: 65]
* Y-axis (y) runs along the end lines, where y increases from bottom to top, as seen by the main camera. [cite: 66]
* Z-axis (z) points vertically upward from the nominal plane of the pitch. [cite: 67]

Units are in meters. [cite: 67]
For a pitch of 105 meters by 68 meters, the pitch markings are as below: [cite: 68]

*(Image of pitch coordinates was present here in the PDF)* [cite: 68]

---
*PFFA Acquisition LLC proprietary information | 7* [cite: 69]
---

## 8. Metadata [cite: 70]


| Name                | Type    | Description                                                                                                |
| :------------------ | :------ | :--------------------------------------------------------------------------------------------------------- |
| awayTeam            | dict    | Dict of away team information.                                                                             |
| awayTeamKit         | dict    | Dict of away team kit information, including color codes.                                                  |
| competition         | dict    | Dict of competition information.                                                                           |
| date                | datetime| Date and time of game.                                                                                     |
| endPeriod1          | float   | Number of seconds in video at end of first half.                                                           |
| endPeriod2          | float   | Number of seconds in video at end of second half.                                                          |
| homeTeam            | dict    | Dict of home team information.                                                                             |
| homeTeamKit         | dict    | Dict of home team kit information, including color codes.                                                  |
| homeTeamStartLeft   | boolean | Indicates if the home team started the first half playing left to right.                                   |
| id                  | int     | Unique game identifier. Equals gameRefId and game_id in tracking data files.                               |
| periodl             | float   | Number of minutes in the first half.                                                                       |
| period2             | float   | Number of minutes in the second half.                                                                      |
| season              | string  | Season identifier.                                                                                         |
| stadium             | dict    | Dict of stadium information, including pitch dimensions (length & width)                                   |
| startPeriodl        | float   | Number of seconds in video at start of first half.                                                         |
| startPeriod2        | float   | Number of seconds in video at start of second half.                                                        |
| videos              | dict    | Dict of video information, including fps and link to video.                                                |
| week                | int     | Game week identifier.                                                                                      |

---
*PFFA Acquisition LLC proprietary information | 8* [cite: 72]
---
