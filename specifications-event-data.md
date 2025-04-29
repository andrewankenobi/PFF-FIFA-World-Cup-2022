# PFF FC Event Data Specification

**Version 2.0**

*December, 2024*

---
*PFF A Acquisition LLC proprietary information*
---

## Table of Contents

1.  Introduction
2.  Game Event Information
3.  Initial Touch Information
4.  Possession Event Information
    4.1. Passes and Crosses Information.
    4.2. Shooting Information
    4.3. Clearance columns
    4.4. Challenge columns
    4.5. Touch and Ball Carry Columns
    4.6. Rebound Columns
    4.7. Additional Event Information
4.8. Sub-grade Players
5.  Foul Information
6.  Grades
7.  Location Data
    7.1. Home and Away Player Tracking Information
    7.2. Ball Tracking Information
Appendix 1 - Body part Options
Appendix 2 - Height Options
Appendix 3 - Accuracy Type
Appendix 4 - Incompletion Reason Type
Appendix 5 - Lines Broken Type

---

## 1. Introduction

This document contains the data speciﬁcation of PFF FC event data for association football games. PFF FC events are separated into game events and possession events. Game events could represent a possession for a player on the ball, or events such as substitutions, ball out of play events, end of half/game, etc. Possession events are the events within the possession of a player, such as a pass or a cross for example. Game events can consist of multiple possession events. For example, when a player receives the ball and is challenged by a defender before passing it to a teammate, the game event consists of two possession events: a challenge and a pass. Game events and possession events are merged for your convenience. The variables on the data frame are described in the table below.

| Column name         | Column type   | Column description                                                                                                                                  |
| :------------------ | :------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| gameId              | int           | A unique identiﬁer for games.                                                                                                                       |
| gameEventId         | int           | A unique identiﬁer for game events.                                                                                                                 |
| possessionEventId   | int           | A unique identiﬁer for possession events.                                                                                                           |
| startTime           | ﬂoat          | Time the possession starts in seconds. (In reference to the start of the video, not the game)                                                       |
| endTime             | ﬂoat          | Time the possession ends in seconds. (In reference to the start of the video, not the game)                                                         |
| duration            | ﬂoat          | Duration of the possession in seconds.                                                                                                              |
| eventTime           | ﬂoat          | Time in seconds when the event took place. In reference to the start of the video                                                                   |
| gameEvents          | dict          | Dictionary variable containing information regarding the game events. See [section 2](#2-game-event-information).                                     |
| initialTouch        | dict          | Dictionary variable containing information regarding a player’s ﬁrst touch. See [section 3](#3-initial-touch-information).                            |
| possessionEvents    | dict          | Dictionary variable containing information regarding the possession events. See [section 4](#4-possession-event-information).                         |
| fouls               | dict          | Dictionary variable containing information regarding fouls. See [section 5](#5-foul-information).                                                     |
| grades              | dict          | Dictionary variable  containing the player grades. See [section 6](#6-grades).                                                                      |
| homePlayers         | List of dicts | List of dictionary variables containing information regarding the broadcast tracking data for the players on the home team. See [section 7.1](#71-home-and-away-player-tracking-information). |
| awayPlayers         | List of dicts | List of dictionary variables containing information regarding the broadcast tracking data for the players on the away team. See [section 7.1](#71-home-and-away-player-tracking-information). |
| ball                | dict          | Dictionary variable containing information regarding the broadcast tracking data for the ball. See [section 7.2](#72-ball-tracking-information).        |

## 2. Game Event Information

As previously mentioned the game events represent a possession by a player or other game events like substitutions, or the ball going out of play. The gameEvents dict add information to the entirety of a player’s possessions as well as the additional information for players coming on and oﬀ the game on a substitution for example. The Table below shows the information contained in the game event dict.

| Column name (type)         | Column description                                                                 | Column values                                                                                                                                   |
| :------------------------- | :--------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------- |
| gameEventType (str)        | Type of game event.                                                                | FIRSTKICKOFF - ﬁrst half kick oﬀ <br> SECONDKICKOFF - second half kick oﬀ <br> THIRD KICKOFF - 1st half of extra time <br> FOURTHKICKOFF - 2nd half of extra time <br> FOUL - Additional foul. More information on the [Foul Columns section](#5-foul-information). <br> END - End of half or game <br> G - Ball hits the woodwork or corner ﬂag and comes back into play <br> OFF - Player comes oﬀ the pitch <br> ON - Player come on the pitch <br> OTB - A possession with a player on the ball <br> OUT - Ball out of play <br> SUB - Substitution |
| initialNonEvent (bool)     | Was the possession disallowed after the fact?                                      | True - Event disallowed <br> False - Event not disallowed                                                                                         |
| startGameClock (int)       | Time the possession starts in second in reference to the start of the game         |                                                                                                                                                 |
| startFormattedGameClock (str) | Time the possession starts in the “00:00” format.                                 |                                                                                                                                                 |
| period (str)               | The period (or half) the event took place.                                         | 1 - First Half <br> 2 - Second Half <br> 3 - First Half of Extra Time <br> 4 - Second Half of the Extra Time                                    |
| videoMissing (bool)        | Is part of the event cut by the broadcast?                                         | True - Part of the event is missing <br> False - Entire possession is visible                                                                   |
| teamId (ﬂoat)              | A unique identiﬁer for the team.                                                   |                                                                                                                                                 |
| teamName (str)             | Name of the team                                                                   |                                                                                                                                                 |
| playerId (ﬂoat)            | Unique identiﬁer for the player in possession.                                     |                                                                                                                                                 |
| playerName (str)           | Name of the player in possession                                                   |                                                                                                                                                 |
| touches (ﬂoat)             | Total number of separate touches a player takes within their possession.           |                                                                                                                                                 |
| touchesInBox (ﬂoat)        | Number of touches in the opposition box a player takes within their possession.    |                                                                                                                                                 |
| setpieceType (str)         | Type of set piece being taken or type O when not a set piece                       | C - Corner Kick <br> D - Drop Ball <br> F - Free Kick <br> G - Goal Kick <br> K - Kickoﬀ <br> O - Open Play <br> P - Penalty <br> T - Throw in |
| earlyDistribution (bool)   | Is the set piece taken quickly?                                                    | True - Team tries to take the set piece quickly <br> False - Team does not make an eﬀort to take the set piece more quickly than normal.        |
| videoUrl (str)             | Link to video for the speciﬁc possession                                           |                                                                                                                                                 |
| endType (str)              | Indicates the type of end event.                                                   | 1 - End of First Half <br> 2 - End of Second Half (only used if there is extra time, otherwise it will be G for end of the game) <br> F - End of the ﬁrst half of the extra time <br> G - End of Game |
| outType (str)              | Indicates why the ball has gone out of play                                        | A - Away Score <br> H - Home Score <br> T - Out of Touch <br> W - Whistle                                                                        |
| subType (str)              | Type of substitution                                                               | H - Head Injury <br> S - Standard                                                                                                                |
| playerOﬀId (ﬂoat)          | Unique Identiﬁer for the player coming oﬀ the pitch                                |                                                                                                                                                 |
| playerOﬀName (str)         | Name of the player coming oﬀ the pitch                                             |                                                                                                                                                 |
| playerOﬀType (str)         | Reason for the player leaving the pitch                                            | E - Equipment e.g. having to change boots <br> I - Injury <br> M - Miscellaneous <br> R - Red Card                                             |
| PlayerOnId (str)           | Unique Identiﬁer for the player coming on the pitch                                |                                                                                                                                                 |
| playerOnName (str)         | Name of the player coming on the pitch                                             |                                                                                                                                                 |

## 3. Initial Touch Information

The initial touch information is stored in a dict column. Within the dict we have the following variables.
The pressure data is part of the initial touch (as well as the events). An attempt to apply pressure is recorded when a member of the opposing team is within 5 yards of the ball carrier and closing the space to them with intensity. A pressure is deemed to be successful if that opposing player closes to within 3 yards of the ball carrier, whilst continuing to close the space and aﬀecting either the ball carrier or their options (for example cutting oﬀ pass lanes). Pressure will not be applied if the opposing team member is static or moving away from the ball carrier. Both the 5 and 3 yard radius are used as a guide and can expand or shrink depending on the intensity of the presser or direction of the pressure (smaller radius from behind). For example a player might be 4 yards from the ball carrier but at a full sprint could get awarded a successful pressure whereas a player within 3 yards and walking towards the carrier may not.

| Column name (type)                 | Column description                                                                                                                                                                                                                                                             | Column values                                                                                                                                                                                           |
| :--------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| initialBodyType (str)              | The Body part used to take the ﬁrst touch                                                                                                                                                                                                                                      | See [Appendix 1](#appendix-1---body-part-options).                                                                                                                                                             |
| initialHeightType (str)            | Duration of the game event (recorded in seconds).                                                                                                                                                                                                                              | See [Appendix 2](#appendix-2---height-options).                                                                                                                                                              |
| facingType (str)                   | Direction the player is facing at the point of reception.                                                                                                                                                                                                                      | B - Back to Goal. Not necessarily the goal itself, but general backwards direction <br> G - Goal. Not necessarily the goal itself, but general forward direction. <br> L - Lateral                        |
| initialTouchType (str)             | Quality and diﬃculty when controlling the ball (this is used when the player retains possession, a touch bad enough to make a player lose the ball will be charted as a failed touch or heavy touch - see Touch and Ball Carry Columns for more details)                  | B -Hard to control, but bad <br> G - Hard to control and good <br> M - Miscontrol <br> P - Plus. A positive touch when the ball is not hard to control. E.g. evaded a defender with a good ﬁrst touch <br> S- Standard |
| initialPressureType (str)          | Type of pressure being applied                                                                                                                                                                                                                                                 | A - Attempted Pressure <br> L - Passing Lane Pressure <br> N - No Pressure <br> P - Player Pressured                                                                                                  |
| initialPressurePlayerId (ﬂoat)     | Unique identiﬁer for the player applying the pressure                                                                                                                                                                                                                          |                                                                                                                                                                                                         |
| initialPressurePlayerName (str)    | Name of the player applying the pressure.                                                                                                                                                                                                                                      |                                                                                                                                                                                                         |

## 4. Possession Event Information
The possession event columns represent the general information about a speciﬁc possession event. This will be the dict that contains the highest amount of information since it captures information about all types of possession events and each has individual speciﬁc data points with some overlap. The table below will contain the metadata on the possession event and we will go into the information for each possession event type separately.

| Column name (type)                 | Column description                                                                                                                                                                | Column values                                                                                                                                                                                                                                                                         |
| :--------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| possessionEventType (str)          | Type of event.                                                                                                                                                                    | BC - Ball Carry <br> CH - Challenge <br> CL - Clearance <br> CR - Cross <br> FO - Foul. More information on the [Foul Columns section](#5-foul-information). <br> PA - Pass <br> RE - Rebound <br> SH - Shot <br> TC - Touch. More details in section 9.                          |
| nonEvent (bool)                    | Is the event disallowed after the fact?                                                                                                                                           | True - Event disallowed <br> False - Event not disallowed                                                                                                                                                                                                                                |
| gameClock (ﬂoat)                   | Time in seconds when the event took place. In reference to the start of the game                                                                                                  |                                                                                                                                                                                                                                                                                         |
| formattedGameClock (str)           | Time when the event took place in the “00:00” format.                                                                                                                             |                                                                                                                                                                                                                                                                                         |
| eventVideoUrl (str)                | Link to the video for the speciﬁc event.                                                                                                                                          |                                                                                                                                                                                                                                                                                         |
| ballHeightType (str)               | Height from where the ball was played.                                                                                                                                            | See [Appendix 2](#appendix-2---height-options).                                                                                                                                                                                                                         |
| bodyType (str)                     | Body part used to hit the ball                                                                                                                                                    | See [Appendix 1](#appendix-1---body-part-options).                                                                                                                                                                                                                        |
| highPointType (str)                | Maximum height the ball reached from the point of the distribution and the next event (or the next bounce)                                                                      | See [Appendix 2](#appendix-2---height-options). - Option V - half volley does not apply here.                                                                                                                                                                               |

---
*PFF A Acquisition LLC proprietary information*
---