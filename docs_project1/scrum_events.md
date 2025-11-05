### **Sprint 1 (Sept 15 -- Sept 23): Foundation & Core Features**

**Goal:** Establish the technical foundation, implement user authentication, and build core CRUD functionalities for calendar events and LeetCode entries.

#### **Sprint 1 Planning**

-   **Date:** September 15, 2025

-   **Purpose:** To define the scope of Sprint 1, discuss the initial product backlog, and create a plan for the upcoming week. The team aligns on the sprint goal and selects the user stories to work on.

**Discussion & Outcomes:**

-   **Project Vision:** The team confirmed the project scope: a core application focused on a calendar and LeetCode tracking, deciding to postpone complex features like general hobby tracking.

-   **Backlog & Tooling:**

    -   The team established a GitHub repository under the "TAMU" organization for source control and agreed to use GitHub Projects for task management.

    -   A Notion document was created by @yafeili to collaboratively refine requirements and user stories.

-   **Sprint 1 User Stories Selected:**

    -   *(Authentication)*: "As a visitor, I want to log in via Google OAuth..."

    -   *(System Setup)*: "As a system, I want to set up the initial repository structure..."

    -   *(Calendar)*: "As a user, I want to perform CRUD (create, read, update, delete) operations on events..."

    -   *(LeetCode)*: "As a user, I want CRUD operations for LeetCode problems..."

-   **Initial Task Breakdown:**

    -   @Hasitha Tumu took on creating the boilerplate code.

    -   @Tasnia Jamal began researching the TAMU single sign-on (SSO) integration.

#### **Daily Standups (Summary)**

-   **Dates:** September 18, 21, & 22, 2025

-   **Purpose:** To provide quick, daily updates on progress, identify any impediments, and coordinate the day's work.

**Key Updates & Blockers:**

-   **Sept 18:**

    -   **Blocker:** @Tasnia Jamal reported being unable to push code.

    -   **Resolution:** @Hasitha Tumu identified it as a permissions issue and resolved it by granting @Tasnia Jamal write access to the repository.

    -   **Progress:** @Shreya and @Hasitha Tumu shared they were starting on the Google Calendar integration and dashboard development, respectively. The team discussed the LeetCode API limitations.

-   **Sept 21:**

    -   **Blocker:** The Google Calendar integration was failing tests. @Shreya identified that the test cases were mismatched with the routes and took the action item to fix them.

    -   **Progress:** Linting issues were identified and deemed easy fixes by the team. @Hasitha Tumu outlined the deployment plan to merge to `development` and deploy to Heroku.

-   **Sept 22:**

    -   **Progress:** The team reviewed the current UI (dashboard and calendar tabs).

    -   **Planning:** The team divided the work for the upcoming features:

        -   @Shreya & @Tasnia Jamal: Calendar and Dashboard tabs.

        -   @yafeili & @Hasitha Tumu: LeetCode tab.

    -   **Prioritization:** Email integration was prioritized over YouTube integration.

#### **Sprint 1 Review & Retrospective**

-   **Date:** September 25, 2025

-   **Purpose:** To demonstrate the work completed during the sprint and reflect on the team's process to identify areas for improvement.

**Sprint Review (Demo & Discussion):**

-   **Completed Work:**

    -   @Shreya demonstrated the completed dashboard feature showing the user's current calendar event.

    -   @yafeili confirmed completion of the backend CRUD code for events.

    -   The initial repository setup, CI pipeline, and user authentication flow were functional.

-   **Unfinished Work:** Several team members were still debugging integration issues, particularly with logout and calendar syncing.

**Sprint Retrospective (Process Improvement):**

-   **What went well?**

    -   The team was effective at identifying and resolving technical blockers quickly (e.g., repository permissions).

    -   Collaboration on tools like Notion and GitHub Projects was successful.

-   **What could be improved?**

    -   Individual environment differences caused confusion. @Tasnia Jamal faced logout/sync issues that others couldn't reproduce, indicating a need for more consistent development environments or better debugging strategies.

    -   There was a need for clearer communication on when core changes (like @Hasitha Tumu's session store update) were pushed, as they had downstream impacts.

-   **Action Item:** Team members experiencing issues should pull the latest from the `development` branch more frequently to stay in sync.

* * * * *

### **Sprint 2 (Sept 24 -- Oct 2): Advanced Features & Final Polish**

**Goal:** To build the statistics dashboard, enhance UI/UX, finalize all documentation and testing, and prepare the application for final presentation.

#### **Sprint 2 Planning & Backlog Grooming**

-   **Date:** September 27 & October 3, 2025

-   **Purpose:** To define the goals for Sprint 2 and break down larger stories into smaller, manageable tasks.

**Discussion & Outcomes:**

-   **New Requirement (Sept 27):** A key discussion point was the new requirement to make the application functional *without* JavaScript. @Shreya took the lead on this major refactoring task.

-   **Task Dependencies:** The team identified that the JS removal would be a blocker for @Hasitha Tumu and @Tasnia Jamal, who would need to adapt their UI code afterward.

-   **Backlog Grooming (Oct 3):**

    -   The team realized they needed to meet the project requirement of having 20 user stories.

    -   They reviewed the existing work and broke down large features into smaller, more granular stories (e.g., splitting "Dashboard UI" into separate stories for the timer, current event display, and styling).

-   **Sprint 2 User Stories Selected:**

    -   *(Dashboard/Stats)*: "As a user, I want to see statistics in a styled UI...", "As a user, I want to fetch statistics from LeetCode's API..."

    -   *(Polish)*: "As a developer, I want to refactor the dashboard codebase...", "As a user, I want the calendar UI to be polished..."

    -   *(Emails)*: "As a user, I want to receive a weekly email summarizing my progress..."

    -   *(Documentation)*: "As a team, we want technical documentation...", "As a team, we want a presentation slide deck..."

#### **Daily Standups (Summary)**

-   **Dates:** September 30 & October 4, 2025

-   **Purpose:** To track progress towards the sprint goal and resolve final integration issues before the deadline.

**Key Updates & Blockers:**

-   **Sept 30:**

    -   **Progress:** @Shreya had a pending PR for the JS removal and dashboard metrics. @Hasitha Tumu gave an overview of the session tracking logic, and @Tasnia Jamal was working on UI changes.

    -   **Decision:** The team decided against overcomplicating the event-session association logic to focus on core deliverables.

    -   **Final Plan:** The team set a firm timeline: code complete by Thursday (10/2), docs by Friday (10/3), video recording on Sunday (10/5).

-   **Oct 4:**

    -   **Blocker:** @Tasnia Jamal faced merge conflicts due to divergent branches.

    -   **Resolution:** @Shreya resolved the major conflicts and merged the changes into the `development` branch.

    -   **Progress:** The app was deployed to Heroku, but a 500 error was found and fixed. The team focused on final bug fixes, like the sign-out flash issue.

#### **Sprint 2 Review**

-   **Date:** October 5, 2025

-   **Purpose:** To present the fully functional product, review all completed features, and prepare for the final presentation to stakeholders (the professor and TA).

**Demo & Discussion:**

-   **Final Product Demo:** The team walked through the final application, dividing responsibilities for the video recording:

    -   @Tasnia Jamal: Introduction & Login (Google OAuth).

    -   @Shreya: Dashboard (current event, timer, stats).

    -   @Hasitha Tumu: Calendar (CRUD) & LeetCode integration.

    -   @yafeili: Statistics Page, User Profile, and Email feature.

-   **Features Reviewed:**

    -   **Security:** All routes are protected and require Google OAuth authentication.

    -   **Accessibility:** The app functions without JavaScript (except for the Google login page itself), uses high color contrast, and has no critical accessibility issues.

    -   **Functionality:** The final application successfully integrates Google Calendar, tracks LeetCode problems, and displays user statistics.

#### **Project Retrospective**

-   **Date:** October 5, 2025

-   **Purpose:** To reflect on the entire project, celebrating successes and noting key lessons learned.

**Discussion & Key Takeaways:**

-   **What went well?**

    -   The team successfully delivered all core features and met the advanced requirements like JS-optional functionality and email summaries.

    -   They demonstrated strong problem-solving skills in debugging complex integration, deployment, and merge conflict issues.

    -   The division of labor for the final presentation was clear and efficient.

-   **What could be improved?**

    -   **Branching Strategy:** The team encountered several merge conflicts and divergent branches, suggesting that a more disciplined Git workflow (e.g., more frequent rebasing or merging from `development`) could have saved time.

    -   **Requirement Clarity:** The mid-sprint addition of the "no-JavaScript" requirement and the late realization about the "20 user stories" count caused the team to pivot and refactor work, highlighting the challenge of evolving requirements.