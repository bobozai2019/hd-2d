---
name: token-manager
description: Use when implementing token estimation, tracking, auto-summarization, or token limit management in conversational AI systems
---

# Token Manager Skill

## Overview
A skill for managing token estimation, tracking, auto-summarization, and token limit management in conversational AI systems. Provides accurate token counting, automatic conversation summarization when approaching token limits, and configurable token management.

## When to Use
- Implementing token estimation for text messages
- Tracking token usage across conversation history
- Managing token limits and automatic cleanup
- Triggering automatic summarization when approaching token limits
- Providing token statistics and limit configuration commands

## Core Functions

### Token Estimation
Uses a heuristic-based approach: Chinese characters ≈ 2 tokens, other characters ≈ 0.25 tokens each.

### Token Tracking
- Maintains accurate token counts across conversation history
- Handles token-based cleanup when limits are exceeded
- Supports both token-based and message count-based limits

### Auto-Summarization
- Automatically triggers summarization when token usage exceeds 80% of limit
- Can be manually triggered via /summarize command
- Maintains conversation context while reducing token usage

### Configuration Management
- Token limit settings (0 for unlimited)
- Threshold configuration for auto-summarization
- Integration with session management systems

## API Usage

```typescript
import { TokenManager } from './index';

const tokenManager = new TokenManager();

// Estimate tokens
const tokens = tokenManager.estimateTokens("Hello world 你好");

// Check if auto-summarization should be triggered
const shouldSummarize = tokenManager.shouldAutoSummarize(currentTokens, limit, threshold);

// Format token usage for display
const usageText = tokenManager.formatTokenUsage(currentTokens, limit);
```

## Integration Points

### Session Management
Integrates with session storage to maintain token counts across message history.

### Command Handlers
Provides handlers for:
- `/token_stats` - Display token usage statistics
- `/set_tokens_limit` - Configure token limits
- `/summarize` - Manual summarization trigger

### Auto-Summarization Logic
Called before adding new messages to check if summarization is needed.

## Configuration

### Default Settings
- Default token limit: 80,000 (80% of 102,400 for 20% buffer)
- Auto-summarization threshold: 80%
- Default message history length: 100

### Customization
All settings can be configured via session storage or command interface.

## Backward Compatibility
Maintains full compatibility with existing:
- Session data structure
- Command interfaces
- Token estimation algorithms
- Auto-summarization behavior