User Guide
==========

This guide explains how to use the primary features of the application.

### Getting Started: Sign In

1.  Navigate to the application's home page.

2.  Click the "Sign in with Google" button.

3.  You will be redirected to a Google authentication screen. Authorize the application to access your profile and calendar.

4.  Upon success, you will be redirected back to the application's main dashboard, fully logged in.

Note: This application is presently built only for students, faculty and employees of Texas A&M University. You can only sign in through your "[tamu.edu](http://tamu.edu)" account.

### Dashboard

Track your study sessions in two modes:

-   Ongoing Event: When you log in during a scheduled calendar event, a timer automatically appears and counts down the time remaining in that session. You can also view details of your current event - title and description - with the latter containing a list of the Leetcode problems added for this event (if any).

-   Custom Session: If no event is active, you can start a manual timer. Enter your desired time in minutes in the form field. Toggle your timer with the Start, Pause, and Reset controls.

### Note: Live countdowns require JavaScript. If JavaScript is disabled in the browser, the timer will be static and a "Refresh" button is provided that will update the time countdown display on click.

### Collaborative Whiteboard

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
	- A <noscript> notice explains limitations.

Permissions:
	- Drawing/shape adding controlled by "Can Draw" flag per lobby member.
	- Notes editing controlled by "Can Edit Notes" flag.

Data Persistence:
	- Board stored as SVG (`whiteboards.svg_data`).
	- Notes stored in `whiteboards.notes`.

Limitations / Future Improvements:
	- Real-time presence (who is viewing) not yet displayed.
	- Undo/redo stack not implemented.
	- Potential optimization: PNG snapshot for faster initial load when JS disabled.

Accessibility:
	- All buttons have text labels; color input uses native picker.
	- Fallback forms are regular HTML for screen reader compatibility.


### Calendar

You can view your Google Calendar events on the "Calendar" view. Any modifications you make to your calendar events from this application will sync with your Google Calendar.

-   To Add an Event: Click on the "Add Event" button at the top, this will bring up a form for you to fill in the title, date, and time, then click "Add Event." Your form must at least have an event name, date, and start time (if it is not an all-day event).

-   You can also click on "Back to Calendar" if you wish to discard your changes.

-   To Edit an Event: Click on the "Edit" button next to any existing event in the calendar. This will bring up a form where you can make your changes, and click "Update."

-   You can also click on "Back to Calendar" if you wish to discard your changes.

-   To Delete an Event: Click on the "Delete" button next to any existing event in the calendar.

### Tracking Leetcode Progress

-   You can view any problem on the Leetcode platform using the "View on Leetcode" link next to any problem entry.

-   You can filter Leetcode problems by selecting difficulty levels from the dropdown menu and clicking on the "Filter" icon.

-   You can add Leetcode problems to your calendar events' description so they display on your dashboard (home page) during any scheduled event. 

1.  Navigate to the "Leetcode" page from the main navigation bar.

2.  Next to any Leetcode problem of your interest, click the "Select a Session" button, it will display a dropdown menu of your Google Calendar events.

3.  Select any event and click the "Add" button. This will append the selected Leetcode problem to the event's description.

-   If you don't see your latest Calendar events in the dropdown for "Select a Session", click the "Sync Calendar" button at the top of the page to fetch your latest data.

### Statistics

-   You can view your weekly statistics by navigating to the "Statistics" view from the main navigation bar.

-   Click the "View my Leetcode Profile" button to go to your Leetcode profile.

### Updating Your Profile

You can add your Leetcode username and/or your personal email address to your profile to enable statistics tracking and weekly statistics summary emails, respectively.

1.  Navigate to the "Profile" page from the main navigation bar.

2.  Enter your Leetcode username into the "Leetcode Username" field.

3.  Enter your personal email address into the "Personal Email" field.

4.  Click the "Update Profile" button.

5.  Once updated, the application will be able to fetch your progress from Leetcode and display it on the "Statistics" page. You will also be signed up for receiving weekly statistics summary emails.

### Logout

Click the "Sign Out" button at the bottom of your main navigation bar to sign out. You will be redirected back to the "Sign In" page.