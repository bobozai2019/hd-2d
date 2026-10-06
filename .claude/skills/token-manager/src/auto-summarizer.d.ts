import { AutoSummaryCheck } from './interfaces.js';
/**
 * Auto-summarizer for managing conversation summarization triggers
 */
export declare class AutoSummarizer {
    private config;
    constructor(threshold?: number);
    /**
     * Check if auto-summarization should be triggered
     */
    shouldAutoSummarize(currentTokens: number, maxTokens: number, threshold?: number): AutoSummaryCheck;
    /**
     * Check if token usage is high (above threshold)
     */
    isTokenUsageHigh(currentTokens: number, maxTokens: number, threshold?: number): boolean;
    /**
     * Generate summarization prompt
     */
    generateSummaryPrompt(currentTokens: number, maxTokens: number, userMessage?: string): string;
    /**
     * Generate manual summarization prompt
     */
    generateManualSummaryPrompt(currentTokens: number, maxTokens: number): string;
    /**
     * Update configuration
     */
    updateConfig(threshold: number): void;
    /**
     * Get current configuration
     */
    getConfig(): {
        threshold: number;
    };
}
//# sourceMappingURL=auto-summarizer.d.ts.map