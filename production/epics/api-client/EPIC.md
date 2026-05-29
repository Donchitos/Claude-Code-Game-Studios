# Epic: API Client

> **Layer**: Foundation
> **GDD**: design/gdd/api-client.md
> **Architecture Module**: API Client (HTTP + retry + JWT injection)
> **Status**: Ready
> **Stories**: 5/5 Complete

## Overview

The API Client is the client-side HTTP abstraction used by all screens and stores to communicate with the server REST API. It automatically injects the Supabase JWT as a `Bearer` token on every outbound request, handles 401 responses by triggering a session refresh, and implements exponential backoff retry for transient network failures. All REST calls from the mobile client flow through this single module — no screen makes raw `fetch()` calls.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0001: Client-Server Architecture | API Client in Client Foundation layer; all HTTP goes through it | LOW |
| ADR-0004: Authentication Architecture | JWT injected via Axios interceptor; 401 → refresh flow | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR registry pending | Run `/architecture-review` to populate TR-IDs | ADR-0001 ✅ |

## Definition of Done

This epic is complete when:
- All stories implemented and closed via `/story-done`
- All acceptance criteria from `design/gdd/api-client.md` verified
- JWT auto-injected on all requests (integration test)
- 401 response triggers token refresh; original request retried
- Exponential backoff retries on 5xx and network errors
- No screen makes a direct `fetch()` call — enforced by code review

## Next Step

Run `/create-stories api-client` to break this epic into implementable stories.
