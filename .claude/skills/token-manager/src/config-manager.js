/**
 * Configuration manager for token management
 */
export class ConfigManager {
    estimationConfig;
    trackingConfig;
    constructor(estimationConfig = {}, trackingConfig = {}) {
        this.estimationConfig = {
            chineseMultiplier: 2,
            otherMultiplier: 0.25,
            ...estimationConfig,
        };
        this.trackingConfig = {
            maxTokensLimit: 80000,
            autoSummaryThreshold: 0.8,
            maxHistoryLength: 100,
            ...trackingConfig,
        };
    }
    /**
     * Get token usage statistics
     */
    getTokenStats(currentTokens, maxTokens, messageCount, maxHistoryLength) {
        const usagePercentage = maxTokens > 0 ? (currentTokens / maxTokens) * 100 : 0;
        const isNearLimit = maxTokens > 0 &&
            currentTokens > maxTokens * this.trackingConfig.autoSummaryThreshold;
        return {
            currentTokens,
            maxTokensLimit: maxTokens,
            usagePercentage,
            messageCount,
            maxHistoryLength: maxHistoryLength || this.trackingConfig.maxHistoryLength,
            isNearLimit,
            autoSummaryThreshold: this.trackingConfig.autoSummaryThreshold,
        };
    }
    /**
     * Format token usage for display
     */
    formatTokenUsage(currentTokens, maxTokens) {
        if (maxTokens <= 0) {
            return `当前: ${currentTokens} tokens (无限制)`;
        }
        const percent = Math.round((currentTokens / maxTokens) * 100);
        return `当前: ${currentTokens} tokens / 限制: ${maxTokens} tokens (${percent}%)`;
    }
    /**
     * Validate and set token limit
     */
    setTokenLimit(limit) {
        if (isNaN(limit) || limit < 0) {
            return { valid: false, error: '请输入有效的非负整数' };
        }
        this.trackingConfig.maxTokensLimit = limit;
        return { valid: true };
    }
    /**
     * Validate and set auto-summary threshold
     */
    setAutoSummaryThreshold(threshold) {
        if (isNaN(threshold) || threshold < 0 || threshold > 1) {
            return { valid: false, error: '阈值必须在0到1之间' };
        }
        this.trackingConfig.autoSummaryThreshold = threshold;
        return { valid: true };
    }
    /**
     * Validate and set max history length
     */
    setMaxHistoryLength(length) {
        if (isNaN(length) || length <= 0) {
            return { valid: false, error: '历史长度必须是正整数' };
        }
        this.trackingConfig.maxHistoryLength = length;
        return { valid: true };
    }
    /**
     * Get estimation configuration
     */
    getEstimationConfig() {
        return { ...this.estimationConfig };
    }
    /**
     * Get tracking configuration
     */
    getTrackingConfig() {
        return { ...this.trackingConfig };
    }
    /**
     * Update estimation configuration
     */
    updateEstimationConfig(config) {
        this.estimationConfig = { ...this.estimationConfig, ...config };
    }
    /**
     * Update tracking configuration
     */
    updateTrackingConfig(config) {
        this.trackingConfig = { ...this.trackingConfig, ...config };
    }
}
//# sourceMappingURL=config-manager.js.map