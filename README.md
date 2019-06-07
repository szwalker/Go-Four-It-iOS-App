# Go-Four-It-iOS-App
Go Four It is an Augmented Reality 3D game based on a classic game called Connect Four. Player will play against a friend and try to connect four pieces into a line, which can be vertical, horizontal, or diagonal across space.

In order to place your piece onto the desired pole, players need to select the pole simply by touching. Once the selected pole is highlighted in yellow, press confirm to drop the piece. The player who first connect four pieces into a line wins the game.

An amazing feature of Go Four It is that it supports two mode: single device mode and multi-device mode. Players can play on a single device in turn as well as connect two phones to play on their own phone. With the multi-device later mode, both players will have the same 3D immersive experience with the augmented reality, providing a unique and mind challenging opportunity for all players to explore the game.

This iOS App is designed and developed by Jiaqi Liu(jiaqi.liu@nyu.edu) and Chenyu Liu(cl3679@nyu.edu).

# App Screenshots
A video demo for the multi-device mode:
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/c7c25S5IIM/0.jpg)](http://www.youtube.com/watch?v=c7c25S5IIM)


<a href="http://www.youtube.com/watch?feature=player_embedded&v=c7c25S5IIM
" target="_blank"><img src="http://img.youtube.com/vi/c7c25S5IIM/0.jpg"
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>


# Technical Description
Overall game logic:
We used two 2D arrays to keep track of the what is happening on the game board. With these two arrays, we are able to extract information such as the position in which the piece should be rendered upon placement and whether the pole is full so that we can disregard any touch event. We can also feed both arrays to a “checkWin” function every time a player makes a move.

## Framework and APIs
We used `TransitionButton` and `SkyFloatingLabelTextField` from `CocoPods`.
The `TransitionButton` is used for button animation and the `SkyFloatingLabelTextField` is used for dynamic text field interaction.

We also used `ARKit`, `SceneKit`, `AVFoundation`, `MultipeerConnectivity` from Apple.
The ARKit is used for rendering an augmented reality view and providing us options to configure the view, such as `ARWorldTrackingConfiguration`.

The `SceneKit` provides us a node tree for the view, and allows us to attach or remove any scenes to the view to display and interact with the user.

We used `AVFoundation` to provide sound effects on the following events have occurred:
1. when the user pressed the confirm button and placed a chess on board;
2. when a winner occurred;
3. when a user pressed the quit button.
4. when a user selects the solo mode.

We used `MultipeerConnectivity` to support multiplayer mode. It allows us to set up peer-to-peer sessions so as long as two users are under the same wifi or they both have bluetooth opened, then they can connect with each other and play the game in this multiplayer mode.
