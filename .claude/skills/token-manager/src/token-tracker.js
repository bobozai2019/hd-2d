/**
 * Default token tracking configuration
 */
const DEFAULT_TRACKING_CONFIG = {
    maxTokensLimit: 80000, // 80% of 102,400 (20% buffer)
    autoSummaryThreshold: 0.8,
    maxHistoryLength: 100,
};
/**
 * Token tracker for managing token counts and history cleanup
 */
export class TokenTracker {
    estimator;
    config;
    constructor(estimator, config = {}) {
        this.estimator = estimator;
        this.config = { ...DEFAULT_TRACKING_CONFIG, ...config };
    }
    /**
     * Add a chat message to session and update token counts
     */
    addChatMessage(session, role, content) {
        // Initialize session fields if needed
        if (!session.chatHistory) {
            session.chatHistory = [];
        }
        if (session.maxTokensLimit === undefined) {
            session.maxTokensLimit = this.config.maxTokensLimit;
        }
        if (session.currentTokens === undefined) {
            session.currentTokens = 0;
        }
        if (session.maxHistoryLength === undefined) {
            session.maxHistoryLength = this.config.maxHistoryLength;
        }
        // Estimate tokens for the new message
        const messageTokens = this.estimator.estimateTokens(content);
        const chatMessage = {
            role,
            content,
            timestamp: Date.now(),
            tokens: messageTokens,
        };
        // Add to history
        session.chatHistory.push(chatMessage);
        session.currentTokens = (session.currentTokens || 0) + messageTokens;
        // Apply token-based truncation if limit is enabled
        const maxTokens = session.maxTokensLimit || this.config.maxTokensLimit;
        if (maxTokens > 0 && session.currentTokens > maxTokens) {
            this.truncateByTokens(session, maxTokens);
        }
        // Apply message count truncation
        const maxLen = session.maxHistoryLength || this.config.maxHistoryLength;
        if (session.chatHistory.length > maxLen) {
            this.truncateByMessageCount(session, maxLen);
        }
        // Ensure currentTokens is non-negative
        if (session.currentTokens < 0) {
            session.currentTokens = 0;
        }
    }
    /**
     * Recalculate token count for session (e.g., after loading from storage)
     */
    recalculateTokens(session) {
        if (!session.chatHistory) {
            session.chatHistory = [];
        }
        let totalTokens = 0;
        for (const msg of session.chatHistory) {
            if (msg.tokens === undefined) {
                msg.tokens = this.estimator.estimateTokens(msg.content);
            }
            totalTokens += msg.tokens;
        }
        session.currentTokens = totalTokens;
    }
    /**
     * Cleanup session based on token and message limits
     * This should be called before saving session to storage
     */
    cleanupSession(session) {
        if (!session.chatHistory) {
            session.chatHistory = [];
        }
        // Ensure fields exist
        if (session.maxTokensLimit === undefined) {
            session.maxTokensLimit = this.config.maxTokensLimit;
        }
        if (session.currentTokens === undefined) {
            this.recalculateTokens(session);
        }
        if (session.maxHistoryLength === undefined) {
            session.maxHistoryLength = this.config.maxHistoryLength;
        }
        // Apply token-based truncation
        const maxTokens = session.maxTokensLimit;
        if (maxTokens > 0 && session.currentTokens > maxTokens) {
            this.truncateByTokens(session, maxTokens);
        }
        // Apply message count truncation
        const maxLen = session.maxHistoryLength;
        if (session.chatHistory.length > maxLen) {
            this.truncateByMessageCount(session, maxLen);
        }
    }
    /**
     * Truncate history based on token limit
     */
    truncateByTokens(session, maxTokens) {
        while (session.chatHistory.length > 1 &&
            session.currentTokens > maxTokens) {
            const removed = session.chatHistory.shift();
            if (removed?.tokens) {
                session.currentTokens = Math.max(0, session.currentTokens - removed.tokens);
            }
        }
    }
    /**
     * Truncate history based on message count limit
     */
    truncateByMessageCount(session, maxLen) {
        const toRemove = session.chatHistory.length - maxLen;
        for (let i = 0; i < toRemove; i++) {
            const removed = session.chatHistory.shift();
            if (removed?.tokens) {
                session.currentTokens = Math.max(0, (session.currentTokens || 0) - removed.tokens);
            }
        }
    }
    /**
     * Calculate how many messages to remove to reach target token count
     */
    calculateMessagesToRemove(messages, currentTokens, targetTokens) {
        if (currentTokens <= targetTokens || !messages || messages.length === 0) {
            return 0;
        }
        let toRemove = 0;
        let removedTokens = 0;
        const targetRemoval = currentTokens - targetTokens;
        for (const msg of messages) {
            if (removedTokens >= targetRemoval)
                break;
            removedTokens += msg.tokens || 0;
            toRemove++;
        }
        return toRemove;
    }
    /**
     * Update configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
}
//# sourceMappingURL=token-tracker.js.map