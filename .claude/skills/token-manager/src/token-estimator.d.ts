import { TokenEstimationConfig } from './interfaces.js';
/**
 * Token estimator for calculating approximate token counts
 */
export declare class TokenEstimator {
    private config;
    constructor(config?: Partial<TokenEstimationConfig>);
    /**
     * Estimate token count for a text string
     */
    estimateTokens(text: string): number;
    /**
     * Estimate token count for an array of messages
     */
    estimateMessagesTokens(messages: Array<{
        content: string;
    }>): number;
    /**
     * Update configuration
     */
    updateConfig(config: Partial<TokenEstimationConfig>): void;
    /**
     * Get current configuration
     */
    getConfig(): TokenEstimationConfig;
}
//# sourceMappingURL=token-estimator.d.ts.map