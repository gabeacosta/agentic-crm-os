# Agentic CRM OS

![Status](https://img.shields.io/badge/status-production-22c55e?style=for-the-badge) ![Tables](https://img.shields.io/badge/schema-15_tables-4169E1?style=for-the-badge) ![Tenants](https://img.shields.io/badge/tenants-3-22c55e?style=for-the-badge)

Multi-tenant CRM with PostgreSQL state machine.

## Features
- `fn_transition_lead()` with FOR UPDATE row locking
- 12-state lead lifecycle (new > contacted > qualified > ... > closed)
- 3 active tenants: DealiQ, Gentic AI, VoiceScheduleAI
- 9 n8n workflows for automation
- Error handler with dead letter queue

---
Part of the [AI Infrastructure Portfolio](https://github.com/genticai0910-png/ai-portfolio)
