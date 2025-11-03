User Guide
==========

This guide explains how to use the primary features of the application.

### Getting Started: Sign In

1.  Navigate to the application's home page.

2.  Click the "Sign in with Google" button.

3.  You will be redirected to a Google authentication screen. Authorize the application to access your profile and calendar.

4.  Upon success, you will be redirected back to the application's main dashboard, fully logged in.

Note: This application is presently built only for students, faculty and employees of Texas A&M University. You can only sign in through your "[tamu.edu](http://tamu.edu)" account.

### Lobbies

The Collaborative Lobbies feature allows you to create real-time study sessions with other users, complete with a shared whiteboard, notes, and participant list.

1. Accessing the Lobby Dashboard
Navigate to the "Lobbies" page from the main navigation bar. From this page, you can join, create, or view your lobbies.

To Join a Lobby: Enter the 6-character lobby_code provided by a host into the "Join a Lobby" form and click "Join."

To Create a Lobby: Click the "+ Create New Lobby" button. You will be asked to provide a Name, Description, and set the visibility to "Public" or "Private."

2. The Lobby Room
The lobby room is a three-column layout designed for real-time collaboration:

Shared Notes (Left Column): A real-time text editor. All participants can see the content, but only users with the "Can Edit Shared Notes" permission can type, edit, and save notes for the group.

Whiteboard (Center Column): An interactive canvas for visual problem-solving. A toolbar allows you to draw with a pencil, erase, clear the board, and change colors and brush size. Drawing is only enabled for users with the "Can Draw on Whiteboard" permission.

Text Chat (Right Column):

3. Managing Your Lobby (For Owners)
If you are the lobby owner, you have special controls located in the "Description and Permissions" section at the bottom of the page.

Finding Your Lobby Code: Your unique 6-character lobby_code is displayed here. Share this code to invite other users to your lobby.

Managing Permissions: In the "Manage Permissions" table, you can grant or revoke privileges for each participant. Check the box for "Can Draw on Whiteboard" or "Can Edit Shared Notes" and click "Update All Permissions" to save your changes.

Ending a Session: When you are finished, you can click "Destroy Lobby" to permanently delete the lobby and all its contents.

4. Leaving a Lobby (For Participants)
If you are a participant and not the owner, you will see a "Leave Lobby" button. Clicking this will remove you from the session and return you to the Lobbies dashboard.

#### Notes

From the main lobby view, you can access the dedicated Shared Notes page by clicking the "Notes" button (this may be in the left column or near the "Back to Lobbies" button). This page is designed for focused, collaborative text editing, such as drafting pseudocode or listing ideas.

Edit Mode: If you are the Lobby Owner or have been granted the "Can Edit Shared Notes" permission by the owner, you will see a large, editable text area. You can type directly into this box. When you are finished, click the "Save Note" (or "Create Note") button to save the content for everyone in the lobby.

Read-Only Mode: If you do not have edit permissions, you will see the notes in a read-only (grayed-out) text box. You can read all the content but cannot make changes.

Returning: From the notes page, you can click the "Back to Lobby" button at any time to return to the main lobby view.

#### Whiteboard

The Lobby page includes a shared whiteboard designed to work with and without JavaScript:

1. JavaScript Enabled (Enhanced Mode)
	- Drawing canvas powered by Fabric.js (freehand pen, text, rectangle, circle, line tools).
	- Color picker and brush size slider.
	- Live synchronization: changes broadcast instantly to other lobby members using ActionCable.
	- Grid background for alignment.

2. JavaScript Disabled (Fallback Mode)
	- The current board state is rendered as server-side SVG.
	- Basic forms allow adding text, rectangle, circle, and line elements without any client scripting.
	- Notes section remains editable if you have the proper permission (Owner or Can Edit Notes).

#### Text Chat

### Logout

Click the "Sign Out" button at the bottom of your main navigation bar to sign out. You will be redirected back to the "Sign In" page.