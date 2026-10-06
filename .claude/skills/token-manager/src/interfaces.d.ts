/**
 * Token estimation configuration
 */
export interface TokenEstimationConfig {
    /** Multiplier for Chinese characters (default: 2) */
    chineseMultiplier: number;
    /** Multiplier for other characters (default: 0.25) */
    otherMultiplier: number;
}
/**
 * Token tracking configuration
 */
export interface TokenTrackingConfig {
    /** Maximum token limit (0 for unlimited) */
    maxTokensLimit: number;
    /** Auto-summarization threshold (0-1, default: 0.8) */
    autoSummaryThreshold: number;
    /** Maximum history length (message count) */
    maxHistoryLength: number;
}
/**
 * Chat message with token information
 */
export interface ChatMessage {
    role: 'user' | 'assistant';
    content: string;
    timestamp: number;
    tokens?: number;
}
/**
 * Session data for token management
 */
export interface TokenSession {
    chatHistory: ChatMessage[];
    maxTokensLimit?: number;
    currentTokens?: number;
    maxHistoryLength?: number;
}
/**
 * Token usage statistics
 */
export interface TokenStats {
    currentTokens: number;
    maxTokensLimit: number;
    usagePercentage: number;
    messageCount: number;
    maxHistoryLength: number;
    isNearLimit: boolean;
    autoSummaryThreshold: number;
}
/**
 * Auto-summarization result
 */
export interface AutoSummaryCheck {
    shouldSummarize: boolean;
    usagePercentage: number;
    historyTokens: number;
    maxTokens: number;
    threshold: number;
}
/**
 * Token manager options
 */
export interface TokenManagerOptions {
    estimationConfig?: Partial<TokenEstimationConfig>;
    trackingConfig?: Partial<TokenTrackingConfig>;
}
//# sourceMappingURL=interfaces.d.ts.map