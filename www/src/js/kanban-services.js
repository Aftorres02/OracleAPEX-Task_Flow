/*
 * ==========================================================================
 * KANBAN SERVICES
 * ==========================================================================
 *
 * @description Services and Business Logic for TaskFlow Kanban
 * @author Angel O. Flores Torres
 * @created 2024
 * @version 2.0
 */

// Initialize namespace
var namespace = namespace || {};







/**
 * ==========================================================================
 * @module kanbanServices
 * ==========================================================================
 */
namespace.kanbanServices = (function(namespace, $, undefined) {
  'use strict';
  
  var MODULE_NAME = 'KanbanServices';
  
  // Configuration constants
  var CONFIG = {
    ajaxGetTicketsForColumn: 'get_tickets_for_column_ajax'
  };

  // Create module-specific logger using enterprise logger
  var logger = namespace.logger ? namespace.logger.createModuleLogger(MODULE_NAME) : { log: function(){}, error: function(){}, warning: function(){} };






  /* ================================================================ */
  /* UTILITIES SECTION                                                */
  /* ================================================================ */


  /**
  * Copy text to clipboard with modern API
  * @param {string} text - The text to copy
  * @param {Event} event - The click event (optional, for visual feedback)
  * @returns {Promise<boolean>} - Success status
  */
  var copyToClipboard = function(text, event) {
    // Fixed defaults for this module
    var options = {
      buttonSelector: '.copy-ticket-btn',
      successColor: '#28a745',
      successIcon: 'fa fa-check',
      successText: 'Ticket Number Copied'
    };

    // Call utilities.copyToClipboard and return the promise
    if (namespace.utilities && typeof namespace.utilities.copyToClipboard === 'function') {
      return namespace.utilities.copyToClipboard(text, event, options);
    } else {
      logger.warning('namespace.utilities.copyToClipboard is not available');
      return Promise.resolve(false);
    }
  };








  /* ================================================================ */
  /* BUSINESS LOGIC SECTION                                           */
  /* ================================================================ */



  /**
   * Get tickets for a specific column via AJAX
   * @param {string} columnId - The column ID
   * @param {Function} callback - Callback function to handle tickets data
   */
  var getTicketsForColumn = function(columnId, filters, callback) {
    // Handle optional filters argument
    if (typeof filters === 'function') {
      callback = filters;
      filters = {};
    }
    filters = filters || {};

    logger.log('Getting tickets for column', {columnId: columnId, filters: filters});

    apex.server.process(
      CONFIG.ajaxGetTicketsForColumn,
      {
          x01: columnId
        , x02: filters.userIds // || '' // Pass userIds filter
        , x03: filters.ticketType // || '' // Pass ticketType filter
        , x04: filters.search  //|| '' // Pass search filter
        , x05: filters.priority // || '' // Pass priority filter
        , x06: filters.myTickets // || '' // Pass myTickets filter Y/N
      },
      {
        success: function(pData) {
          logger.log('Response for column', {columnId: columnId, success: pData.success, ticketCount: (pData.tickets || []).length});

          if (pData.success) {
            callback(pData.tickets || []);
          }
          else {
            logger.error('Error getting tickets for column', {columnId: columnId, error: pData.error_msg});
            callback([]);
          }
        },
        error: function(jqXHR, textStatus, errorThrown) {
          logger.error('AJAX error getting tickets for column', {columnId: columnId, status: textStatus, error: errorThrown});
          callback([]);
        }
      }
    );
  };








  /* ================================================================ */
  /**
   * Create HTML for a ticket card
   * @param {Object} ticket - Ticket data object
   * @returns {string} - HTML string for the ticket
   */
  var createTicketHTML = function(ticket) {
    var ticketNumber = ticket.TICKET_NUMBER;

    // Use Priority instead of Ticket Type as visually primary tag
    var priorityHtml = ticket.PRIORITY 
      ? `<div class="priority-tag ${ticket.PRIORITY.toLowerCase()}">${ticket.PRIORITY}</div>` 
      : '';
 
    var typeHtml = '';
    /*
    var typeHtml = ticket.TICKET_TYPE 
      ? `<div class="ticket-type-tag ${ticket.TICKET_TYPE.toLowerCase()}">${ticket.TICKET_TYPE}</div>` 
      : '';
    */

    // Note: Updated onclick to point to namespace.kanbanServices.copyToClipboard
    return `
      <div class="ticket-header">
        <div class="ticket-number-container">
          <div class="ticket-number" data-ticket-id="${ticket.TICKET_ID}">${ticketNumber}</div>
          <span class="copy-ticket-btn" onclick="namespace.kanbanServices.copyToClipboard('${ticketNumber}', event, 'Kanban')">
            <i class="fa fa-copy"></i>
          </span>
        </div>
        <div class="ticket-tags">
          ${typeHtml}
          ${priorityHtml}
        </div>
      </div>
      <div class="ticket-title">${ticket.TITLE}</div>
      <div class="ticket-footer">
        <span class="assignee">${ticket.ASSIGNED_TO || ''}</span>
        <span class="created-date">${ticket.CREATED_DATE || ''}</span>
      </div>
    `;
  };








  /* ================================================================ */
  /**
   * Update ticket status in database after drag and drop
   * @param {string} ticketId - The ticket ID
   * @param {string} newColumnId - The new column ID
   * @param {Function} callback - Callback function to execute after update
   */
  var updateTicketStatus = function(ticketId, newColumnId, callback) {
    logger.log('Updating ticket status', {ticketId: ticketId, newColumnId: newColumnId});

    // Llamada AJAX a tu endpoint
    apex.server.process(
      "move_ticket_ajax",
      {
        x01: ticketId, // Ticket ID
        x02: newColumnId,  // New Column ID
      },
      {
        success: function(pData) {
          logger.log('AJAX response', {success: pData.success});
          if (pData.success) {
            apex.message.showPageSuccess('Ticket moved successfully');
            logger.log('Ticket status updated successfully', {ticketId: ticketId, newColumnId: newColumnId});

            // Execute callback if provided
            if (typeof callback === 'function') {
              callback(true, pData);
            }
          } else {
            logger.error('Error updating ticket status', {ticketId: ticketId, newColumnId: newColumnId, error: pData.error_msg});

            // Execute callback with error if provided
            if (typeof callback === 'function') {
              callback(false, pData);
            }
          }
        },
        error: function(jqXHR, textStatus, errorThrown) {
          logger.error('AJAX error updating ticket status', {ticketId: ticketId, newColumnId: newColumnId, status: textStatus, error: errorThrown});

          // Execute callback with error if provided
          if (typeof callback === 'function') {
            callback(false, { error: textStatus, details: errorThrown });
          }
        }
      }
    );
  };








  /* ================================================================ */
  /**
   * Show processing indicator on ticket
   * @param {string} ticketId - The ticket ID
   */
  var showProcessingIndicator = function(ticketId) {
    var ticketElement = document.querySelector('[data-ticket-id="' + ticketId + '"]');
    if (ticketElement) {
      ticketElement.classList.add('processing');
      ticketElement.setAttribute('title', 'Processing...');
    }
  };








  /* ================================================================ */
  /**
   * Hide processing indicator on ticket
   * @param {string} ticketId - The ticket ID
   */
  var hideProcessingIndicator = function(ticketId) {
    var ticketElement = document.querySelector('[data-ticket-id="' + ticketId + '"]');
    if (ticketElement) {
      ticketElement.classList.remove('processing');
      ticketElement.removeAttribute('title');
    }
  };









  /* ================================================================ */
  /**
   * Show success feedback on ticket
   * @param {string} ticketId - The ticket ID
   */
  var showSuccessFeedback = function(ticketId) {
    var ticketElement = document.querySelector('[data-ticket-id="' + ticketId + '"]');
    if (ticketElement) {
      ticketElement.classList.add('success-feedback');
      setTimeout(function() {
        ticketElement.classList.remove('success-feedback');
      }, 2000);
    }
  };







  /* ================================================================ */
  /**
   * Revert ticket position with error feedback
   * @param {string} ticketId - The ticket ID
   * @param {string} errorMessage - Error message to display
   */
  var revertTicketPosition = function(ticketId, errorMessage) {
    var ticketElement = document.querySelector('[data-ticket-id="' + ticketId + '"]');
    if (ticketElement) {
      // Add error feedback class
      ticketElement.classList.add('error-feedback');

      // Show error message
      apex.message.showErrors(errorMessage || 'Failed to move ticket. Reverting position.');

      // Trigger revert animation
      setTimeout(function() {
        ticketElement.classList.add('reverting');

        // After animation, remove error classes
        setTimeout(function() {
          ticketElement.classList.remove('error-feedback', 'reverting');
        }, 500);
      }, 100);
    }
  };







  /* ================================================================ */
  /* Return public API */
  /* ================================================================ */
  return {
    // Utilities
    copyToClipboard: copyToClipboard,

    // Business Logic
    getTicketsForColumn: getTicketsForColumn,
    createTicketHTML: createTicketHTML,
    updateTicketStatus: updateTicketStatus,
    showProcessingIndicator: showProcessingIndicator,
    hideProcessingIndicator: hideProcessingIndicator,
    showSuccessFeedback: showSuccessFeedback,
    revertTicketPosition: revertTicketPosition
  };

})(namespace, apex.jQuery);
