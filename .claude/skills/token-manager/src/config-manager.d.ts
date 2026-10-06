import { TokenEstimationConfig, TokenTrackingConfig, TokenStats } from './interfaces.js';
/**
 * Configuration manager for token management
 */
export declare class ConfigManager {
    private estimationConfig;
    private trackingConfig;
    constructor(estimationConfig?: Partial<TokenEstimationConfig>, trackingConfig?: Partial<TokenTrackingConfig>);
    /**
     * Get token usage statistics
     */
    getTokenStats(currentTokens: number, maxTokens: number, messageCount: number, maxHistoryLength?: number): TokenStats;
    /**
     * Format token usage for display
     */
    formatTokenUsage(currentTokens: number, maxTokens: number): string;
    /**
     * Validate and set token limit
     */
    setTokenLimit(limit: number): {
        valid: boolean;
        error?: string;
    };
    /**
     * Validate and set auto-summary threshold
     */
    setAutoSummaryThreshold(threshold: number): {
        valid: boolean;
        error?: string;
    };
    /**
     * Validate and set max history length
     */
    setMaxHistoryLength(length: number): {
        valid: boolean;
        error?: string;
    };
    /**
     * Get estimation configuration
     */
    getEstimationConfig(): TokenEstimationConfig;
    /**
     * Get tracking configuration
     */
    getTrackingConfig(): TokenTrackingConfig;
    /**
     * Update estimation configuration
     */
    updateEstimationConfig(config: Partial<TokenEstimationConfig>): void;
    /**
     * Update tracking configuration
     */
    updateTrackingConfig(config: Partial<TokenTrackingConfig>): void;
}
//# sourceMappingURL=config-manager.d.ts.map