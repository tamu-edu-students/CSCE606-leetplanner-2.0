Architecture Decision Records (ADRs)
====================================

### ADR-001: User Authentication via Google OAuth
-   In Project 1 Guide

### ADR-002: Choice of Database System
-   In Project 1 Guide

### ADR-003: Real-time Collaboration Framework

-   Status: Accepted

-   Context: The collaborative lobbies require real-time synchronization for the shared whiteboard and shared notes. Data must be broadcast to all participants in a lobby instantly.

-   Decision: We decided to use Rails Action Cable to manage real-time data synchronization via WebSockets.

-   Consequences:

-   Pro: Action Cable is fully integrated into the Rails framework, allowing us to use existing models and authentication logic.

-   Pro: It provides a robust channel-based system for scoping communication to specific lobbies.

-   Con: Adds a new layer of complexity to the application. Requires careful management of WebSocket connections and data broadcasting to prevent performance issues.

### ADR-004: AI Chatbot Integration

-   Status: Accepted

-   Context: During Sprint 2, a new feature was proposed to add an AI assistant to help users.

-   Decision: We decided to integrate a third-party AI service API to provide chatbot functionality.

-   Consequences:

-   Pro: Adds a powerful, modern feature to the application with minimal development overhead for the AI model itself.

-   Con: Creates an external dependency on a third-party API. This introduces potential costs and requires secure management of API keys (using Heroku Config Vars).

![Architecture Diagram](architecture_diagram.png)