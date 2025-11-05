# Collaborative LeetPlanner

An advanced LeetCode Tracker with real-time collaborative lobbies.
--------------------------

This project is a group web application developed for CSCE 606 (Software Engineering) at Texas A&M University.\
It expands on the original LeetCode tracker by adding real-time, collaborative lobbies for group study sessions.

**Deployed application** - https://leetplanner-2-4817a1835b4f.herokuapp.com/
* * * * *

Core Features
--------------------------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-core-features)

* **Collaborative Lobbies:** Create public or private lobbies and invite users to join.
* **Real-Time Whiteboard:** A shared whiteboard for all lobby participants to draw, erase, and clear.
* **Synchronized Shared Notes:** A real-time, auto-saving notes editor for group collaboration.
* **Text Chat:** A real-time chat channel for group collaboration.
* **AI Chatbot:** An integrated AI assistant to help with problem-solving.

* * * * *

Agile Development Plan
-------------------------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-agile-development-plan)

We followed Agile (Scrum) methodology with 2 sprints to deliver the "Collaborative Lobbies" epic.

### Sprint 1 (Oct 16 – Oct 26): Core Lobby & Collaboration Features

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-sprint-1)

**Goal:** Establish the foundation for the collaborative lobbies, implementing lobby creation, participation, and the core real-time whiteboard and notes features.

**Deliverables:**
* Successfully demonstrated lobby creation & management features.
* A functional real-time shared whiteboard.
* A synchronized shared notes editor.

* * * * *

### Sprint 2 (Oct 29 – Nov 4): Analytics, AI Chat, & Final Polish

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-sprint-2)

**Goal:** Address Sprint 1 spillover (bug fixes, test coverage), implement advanced features (Analytics, AI Chatbot), and complete all documentation for the final project submission.

**Deliverables:**
* Fixed all outstanding bugs from Sprint 1.
* Increased test coverage to ~90% (RSpec & Cucumber).
* Implemented a lobby analytics chart.
* Integrated a functional AI chatbot.
* Completed all technical documentation and scrum artifacts.

Note: Full Scrum Events (planning, standups, retros) are documented in `docs_project2/scrum_events.md`.
* * * * *

User Stories (Epic: Collaborative Lobbies)
--------------------------------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-user-stories)

The user stories for this epic were grouped into the following features:

* **Lobby Creation & Management**
* **Lobby Participation & Permissions**
* **Whiteboard Collaboration**
* **Shared Notes**
* **Text Chat**
* **AI Chatbot Integration**

Note: Full list of User Stories can be found in `docs_project2/user_stories.md`
* * * * *

Repository Structure
---------------------------------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-repository-structure)

CSCE606-leetplanner-2.0/
│── app/ # Rails app code (models, controllers, views)
│── features/ # Cucumber acceptance tests
│── spec/ # RSpec unit tests
│── docs_project2/ # Technical docs, architecture diagrams, scrum logs
│── config/ # Configurations & routes
│── db/ # Migrations & schema
│── README.md # Project overview & setup

* * * * *

Tech Stack
--------------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-tech-stack)

* **Backend:** Ruby on Rails
* **Frontend:** ERB, JavaScript (for analytics charts and whiteboard)
* **Database:** PostgreSQL
* **Testing:** Cucumber, RSpec
* **CI/CD:** GitHub Actions (Rubocop, Simplecov)
* **Deployment:** Heroku
* **Cloud Services:** Google Cloud Platform (GCP)

* * * * *

Documentation
----------------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-documentation)

*	[Technical Documentation](docs_project2/technical_documentation.md) -- setup & deployment steps
*	[User Guide](docs_project2/user_guide.md) -- how to use the collaborative lobbies
*	[Architecture Decision Records](docs_project2/architecture_records.md)
*   [Architecture Diagram](docs_project2/architecture_records.md)
*   [User Stories](docs_project2/user_stories.md)
*   [Database Diagram](docs_project2/erd.pdf)
*   [Presentation]()

* * * * *

Team
-------

[](https://github.com/tamu-edu-students/CSCE606-leetplanner-2.0#-team)

* Mohammed Sharique
* Shreya Sahni
* Venkata Sai Nithin
* Shivam Mishra