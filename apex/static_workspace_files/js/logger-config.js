// Initialize namespace
var namespace = namespace || {};

/**
 * ==========================================================================
 * @module logger-config
 * ==========================================================================
 * @author Angel O. Flores Torres
 * @created 2025
 * @version 1.0
 */
// Create object for logger configuration
namespace.loggerConfig = (function (namespace, undefined) {
  'use strict';

  /* ================================================================================================= */
  // Default configuration values
  // All configuration should be set here - logger.js reads from this config
  var DEFAULT_CONFIG = {
    // Logging behavior
    level:                  'INFORMATION',        // Console log level - values: OFF (disables console only), ERROR, WARNING, INFORMATION (logServer() bypasses this)
    enableServer:           false,                 // Enable server logging (database storage) - works independently of level setting

    // Server logging configuration
    serverProcessName:     'JS_LOGGER',          // APEX process name for server logging
    retryCount:             1,                    // Maximum number of retry attempts for server logging
    retryAttemptInitial:    0,                    // Initial retry attempt counter (usually 0)
    retryDelayBase:         1000,                 // Base delay in milliseconds for exponential backoff retry

    // Default values
    defaultModuleName:      'JS_LOGGER',          // Default module name when not provided in log calls
    defaultUserName:        'UNKNOWN',            // Default user name when APEX context not available

    // Security and data handling
    enableDataMasking:      true,                 // Enable masking of sensitive fields
    sensitiveFields:        ['password', 'token', 'ssn'],  // Fields to mask in log data
    maxDataSize:            10000,                // Maximum data size in bytes before truncation
    maxErrorStringLength:    100,                  // Maximum length for error string display

    // Timing configuration
    timingDecimalPlaces:    2                    // Decimal places for timing display (e.g., "123.45ms")
  };

  // Current active configuration (this is the single source of truth)
  var currentConfig = Object.assign({}, DEFAULT_CONFIG);









  /* ================================================================================================= */
  // Log level constants (only implemented levels)
  var LOG_LEVELS = {
    OFF:          0,  // Blocks console output only - server logging still works if enableServer is true
    ERROR:        2,  // logger.error() method
    WARNING:      4,  // logger.warning() method
    INFORMATION:  8,  // logger.log() and logger.logServer() methods (default)
    TIMING:      32   // Has styling but timeStop() uses INFORMATION level
  };









  /* ================================================================================================= */
  // Environment-specific configurations
  var ENV_CONFIGS = {
    development: {
      level: 'INFORMATION',
      enableServer: false,
      enableDataMasking: false, // Less strict in dev
      maxDataSize: 50000, // Larger in dev for debugging
      serverProcessName: 'LOG_ENTRY_DEV' // Optional: different process for dev
    },
    testing: {
      level: 'INFORMATION',
      enableServer: true,
      enableDataMasking: true,
      maxDataSize: 20000,
      serverProcessName: 'LOG_ENTRY' // Can use same or different process
    },
    production: {
      level: 'WARNING',  // Only show warnings and errors in production
      enableServer: true,
      enableDataMasking: true, // Strict in production
      sensitiveFields: ['password', 'token', 'ssn', 'credit_card', 'api_key'],
      maxDataSize: 5000, // Smaller in production
      serverProcessName: 'LOG_ENTRY' // Production process name
    }
  };









  /* ================================================================================================= */
  // Console formatting options
  var CONSOLE_CONFIG = {
    showTimestamp: true,
    showLevel: true,
    showScope: true,
    showExtra: true,
    timestampFormat: 'HH:mm:ss',
    levelStyles: {
      ERROR: 'color: #ff9999; font-weight: bold',        // Soft red
      WARNING: 'color: #ffcc99; font-weight: bold',      // Soft orange
      INFORMATION: 'color: #99ccff; font-weight: bold',  // Soft blue
      TIMING: 'color: #99cc99; font-weight: bold'       // Soft green
    }
  };









  /* ================================================================================================= */
  /**
   * Get environment-specific configuration
   * @param {string} environment - The environment name
   * @returns {Object} - Environment configuration
   */
  var getEnvConfig = function (environment) {
    return Object.assign({}, DEFAULT_CONFIG, ENV_CONFIGS[environment] || {});
  };









  /* ================================================================================================= */
  /**
   * Get console configuration
   * @returns {Object} - Console config
   */
  var getConsoleConfig = function () {
    return Object.assign({}, CONSOLE_CONFIG);
  };



























  /* ================================================================================================= */
  /**
   * Get current active configuration (used by logger.js)
   * @returns {Object} - Current active configuration
   */
  var getCurrentConfig = function () {
    return currentConfig; // Return reference, not copy, so logger.js uses live config
  };

  /**
   * Get enhanced default configuration with new options
   * @returns {Object} - Enhanced default configuration
   */
  var getEnhancedConfig = function () {
    return Object.assign({}, currentConfig); // Return current config, not default
  };









  /* ================================================================================================= */
  /**
   * Set log level
   * @param {string} level - The log level to set
   */
  var setLevel = function (level) {
    if (LOG_LEVELS[level.toUpperCase()] !== undefined) {
      currentConfig.level = level.toUpperCase();
    } else {
      console.warn('Invalid log level: ' + level);
    }
  };









  /* ================================================================================================= */
  /**
   * Get current log level
   * @returns {string} - Current log level
   */
  var getLevel = function () {
    return currentConfig.level;
  };




  /* ================================================================================================= */
  /**
   * Reset log level to default (INFORMATION)
   * Convenient way to restore default logging after changing level
   */
  var resetLevel = function () {
    currentConfig.level = DEFAULT_CONFIG.level;
  };









  /* ================================================================================================= */
  /**
   * Configure logger options
   * @param {Object} options - Configuration options
   */
  var configure = function (options) {
    Object.assign(currentConfig, options);
  };









  /* ================================================================================================= */
  /**
   * Get current configuration
   * @returns {Object} - Current configuration
   */
  var getConfig = function () {
    return Object.assign({}, currentConfig);
  };











  /* ================================================================================================= */
  /* Return public API */
  /* ================================================================================================= */
  return {
    // Configuration functions
    getEnvConfig: getEnvConfig,
    getConsoleConfig: getConsoleConfig,
    getEnhancedConfig: getEnhancedConfig,
    getCurrentConfig: getCurrentConfig,

    // Logger control functions (moved from logger.js)
    setLevel: setLevel,
    getLevel: getLevel,
    resetLevel: resetLevel,
    configure: configure,
    getConfig: getConfig,

    // Constants
    LOG_LEVELS: LOG_LEVELS
  };

})(namespace);
