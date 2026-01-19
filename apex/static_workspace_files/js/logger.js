// Initialize namespace
var namespace = namespace || {};

/**
 * ==========================================================================
 * @module logger
 * ==========================================================================
 * @author Angel O. Flores Torres
 * @created 2025
 * @version 1.0
 */
// Create object for logger functions
namespace.logger = (function (namespace) {
  'use strict';

  // Configuration - Use live config from logger-config (single source of truth)
  var config = namespace.loggerConfig.getCurrentConfig();

  // Private variables
  var timingUnits = {};

  // Log levels - Use from logger-config
  var LOG_LEVELS = namespace.loggerConfig.LOG_LEVELS;

  /* ================================================================================================= */
  /* ================================================================================================= */
  /*                                           PRIVATE FUNCTIONS                                       */
  /* ================================================================================================= */

  /**
   * Check if a log level should be logged based on current configuration
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string|number} level - The log level to check
   *
   * @returns {boolean} - Whether the level should be logged
   */
  var _shouldLog = function (level) {
    var levelNum = typeof level === 'string' ? LOG_LEVELS[level.toUpperCase()] : level;
    var configNum = LOG_LEVELS[config.level.toUpperCase()];

    // OFF blocks everything - no logging at all
    if (configNum === LOG_LEVELS.OFF) {
      return false;
    }

    // If level is undefined, don't log (invalid level)
    if (levelNum === undefined) {
      return false;
    }

    // Only log if log level is less than or equal to configured level
    return levelNum <= configNum;
  };









  /* ================================================================================================= */
  /**
   * Send log entry to server via AJAX with enhanced error handling
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {Object} logEntry - The log entry to send
   */
  var _sendToServer = function (logEntry) {
    if (!config.enableServer) return;

    var retryAttempts = config.retryAttemptInitial || 0;
    var maxRetries = config.retryCount || 1;

    var attemptSend = function () {
      try {
        var processName = config.serverProcessName || 'JS_LOGGER';
        var defaultModule = config.defaultModuleName || 'JS_LOGGER';
        var retryDelayBase = config.retryDelayBase || 1000;

        apex.server.process(processName, {
          x01: logEntry.level,
          x02: logEntry.text,
          x03: logEntry.module || defaultModule,
          x04: JSON.stringify(logEntry.extra || {}),
          x05: logEntry.timestamp,
          x06: logEntry.user,
          x07: logEntry.page,
          x08: logEntry.session
        }, {
          success: function () {
            // Success - reset any error flags
            config._serverError = false;
          },
          error: function () {
            retryAttempts++;
            if (retryAttempts <= maxRetries) {
              // Exponential backoff retry
              setTimeout(attemptSend, retryDelayBase * retryAttempts);
            } else {
              // Mark server as failed, switch to console-only mode
              config._serverError = true;
              console.warn('Logger server failed, using console fallback');
              console.log(_formatConsoleMessage(logEntry));
            }
          }
        });
      } catch (e) {
        // APEX not available or other critical error
        config._serverError = true;
        console.error('Logger server error:', e.message);
        console.log(_formatConsoleMessage(logEntry));
      }
    };

    attemptSend();
  };









  /* ================================================================================================= */
  /**
   * Output log entry to console with colors and appropriate console method
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {Object} logEntry - The log entry to output
   */
  var _outputToConsole = function (logEntry) {
    var timestamp = new Date(logEntry.timestamp).toLocaleTimeString();
    var level = logEntry.level.toUpperCase();
    var module = logEntry.module ? `[${logEntry.module}]` : '';

    // Get styles from config (single source of truth)
    var consoleConfig = namespace.loggerConfig.getConsoleConfig();
    var styles = consoleConfig.levelStyles;

    // Prepare console arguments - log extra data as separate argument for better formatting
    var message = `%c[${timestamp}] ${level}%c ${module} ${logEntry.text}`;
    var consoleArgs = [message, styles[level] || styles.INFORMATION, 'color: inherit'];

    // Add extra data as separate argument so browser can format it nicely
    if (logEntry.extra) {
      consoleArgs.push(logEntry.extra);
    }

    // Use appropriate console method with styles from config
    switch (level) {
      case 'ERROR':
        console.error.apply(console, consoleArgs);
        break;
      case 'WARNING':
        console.warn.apply(console, consoleArgs);
        break;
      case 'TIMING':
        console.log.apply(console, consoleArgs);
        break;
      case 'INFORMATION': // this is the default level logger.log
      default:
        console.log.apply(console, consoleArgs);
        break;
    }
  };









  /* ================================================================================================= */
  /**
   * Format log entry for console output (fallback for server errors)
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {Object} logEntry - The log entry to format
   *
   * @returns {string} - Formatted log message
   */
  var _formatConsoleMessage = function (logEntry) {
    var timestamp = new Date(logEntry.timestamp).toLocaleTimeString();
    var level = logEntry.level.toUpperCase();
    var module = logEntry.module ? `[${logEntry.module}]` : '';
    var extra = logEntry.extra ? ` ${JSON.stringify(logEntry.extra)}` : '';

    return `[${timestamp}] ${level} ${module} ${logEntry.text}${extra}`;
  };









  /* ================================================================================================= */
  /**
   * Sanitize data to prevent issues with circular references and size limits
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {*} data - The data to sanitize
   *
   * @returns {*} - Sanitized data
   */
  var _sanitizeData = function (data) {
    if (!data) return data;

    try {
      // Check for circular references
      JSON.stringify(data);

      // Check size limit
      var dataStr = JSON.stringify(data);
      if (dataStr.length > config.maxDataSize) {
        return {
          _truncated: true,
          _originalSize: dataStr.length,
          data: dataStr.substring(0, config.maxDataSize) + '...'
        };
      }

      // Mask sensitive fields
      return _maskSensitiveFields(data);

    } catch (e) {
      // Circular reference or other JSON error
      var maxErrorLength = config.maxErrorStringLength || 100;
      return {
        _error: 'Could not serialize data',
        _type: typeof data,
        _string: String(data).substring(0, maxErrorLength)
      };
    }
  };









  /* ================================================================================================= */
  /**
   * Mask sensitive fields in data
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {*} data - The data to mask
   *
   * @returns {*} - Data with sensitive fields masked
   */
  var _maskSensitiveFields = function (data) {
    if (!config.enableDataMasking || !data || typeof data !== 'object') {
      return data;
    }

    var sensitiveFields = config.sensitiveFields || ['password', 'token', 'ssn'];
    var masked = {};

    for (var key in data) {
      if (data.hasOwnProperty(key)) {
        var lowerKey = key.toLowerCase();
        var isSensitive = sensitiveFields.some(function (field) {
          return lowerKey.includes(field);
        });

        if (isSensitive) {
          masked[key] = '***MASKED***';
        } else {
          masked[key] = data[key];
        }
      }
    }

    return masked;
  };









  /* ================================================================================================= */
  /**
   * Create log entry object with enhanced features
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} text - The log message
   * @param {string} module - The module name
   * @param {Object} extra - Extra data
   * @param {string} level - The log level
   *
   * @returns {Object} - Formatted log entry
   */
  var _createLogEntry = function (text, module, extra, level) {
    var defaultUser = config.defaultUserName || 'UNKNOWN';
    var logEntry = {
      timestamp: new Date().toISOString(),
      level: level || 'INFORMATION',
      text: text,
      module: module,
      extra: _sanitizeData(extra),
      user: (typeof apex !== 'undefined' && apex.env && apex.env.APP_USER) || defaultUser,
      page: (typeof apex !== 'undefined' && apex.env && apex.env.APP_PAGE_ID) || 0,
      session: (typeof apex !== 'undefined' && apex.env && apex.env.APP_SESSION) || 0
    };

    return logEntry;
  };

  /* ================================================================================================= */
  /*                                            PUBLIC FUNCTIONS                                       */
  /* ================================================================================================= */

  /**
   * Console logging function with optional server storage - Always INFORMATION level
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} text - The log message
   * @param {string} module - The module name
   * @param {Object} extra - Extra data
   * @param {Object} options - Optional configuration
   * @param {boolean} options.sendToServer - If true, also send to server (default: false)
   */
  var log = function (text, module, extra, options) {
    try {
      var opts = options || {};
      var sendToServer = opts.sendToServer === true;

      var logEntry = _createLogEntry(text, module, extra, 'INFORMATION');

      // Console output respects level filtering
      if (_shouldLog(logEntry.level)) {
        _outputToConsole(logEntry);
      }

      // Optionally send to server (bypasses level check)
      if (sendToServer && config.enableServer) {
        _sendToServer(logEntry);
      }
    } catch (e) {
      // Fallback logging if main logging fails
      if (typeof console !== 'undefined') {
        console.error('Logger error:', e.message);
        console.log('Original message:', text);
      }
    }
  };









  /* ================================================================================================= */
  /**
   * Server logging function (includes database storage) - Always INFORMATION level
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} text - The log message
   * @param {string} module - The module name
   * @param {Object} extra - Extra data
   */
  var logServer = function (text, module, extra) {
    try {
      var logEntry = _createLogEntry(text, module, extra, 'INFORMATION');

      // Server logging bypasses level check - always send if enabled
      // This allows server logging even when console is disabled
      if (config.enableServer) {
        _sendToServer(logEntry);
      }

      // Console output respects level filtering
      if (_shouldLog(logEntry.level)) {
        _outputToConsole(logEntry);
      }
    } catch (e) {
      // Fallback logging if main logging fails
      if (typeof console !== 'undefined') {
        console.error('Logger server error:', e.message);
        console.log('Original message:', text);
      }
    }
  };









  /* ================================================================================================= */
  /**
   * Error logging with optional server storage - ERROR level
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} text - The error message
   * @param {string} module - The module name
   * @param {Object} extra - Extra data
   * @param {Object} options - Optional configuration
   * @param {boolean} options.sendToServer - If true, also send to server (default: false)
   */
  var error = function (text, module, extra, options) {
    try {
      var opts = options || {};
      var sendToServer = opts.sendToServer === true;

      var logEntry = _createLogEntry(text, module, extra, 'ERROR');

      // Console output respects level filtering
      if (_shouldLog(logEntry.level)) {
        _outputToConsole(logEntry);
      }

      // Optionally send to server (bypasses level check)
      if (sendToServer && config.enableServer) {
        _sendToServer(logEntry);
      }
    } catch (e) {
      // Fallback logging if main logging fails
      if (typeof console !== 'undefined') {
        console.error('Logger error:', e.message);
        console.log('Original message:', text);
      }
    }
  };









  /* ================================================================================================= */
  /**
   * Warning logging with optional server storage - WARNING level
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} text - The warning message
   * @param {string} module - The module name
   * @param {Object} extra - Extra data
   * @param {Object} options - Optional configuration
   * @param {boolean} options.sendToServer - If true, also send to server (default: false)
   */
  var warning = function (text, module, extra, options) {
    try {
      var opts = options || {};
      var sendToServer = opts.sendToServer === true;

      var logEntry = _createLogEntry(text, module, extra, 'WARNING');

      // Console output respects level filtering
      if (_shouldLog(logEntry.level)) {
        _outputToConsole(logEntry);
      }

      // Optionally send to server (bypasses level check)
      if (sendToServer && config.enableServer) {
        _sendToServer(logEntry);
      }
    } catch (e) {
      // Fallback logging if main logging fails
      if (typeof console !== 'undefined') {
        console.error('Logger error:', e.message);
        console.log('Original message:', text);
      }
    }
  };









  /* ================================================================================================= */
  /**
   * Start timing for a unit
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} unit - The timing unit name
   */
  var timeStart = function (unit) {
    timingUnits[unit] = performance.now();
  };









  /* ================================================================================================= */
  /**
   * Stop timing for a unit and log the result (console-only)
   * @param {string} unit - The timing unit name
   * @param {string} module - The module name
   * @returns {number} - Time elapsed in milliseconds
   */
  var timeStop = function (unit, module) {
    if (!timingUnits[unit]) {
      console.warn(`Timing unit '${unit}' was not started`);
      return 0;
    }

    var elapsed = performance.now() - timingUnits[unit];
    var decimalPlaces = config.timingDecimalPlaces || 2;
    var message = `${unit} completed in ${elapsed.toFixed(decimalPlaces)}ms`;

    log(message, module, { unit: unit, elapsed: elapsed });

    delete timingUnits[unit];
    return elapsed;
  };




























  /* ================================================================================================= */
  /**
   * Create a module logger with pre-configured scope and persistent extra data
   * @author Angel O. Flores Torres
   * @created 2025
   *
   * @param {string} moduleName - The module name (becomes the scope)
   * @returns {Object} - Module logger with all logging methods
   */
  var createModuleLogger = function (moduleName) {
    var moduleExtra = {};  // Persistent extra data for this module

    return {
      setExtra: function (extraData) {
        moduleExtra = extraData || {};
      },
      clearExtra: function () {
        moduleExtra = {};
      },
      getExtra: function () {
        return Object.assign({}, moduleExtra);
      },
      log: function (text, extra, options) {
        var combinedExtra = Object.assign({}, moduleExtra, extra || {});
        log(text, moduleName, combinedExtra, options);
      },
      error: function (text, extra, options) {
        var combinedExtra = Object.assign({}, moduleExtra, extra || {});
        error(text, moduleName, combinedExtra, options);
      },
      warning: function (text, extra, options) {
        var combinedExtra = Object.assign({}, moduleExtra, extra || {});
        warning(text, moduleName, combinedExtra, options);
      },
      logServer: function (text, extra) {
        var combinedExtra = Object.assign({}, moduleExtra, extra || {});
        logServer(text, moduleName, combinedExtra);
      },
      timeStart: function (unit) {
        timeStart(unit);
      },
      timeStop: function (unit) {
        return timeStop(unit, moduleName);
      }
    };
  };





  /* ================================================================================================= */
  /* Return public API */
  /* ================================================================================================= */
  return {
    // Console-only logging functions
    log: log, //  namespace.logger.log("API response received", "ajax", { status: 200, data: "success" });
    error: error, // namespace.logger.error("Validation failed", "form-validation", { field: "email", value: "" });
    warning: warning, // namespace.logger.warning("Deprecated function used", "legacy-code", { function: "oldMethod" });

    // Server logging functions (includes database storage)
    logServer: logServer, // namespace.logger.logServer("User login successful", "authentication", { userId: 123, ip: "192.168.1.1" });

    // Timing functions
    timeStart: timeStart, // namespace.logger.timeStart("page-load");
    timeStop: timeStop, // namespace.logger.timeStop("page-load", "performance");



    // Module logger factory
    createModuleLogger: createModuleLogger // var logger = namespace.logger.createModuleLogger('PaymentModule');

  };


})(namespace);
