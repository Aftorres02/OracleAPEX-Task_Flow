// Initialize namespace
var namespace = namespace || {};

/**
 * ==========================================================================
 * @module utilities
 * ==========================================================================
 */
// Create object for utility functions
namespace.utilities = (function(namespace, $, undefined) {
  'use strict';


  // Dynamic module logger management
  var moduleName = 'Utilities';
  var logger = namespace.logger ? namespace.logger.createModuleLogger(moduleName) : null;

  var setModule = function(name) {
        moduleName = typeof name === 'string' && name.trim() ? name : moduleName;
        logger = namespace.logger ? namespace.logger.createModuleLogger(moduleName) : null;
      };





  /* ================================================================ */
  /**
 * Copy text to clipboard with modern API
 * @param {string} text - The text to copy
 * @param {Event} event - The click event (optional, for visual feedback)
 * @param {Object} options - Configuration options forwarded to feedback (see showCopyFeedback defaults)
  * @param {string} [options.successText] - Optional tooltip/text to show temporarily (e.g., 'Copied')
 * @returns {Promise<boolean>} - Success status
 */
  var copyToClipboard = function(text, event, options) {
    // Normalize options: use provided object or fallback to empty
    var opts = (options && typeof options === 'object') ? options : {};

    logger.log('Copying to clipboard', {text: text});

    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).then(function() {
        if (event) {
          showCopyFeedback(event, opts);
        }

        return true;
      }).catch(function(err) {
        logger.error('Clipboard failed', {error: err.message});
        return false;
      });
    } else {
      logger.warning('Clipboard API not supported');
      return Promise.resolve(false);
    }
  };







  /* ================================================================ */
  /**
 * Show visual feedback when copying text
 * @param {Event} event - The click event
 * @param {Object} options - Feedback options
 * @param {string} options.buttonSelector - CSS selector for the copy button
 * @param {string} options.successColor - Color to show on success
 * @param {string} options.successIcon - Icon class to show on success
 * @param {string} [options.successText] - Optional tooltip/text to show temporarily (e.g., 'Copied')
 */
  var showCopyFeedback = function(event, options) {
    var opts = options || {};
    var selector = opts.buttonSelector || '.copy-ticket-btn, .copy-btn';
    var successColor = opts.successColor || '#28a745';
    var successIcon = opts.successIcon || 'fa fa-check';
    var successText = opts.successText || 'Copied';

    var btn = event.target.closest(selector);
    if (!btn) return;

    var icon = btn.querySelector('i');
    if (!icon) return;

    // Use a single flag to control feedback lifecycle
    var isActive = btn.dataset.copyActive === '1';

    // If not active, capture originals; if active, keep existing originals
    if (!isActive) {
      btn.dataset.originalIconClass = icon.className;
      btn.dataset.originalColor = btn.style.color || '';
      btn.dataset.originalTitle = btn.getAttribute('title') || '';
    }

    // Cancel any pending restore and show success state
    if (btn.dataset.copyTimerId) {
      clearTimeout(Number(btn.dataset.copyTimerId));
      btn.dataset.copyTimerId = '';
    }

    icon.className = successIcon;
    btn.style.color = successColor;

    // Minimalistic tooltip-style feedback text (positioned fixed to avoid clipping)
    var textNode = null;
    if (successText) {
      textNode = document.querySelector('.copy-feedback-text[data-btn-id="' + (btn.id || btn.dataset.copyBtnId) + '"]');
      if (!textNode) {
        // Generate unique ID for button if needed
        if (!btn.id && !btn.dataset.copyBtnId) {
          btn.dataset.copyBtnId = 'copy-btn-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
        }
        var btnId = btn.id || btn.dataset.copyBtnId;
        
        textNode = document.createElement('span');
        textNode.className = 'copy-feedback-text';
        textNode.setAttribute('data-btn-id', btnId);
        // Use fixed positioning to avoid clipping by parent containers
        textNode.style.position = 'fixed';
        textNode.style.whiteSpace = 'nowrap';
        textNode.style.pointerEvents = 'none';
        // Minimalistic tooltip styling
        textNode.style.backgroundColor = '#333333';
        textNode.style.color = '#ffffff';
        textNode.style.padding = '3px 6px';
        textNode.style.borderRadius = '3px';
        textNode.style.fontSize = '11px';
        textNode.style.fontWeight = 'normal';
        textNode.style.zIndex = '10000';
        textNode.style.lineHeight = '1.3';
        document.body.appendChild(textNode);
      }
      textNode.textContent = successText;
      // Position relative to icon using viewport coordinates
      var iconRect = icon.getBoundingClientRect();
      var textHeight = textNode.offsetHeight || 18;
      textNode.style.left = (iconRect.right + 6) + 'px';
      textNode.style.top = (iconRect.top + (iconRect.height - textHeight) / 2) + 'px';
      textNode.style.display = 'block';
      
      // Check if tooltip would overflow right edge, position to left if needed
      setTimeout(function() {
        var textRect = textNode.getBoundingClientRect();
        if (textRect.right > window.innerWidth - 10) {
          // Position to left of icon instead
          textNode.style.left = (iconRect.left - textRect.width - 6) + 'px';
        }
      }, 0);
    }
    btn.dataset.copyActive = '1';

    // Schedule restore
    var timerId = setTimeout(function() {
      icon.className = btn.dataset.originalIconClass || icon.className;
      btn.style.color = btn.dataset.originalColor || '';
      btn.dataset.copyTimerId = '';
      btn.dataset.copyActive = '';
      btn.dataset.originalIconClass = '';
      btn.dataset.originalColor = '';
      // Remove tooltip from body if present
      var btnId = btn.id || btn.dataset.copyBtnId;
      if (btnId) {
        var existing = document.querySelector('.copy-feedback-text[data-btn-id="' + btnId + '"]');
        if (existing) {
          existing.remove();
        }
      }
    }, 1000);
    btn.dataset.copyTimerId = String(timerId);
  };








  /* ================================================================ */
  /* Return public API */
  /* ================================================================ */
  return {
    // Clipboard functions
    setModule: setModule,
    copyToClipboard: copyToClipboard
  };

})(namespace, window.jQuery || window.$ || function(){});
