/**
 * Default configuration for auto-summarization
 */
const DEFAULT_AUTO_SUMMARY_CONFIG = {
    threshold: 0.8,
};
/**
 * Auto-summarizer for managing conversation summarization triggers
 */
export class AutoSummarizer {
    config;
    constructor(threshold = DEFAULT_AUTO_SUMMARY_CONFIG.threshold) {
        this.config = { threshold };
    }
    /**
     * Check if auto-summarization should be triggered
     */
    shouldAutoSummarize(currentTokens, maxTokens, threshold) {
        const effectiveThreshold = threshold ?? this.config.threshold;
        if (maxTokens <= 0) {
            return {
                shouldSummarize: false,
                usagePercentage: 0,
                historyTokens: currentTokens,
                maxTokens,
                threshold: effectiveThreshold,
            };
        }
        const usagePercentage = currentTokens / maxTokens;
        const shouldSummarize = usagePercentage > effectiveThreshold;
        return {
            shouldSummarize,
            usagePercentage,
            historyTokens: currentTokens,
            maxTokens,
            threshold: effectiveThreshold,
        };
    }
    /**
     * Check if token usage is high (above threshold)
     */
    isTokenUsageHigh(currentTokens, maxTokens, threshold) {
        if (maxTokens <= 0)
            return false;
        const effectiveThreshold = threshold ?? this.config.threshold;
        return currentTokens > maxTokens * effectiveThreshold;
    }
    /**
     * Generate summarization prompt
     */
    generateSummaryPrompt(currentTokens, maxTokens, userMessage) {
        const usagePercent = Math.round((currentTokens / maxTokens) * 100);
        let prompt = `对话已较长（当前使用 ${currentTokens} tokens，限制 ${maxTokens} tokens，使用率 ${usagePercent}%）。请先用一段话总结之前的对话要点`;
        if (userMessage) {
            prompt += `，然后继续处理当前请求。\n\n当前请求：${userMessage}`;
        }
        else {
            prompt += '，然后说明你已准备好继续对话。';
        }
        return prompt;
    }
    /**
     * Generate manual summarization prompt
     */
    generateManualSummaryPrompt(currentTokens, maxTokens) {
        if (maxTokens > 0) {
            return `对话已较长（当前使用 ${currentTokens} tokens，限制 ${maxTokens} tokens）。请先用一段话总结之前的对话要点，然后说明你已准备好继续对话。`;
        }
        return `对话已较长（当前使用 ${currentTokens} tokens）。请先用一段话总结之前的对话要点，然后说明你已准备好继续对话。`;
    }
    /**
     * Update configuration
     */
    updateConfig(threshold) {
        if (threshold >= 0 && threshold <= 1) {
            this.config.threshold = threshold;
        }
    }
    /**
     * Get current configuration
     */
    getConfig() {
        return { ...this.config };
    }
}
//# sourceMappingURL=auto-summarizer.js.map