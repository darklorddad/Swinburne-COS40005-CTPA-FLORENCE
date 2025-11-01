# Project Manifest

This file is used to track the development plan, store notes, and keep temporary information.

---

## Event-Driven Architecture Decision

Ranking of event-driven architectures considered for real-time monitoring, from best to worst, accounting for project needs and ease of implementation.

1.  **Webhooks:** The best overall choice. They are event-driven, simple to implement (especially with services like Supabase), and promote a loosely coupled architecture that is easy to scale and maintain.

2.  **Direct Method Invocation:** The simplest and "laziest" method to implement. It is perfectly real-time as it's just a function call. However, it creates tight coupling and synchronous blocking, which harms scalability and long-term maintainability.

3.  **Database Triggers:** A very strong choice for simplicity and real-time response. They are easy to set up using SQL and keep the event logic close to the data.

4.  **WebSockets / Server-Sent Events (SSE):** Less suitable. These are more complex to implement and are better suited for real-time updates to user interfaces rather than for server-to-server processing.

5.  **Message Queues / Pub/Sub:** A powerful but high-effort solution. It offers excellent scalability and decoupling but requires setting up and managing separate infrastructure (a message broker).

6.  **Change Data Capture (CDC):** The worst option from an ease-of-implementation perspective. This is a complex, low-level pattern requiring specialised tools and configuration.
