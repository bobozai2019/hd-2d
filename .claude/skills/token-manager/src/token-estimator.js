/**
 * Default token estimation configuration
 */
const DEFAULT_ESTIMATION_CONFIG = {
    chineseMultiplier: 2,
    otherMultiplier: 0.25,
};
/**
 * Token estimator for calculating approximate token counts
 */
export class TokenEstimator {
    config;
    constructor(config = {}) {
        this.config = { ...DEFAULT_ESTIMATION_CONFIG, ...config };
    }
    /**
     * Estimate token count for a text string
     */
    estimateTokens(text) {
        if (!text || text.length === 0)
            return 0;
        // Count Chinese characters (CJK Unified Ideographs)
        const chineseRegex = /[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff]/g;
        const chineseMatches = text.match(chineseRegex);
        const chineseChars = chineseMatches ? chineseMatches.length : 0;
        // Count other characters
        const otherChars = text.length - chineseChars;
        // Calculate estimated tokens
        return Math.ceil(chineseChars * this.config.chineseMultiplier +
            otherChars * this.config.otherMultiplier);
    }
    /**
     * Estimate token count for an array of messages
     */
    estimateMessagesTokens(messages) {
        if (!messages || messages.length === 0)
            return 0;
        return messages.reduce((total, msg) => total + this.estimateTokens(msg.content), 0);
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
//# sourceMappingURL=token-estimator.js.map