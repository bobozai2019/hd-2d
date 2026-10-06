import { TokenManagerOptions, TokenSession, TokenStats, AutoSummaryCheck } from './src/interfaces.js';
/**
 * Main Token Manager class
 * Provides a unified interface for token estimation, tracking, and auto-summarization
 */
export declare class TokenManager {
    private estimator;
    private tracker;
    private summarizer;
    private configManager;
    constructor(options?: TokenManagerOptions);
    /**
     * Estimate tokens for text
     */
    estimateTokens(text: string): number;
    /**
     * Estimate tokens for messages
     */
    estimateMessagesTokens(messages: Array<{
        content: string;
    }>): number;
    /**
     * Add chat message to session
     */
    addChatMessage(session: TokenSession, role: 'user' | 'assistant', content: string): void;
    /**
     * Recalculate tokens for session
     */
    recalculateTokens(session: TokenSession): void;
    /**
     * Cleanup session based on limits
     */
    cleanupSession(session: TokenSession): void;
    /**
     * Check if auto-summarization should be triggered
     */
    shouldAutoSummarize(currentTokens: number, maxTokens: number, threshold?: number): AutoSummaryCheck;
    /**
     * Generate summarization prompt
     */
    generateSummaryPrompt(currentTokens: number, maxTokens: number, userMessage?: string): string;
    /**
     * Generate manual summarization prompt
     */
    generateManualSummaryPrompt(currentTokens: number, maxTokens: number): string;
    /**
     * Get token statistics
     */
    getTokenStats(currentTokens: number, maxTokens: number, messageCount: number, maxHistoryLength?: number): TokenStats;
    /**
     * Format token usage for display
     */
    formatTokenUsage(currentTokens: number, maxTokens: number): string;
    /**
     * Set token limit
     */
    setTokenLimit(limit: number): {
        valid: boolean;
        error?: string;
    };
    /**
     * Set auto-summary threshold
     */
    setAutoSummaryThreshold(threshold: number): {
        valid: boolean;
        error?: string;
    };
    /**
     * Set max history length
     */
    setMaxHistoryLength(length: number): {
        valid: boolean;
        error?: string;
    };
    /**
     * Get configuration
     */
    getConfiguration(): {
        estimation: import("./src/interfaces.js").TokenEstimationConfig;
        tracking: import("./src/interfaces.js").TokenTrackingConfig;
    };
    /**
     * Update configuration
     */
    updateConfiguration(estimationConfig?: Partial<Parameters<typeof this.configManager.updateEstimationConfig>[0]>, trackingConfig?: Partial<Parameters<typeof this.configManager.updateTrackingConfig>[0]>): void;
}
/**
 * Default export for convenience
 */
export default TokenManager;
/**
 * Helper function to create a TokenManager instance
 */
export declare function createTokenManager(options?: TokenManagerOptions): TokenManager;
//# sourceMappingURL=index.d.ts.map