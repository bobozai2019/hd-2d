import { TokenEstimator } from './token-estimator.js';
import { ChatMessage, TokenSession, TokenTrackingConfig } from './interfaces.js';
/**
 * Token tracker for managing token counts and history cleanup
 */
export declare class TokenTracker {
    private estimator;
    private config;
    constructor(estimator: TokenEstimator, config?: Partial<TokenTrackingConfig>);
    /**
     * Add a chat message to session and update token counts
     */
    addChatMessage(session: TokenSession, role: 'user' | 'assistant', content: string): void;
    /**
     * Recalculate token count for session (e.g., after loading from storage)
     */
    recalculateTokens(session: TokenSession): void;
    /**
     * Cleanup session based on token and message limits
     * This should be called before saving session to storage
     */
    cleanupSession(session: TokenSession): void;
    /**
     * Truncate history based on token limit
     */
    private truncateByTokens;
    /**
     * Truncate history based on message count limit
     */
    private truncateByMessageCount;
    /**
     * Calculate how many messages to remove to reach target token count
     */
    calculateMessagesToRemove(messages: ChatMessage[], currentTokens: number, targetTokens: number): number;
    /**
     * Update configuration
     */
    updateConfig(config: Partial<TokenTrackingConfig>): void;
    /**
     * Get current configuration
     */
    getConfig(): TokenTrackingConfig;
}
//# sourceMappingURL=token-tracker.d.ts.map