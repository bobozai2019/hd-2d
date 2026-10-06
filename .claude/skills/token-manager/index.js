import { TokenEstimator } from './src/token-estimator.js';
import { TokenTracker } from './src/token-tracker.js';
import { AutoSummarizer } from './src/auto-summarizer.js';
import { ConfigManager } from './src/config-manager.js';
/**
 * Main Token Manager class
 * Provides a unified interface for token estimation, tracking, and auto-summarization
 */
export class TokenManager {
    estimator;
    tracker;
    summarizer;
    configManager;
    constructor(options = {}) {
        this.estimator = new TokenEstimator(options.estimationConfig);
        this.configManager = new ConfigManager(options.estimationConfig, options.trackingConfig);
        const trackingConfig = this.configManager.getTrackingConfig();
        this.tracker = new TokenTracker(this.estimator, trackingConfig);
        this.summarizer = new AutoSummarizer(trackingConfig.autoSummaryThreshold);
    }
    /**
     * Estimate tokens for text
     */
    estimateTokens(text) {
        return this.estimator.estimateTokens(text);
    }
    /**
     * Estimate tokens for messages
     */
    estimateMessagesTokens(messages) {
        return this.estimator.estimateMessagesTokens(messages);
    }
    /**
     * Add chat message to session
     */
    addChatMessage(session, role, content) {
        this.tracker.addChatMessage(session, role, content);
    }
    /**
     * Recalculate tokens for session
     */
    recalculateTokens(session) {
        this.tracker.recalculateTokens(session);
    }
    /**
     * Cleanup session based on limits
     */
    cleanupSession(session) {
        this.tracker.cleanupSession(session);
    }
    /**
     * Check if auto-summarization should be triggered
     */
    shouldAutoSummarize(currentTokens, maxTokens, threshold) {
        return this.summarizer.shouldAutoSummarize(currentTokens, maxTokens, threshold);
    }
    /**
     * Generate summarization prompt
     */
    generateSummaryPrompt(currentTokens, maxTokens, userMessage) {
        return this.summarizer.generateSummaryPrompt(currentTokens, maxTokens, userMessage);
    }
    /**
     * Generate manual summarization prompt
     */
    generateManualSummaryPrompt(currentTokens, maxTokens) {
        return this.summarizer.generateManualSummaryPrompt(currentTokens, maxTokens);
    }
    /**
     * Get token statistics
     */
    getTokenStats(currentTokens, maxTokens, messageCount, maxHistoryLength) {
        return this.configManager.getTokenStats(currentTokens, maxTokens, messageCount, maxHistoryLength);
    }
    /**
     * Format token usage for display
     */
    formatTokenUsage(currentTokens, maxTokens) {
        return this.configManager.formatTokenUsage(currentTokens, maxTokens);
    }
    /**
     * Set token limit
     */
    setTokenLimit(limit) {
        return this.configManager.setTokenLimit(limit);
    }
    /**
     * Set auto-summary threshold
     */
    setAutoSummaryThreshold(threshold) {
        return this.configManager.setAutoSummaryThreshold(threshold);
    }
    /**
     * Set max history length
     */
    setMaxHistoryLength(length) {
        return this.configManager.setMaxHistoryLength(length);
    }
    /**
     * Get configuration
     */
    getConfiguration() {
        return {
            estimation: this.configManager.getEstimationConfig(),
            tracking: this.configManager.getTrackingConfig(),
        };
    }
    /**
     * Update configuration
     */
    updateConfiguration(estimationConfig, trackingConfig) {
        if (estimationConfig) {
            this.configManager.updateEstimationConfig(estimationConfig);
            this.estimator.updateConfig(estimationConfig);
        }
        if (trackingConfig) {
            this.configManager.updateTrackingConfig(trackingConfig);
            // Update tracker with new tracking config
            const currentTrackingConfig = this.configManager.getTrackingConfig();
            this.tracker.updateConfig(currentTrackingConfig);
            // Update summarizer with new threshold
            if (trackingConfig.autoSummaryThreshold !== undefined) {
                this.summarizer.updateConfig(trackingConfig.autoSummaryThreshold);
            }
        }
    }
}
/**
 * Default export for convenience
 */
export default TokenManager;
/**
 * Helper function to create a TokenManager instance
 */
export function createTokenManager(options = {}) {
    return new TokenManager(options);
}
//# sourceMappingURL=index.js.map