/*
 * ==========================================================================
 * KANBAN VIEW
 * ==========================================================================
 *
 * @description View Controller for TaskFlow Kanban
 * @author Angel O. Flores Torres
 * @created 2024
 * @version 2.0
 */

// Global Variables
var currentUser = apex.env.APP_USER || 'SYSTEM';

// Initialize namespace
var namespace = namespace || {};

/**
 * ==========================================================================
 * @module kanbanView
 * ==========================================================================
 */
namespace.kanbanView = (function(namespace, $, undefined) {
  'use strict';

  var MODULE_NAME = 'KanbanView';

  // Private variables
  var _currentDragTicket = null;
  var isInitialized = false;
  var isModalOpening = false; // From Actions

  // Configuration constants
  var CONFIG = {
    COLUMN_CLASS: '.column-5a',
    CONTAINER_CLASS: '.tickets-container-5a',
    TICKET_CLASS: '.ticket-card',
    DRAG_OVER_CLASS: 'drag-over',
    DRAGGING_CLASS: 'dragging',
    AJAX_GET_URL: 'get_url_ajax'
  };

  // Create module-specific logger using enterprise logger
  var logger = namespace.logger ? namespace.logger.createModuleLogger(MODULE_NAME) : { log: function(){}, error: function(){}, warning: function(){} };

  var apexPageID = apex.env.APP_PAGE_ID;

  // Filter configuration defaults
  var _filterConfig = {
      userFilterItem: 'P' + apexPageID + '_ASSIGNED_TO_ID' // Default item name
    , ticketTypeFilterItem: 'P' + apexPageID + '_TICKET_TYPE_ID'
    , searchFilterItem: 'P' + apexPageID + '_SEARCH'
    , priorityFilterItem: 'P' + apexPageID + '_PRIORITY'
    , myTicketsFilterItem: 'P' + apexPageID + '_MY_TICKETS'
  };


  /* ================================================================ */
  /* EVENT LISTENERS SECTION                                          */
  /* ================================================================ */

  /**
   * Setup event listeners for the kanban board (Global delegation)
   */
  var _setupEventListeners = function() {
    logger.log('Setting up event listeners');
    // Event delegation for dynamic elements
    document.addEventListener('click', function(event) {
      // Check click on ticket counter
      if (event.target.classList.contains('ticket-count-5a') ||
          event.target.closest('.ticket-count-5a')) {
        event.preventDefault();
        _handleTicketCountClick(event);
      }

      // Check click on ticket creation icon
      if (event.target.classList.contains('ticket-creation-5a') ||
          event.target.closest('.ticket-creation-5a')) {
        event.preventDefault();
        _handleTicketCreationClick(event);
      }

      // Check click on ticket number
      if (event.target.classList.contains('ticket-number') ||
          event.target.closest('.ticket-number')) {
        event.preventDefault();
        _handleTicketNumberClick(event);
      }
    });
  };







  /* ================================================================ */
  /**
   * Handle click on ticket counter
   * @param {Event} event - The click event
   */
  var _handleTicketCountClick = function(event) {
    const columnId = event.target.closest('.column-5a').getAttribute('data-column-id');
    const columnName = event.target.closest('.column-5a').querySelector('.column-title-5a').textContent;

    logger.log('Ticket counter clicked for column', {columnId: columnId, columnName: columnName});
    showTicketDetails(columnId, columnName);
  };







  /* ================================================================ */
  /**
   * Handle click on ticket creation icon
   * @param {Event} event - The click event
   */
  var _handleTicketCreationClick = function(event) {
    const columnId = event.target.closest('.column-5a').getAttribute('data-column-id');
    const columnName = event.target.closest('.column-5a').querySelector('.column-title-5a').textContent;

    logger.log('Creating new ticket for column', {columnId: columnId, columnName: columnName});
    addTicket(columnId, columnName, event);
  };







  /* ================================================================ */
  /**
   * Handle click on ticket number
   * @param {Event} event - The click event
   */
  var _handleTicketNumberClick = function(event) {
    const ticketElement = event.target.closest('.ticket-card');
    const ticketId = ticketElement.getAttribute('data-ticket-id');
    const ticketNumber = event.target.textContent;

    // Open ticket details or navigate to ticket page
    openTicketDetails(ticketId, ticketNumber);
  };







  /* ================================================================ */
  /* ACTIONS SECTION                                                  */
  /* ================================================================ */

  /**
   * Show ticket details or statistics for a column
   * @param {string} columnId - The column ID
   * @param {string} columnName - The column name
   */
  var showTicketDetails = function(columnId, columnName) {
    logger.log('Showing details for column', {columnId: columnId, columnName: columnName});
    // Implement your logic here...
  };







  /* ================================================================ */
  /**
   * Private helper to fetch URL and open dialog
   * @param {string} columnId - Context Column ID
   * @param {string} columnName - Context Column Name
   * @param {string} ticketId - Optional Ticket ID (for edit mode)
   * @param {HTMLElement} triggeringElement - The element that triggered the action
   */
  var _openTicketDialog = function(columnId, columnName, ticketId, ticketNumber, triggeringElement) {

    // Prevent multiple modal openings
    if (isModalOpening) {
        logger.warning('Modal already opening, ignoring duplicate request');
        return;
    }

    isModalOpening = true;
    logger.log('Opening ticket dialog', {columnId: columnId, ticketId: ticketId});

    apex.server.process(
        CONFIG.AJAX_GET_URL,
        {
          x01: columnId,         // Context: Board Column
          x02: ticketId ? 'Y' : 'N', // Edit Mode Flag: If ticketId exists, it's edit mode
          x03: ticketId          // Context: Ticket ID
        },
        {
          success: function(pData) {
            if (pData.success) {

              // Open modal using dialog
              apex.navigation.dialog(
                pData.url,
                {
                  title: ticketId ? ('Edit Ticket: ' + ticketNumber) : 'Board Column: ' + columnName,
                  modal: true,
                  resizable: true
                },
                '',
                $(triggeringElement)
              );

              // Listen for dialog close to refresh content
              var cleanupListener = function() {
                logger.log('Modal closed, updating column', {columnId: columnId});

                // Refresh Column Data
                namespace.kanbanServices.getTicketsForColumn(columnId, function(tickets) {
                  renderTicketsForColumn(columnId, tickets, true);
                });

                isModalOpening = false;
                $(triggeringElement).off('apexafterclosecanceldialog', cleanupListener);
              };

              $(triggeringElement).on('apexafterclosecanceldialog', cleanupListener);

            } else {
              logger.error('Error fetching URL', pData);
              isModalOpening = false;
            }
          },
          error: function() {
            logger.error('AJAX error');
            isModalOpening = false;
          }
        }
      );
  };


  /**
   * Show a modal or form to add a new ticket
   * @param {string} columnId - The column ID
   * @param {string} columnName - The column name
   */
  var addTicket = function(columnId, columnName, event) {
    logger.log('Adding ticket to column', {columnId: columnId, columnName: columnName});
    var triggeringElement = event.target.closest('.ticket-creation-5a');
    _openTicketDialog(columnId, columnName, null, null, triggeringElement);
  };



  /* ================================================================ */
  /**
   * Open ticket details or navigate to ticket page
   * @param {string} ticketId - The ticket ID
   * @param {string} ticketNumber - The ticket number
   */
  var openTicketDetails = function(ticketId, ticketNumber) {
    logger.log('Opening ticket details', {ticketId: ticketId, ticketNumber: ticketNumber});

    // Find context from the clicked element in the DOM
    var ticketCard = document.querySelector('[data-ticket-id="' + ticketId + '"]');
    var columnElement = ticketCard ? ticketCard.closest('.column-5a') : null;

    if (columnElement) {
        var columnId = columnElement.getAttribute('data-column-id');
        var columnName = columnElement.querySelector('.column-title-5a').textContent;
        _openTicketDialog(columnId, columnName, ticketId, ticketNumber, ticketCard);
    } else {
        logger.error('Could not find column context for ticket', {ticketId: ticketId});
    }
  };

  /* ================================================================ */



  /* ================================================================ */
  /* BOARD LOGIC SECTION                                              */
  /* ================================================================ */

  /**
   * Find all kanban columns
   * @returns {jQuery} - jQuery collection of columns
   */
  var _findColumns = function() {
    return $(CONFIG.COLUMN_CLASS);
  };







  /* ================================================================ */
  /**
   * Find tickets container within a column
   * @param {jQuery} column - The column element
   * @returns {jQuery} - jQuery collection of container
   */
  var _findContainer = function(column) {
    return column.find(CONFIG.CONTAINER_CLASS);
  };







  /* ================================================================ */
  /**
   * Make a ticket element draggable
   * @param {HTMLElement} ticketElement - The ticket DOM element
   * @param {Object} ticketData - Ticket data object
   */
  var _makeTicketDraggable = function(ticketElement, ticketData) {

    ticketElement.draggable = true;
    ticketElement.setAttribute('data-ticket-id', ticketData.TICKET_ID);

    ticketElement.addEventListener('dragstart', function(e) {
      e.dataTransfer.setData('text/plain', ticketData.TICKET_ID);
      e.dataTransfer.effectAllowed = 'move';
      this.classList.add(CONFIG.DRAGGING_CLASS);
      _currentDragTicket = ticketData.TICKET_ID;
      logger.log('Drag started for ticket', {ticketId: ticketData.TICKET_ID});
    });

    ticketElement.addEventListener('dragend', function(e) {
      this.classList.remove(CONFIG.DRAGGING_CLASS);
      _currentDragTicket = null;
      logger.log('Drag ended for ticket', {ticketId: ticketData.TICKET_ID});
    });
  };







  /* ================================================================ */
  /**
   * Make a column element droppable for tickets
   * @param {HTMLElement} columnElement - The column DOM element
   * @param {string} columnId - The column ID
   */
  var _makeColumnDroppable = function(columnElement, columnId) {
    /* Drag Over */
    columnElement.addEventListener('dragover', function(e) {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      this.classList.add(CONFIG.DRAG_OVER_CLASS);

      var container = this.querySelector(CONFIG.CONTAINER_CLASS);
      if (container) {
        container.classList.add('drag-over');
      }
    });

    /* Drag Leave */
    columnElement.addEventListener('dragleave', function(e) {
      this.classList.remove(CONFIG.DRAG_OVER_CLASS);

      var container = this.querySelector(CONFIG.CONTAINER_CLASS);
      if (container) {
        container.classList.remove('drag-over');
      }
    });

    /* Drop */
    columnElement.addEventListener('drop', function(e) {
      e.preventDefault();
      e.stopPropagation();
      this.classList.remove(CONFIG.DRAG_OVER_CLASS);

      var container = this.querySelector(CONFIG.CONTAINER_CLASS);
      if (container) {
        container.classList.remove(CONFIG.DRAG_OVER_CLASS);
      }

      var ticketId = e.dataTransfer.getData('text/plain');
      var ticketElement = document.querySelector('[data-ticket-id="' + ticketId + '"]');

      if (ticketElement && ticketElement !== this) {
        var ticketsContainer = this.querySelector(CONFIG.CONTAINER_CLASS);

        if (ticketsContainer) {
          logger.log('Dropping ticket into column', {ticketId: ticketId, columnId: columnId});

          // Check if same column
          var originalColumn = ticketElement.closest(CONFIG.COLUMN_CLASS);
          if (originalColumn === this) {
            return;
          }

          // Store original position
          var originalContainer = originalColumn ? originalColumn.querySelector(CONFIG.CONTAINER_CLASS) : null;
          var originalPosition = originalContainer ? Array.from(originalContainer.children).indexOf(ticketElement) : -1;

          // 1. Optimistic Update (Visual Move)
          var dropY = e.clientY;

          var existingTickets = ticketsContainer.querySelectorAll(CONFIG.TICKET_CLASS);
          var insertBeforeElement = null;

          existingTickets.forEach(function(existingTicket) {
            var ticketRect = existingTicket.getBoundingClientRect();
            var ticketCenter = ticketRect.top + (ticketRect.height / 2);

            if (dropY < ticketCenter && !insertBeforeElement) {
              insertBeforeElement = existingTicket;
            }
          });

          // Manual Empty State Management
          // 1. Remove empty state from target container if it exists
          var targetEmptyState = ticketsContainer.querySelector('.empty-column-state');
          if (targetEmptyState) {
            targetEmptyState.remove();
          }

          if (insertBeforeElement) {
            ticketsContainer.insertBefore(ticketElement, insertBeforeElement);
          } else {
            ticketsContainer.appendChild(ticketElement);
          }

          // 2. Add empty state to original container if no tickets left
          if (originalContainer) {
             var remainingTickets = originalContainer.querySelectorAll(CONFIG.TICKET_CLASS);
             if (remainingTickets.length === 0) {
                var emptyState = `
                  <div class="empty-column-state">
                     <i class="fa fa-clipboard empty-state-icon"></i>
                     <div class="empty-state-text">No tickets yet</div>
                  </div>
                `;
                originalContainer.innerHTML = emptyState;
             }
          }

          // 2. Show Processing
          namespace.kanbanServices.showProcessingIndicator(ticketId);

          // 3. Call API
          namespace.kanbanServices.updateTicketStatus(
            ticketId,
            columnId,
            function(success, data) {
              namespace.kanbanServices.hideProcessingIndicator(ticketId);

              if (success) {
                namespace.kanbanServices.showSuccessFeedback(ticketId);
                logger.log('Ticket moved successfully to column', {ticketId: ticketId, columnId: columnId});
              } else {
                logger.error('Failed to move ticket, reverting position', {ticketId: ticketId, columnId: columnId});

                // Revert visual position
                if (originalContainer && originalPosition >= 0) {
                  if (originalPosition === 0) {
                    originalContainer.insertBefore(ticketElement, originalContainer.firstChild);
                  } else {
                    var beforeElement = originalContainer.children[originalPosition - 1];
                    originalContainer.insertBefore(ticketElement, beforeElement.nextSibling);
                  }
                }

                var errorMsg = data.error_msg || data.error || 'Failed to move ticket';
                namespace.kanbanServices.revertTicketPosition(ticketId, errorMsg);
              }
            }
          );
        }
      }
    });
  };







  /* ================================================================ */
  /**
   * Render tickets for a specific column
   * @param {string} columnId - The column ID
   * @param {Array} tickets - Array of ticket data
   * @param {boolean} makeDraggable - Whether to make tickets draggable
   */
  var renderTicketsForColumn = function(columnId, tickets, makeDraggable) {
    var columnElement = document.querySelector('[data-column-id="' + columnId + '"]');
    if (!columnElement) {
      logger.warning('Column element not found for ID', {columnId: columnId});
      return;
    }

    var ticketsContainer = columnElement.querySelector('.tickets-container-5a');
    if (!ticketsContainer) {
      logger.warning('Tickets container not found in column', {columnId: columnId});
      return;
    }

    ticketsContainer.innerHTML = '';

    if (tickets && tickets.length > 0) {
      logger.log('Adding tickets to column', {columnId: columnId, count: tickets.length});

      tickets.forEach(function(ticket) {
        var ticketElement = $('<div>', {
          class: 'ticket-card',
          'data-ticket-id': ticket.TICKET_ID
        });

        // Use SERVICES to create HTML
        var ticketHTML = namespace.kanbanServices.createTicketHTML(ticket);
        ticketElement.html(ticketHTML);
        ticketsContainer.appendChild(ticketElement[0]);

        if (makeDraggable) {
          _makeTicketDraggable(ticketElement[0], ticket);
        }
      });
    } else {
      logger.log('No tickets found for column', {columnId: columnId});

      // Render Empty State
      var emptyState = `
        <div class="empty-column-state">
           <i class="fa fa-clipboard empty-state-icon"></i>
           <div class="empty-state-text">No tickets yet</div>
        </div>
      `;
      ticketsContainer.innerHTML = emptyState;
    }

    var ticketCountElement = columnElement.querySelector('.ticket-count-5a');
    if (ticketCountElement) {
      ticketCountElement.textContent = tickets.length;
    }
  };







  /* ================================================================ */


  /* ================================================================ */
  /**
   * Collect current values from configured APEX items
   * @returns {Object} filters object
   */
  var _collectFilters = function() {
    var filters = {};

    // User Filter
    if (_filterConfig.userFilterItem && apex.item(_filterConfig.userFilterItem)) {
      var userIds = apex.item(_filterConfig.userFilterItem).getValue();
      filters.userIds = Array.isArray(userIds) ? userIds.join(':') : userIds;

      var ticketType = apex.item(_filterConfig.ticketTypeFilterItem).getValue();
      filters.ticketType = Array.isArray(ticketType) ? ticketType.join(':') : ticketType;

      var search = apex.item(_filterConfig.searchFilterItem).getValue();
      filters.search = Array.isArray(search) ? search.join(':') : search;

      var priority = apex.item(_filterConfig.priorityFilterItem).getValue();
      filters.priority = Array.isArray(priority) ? priority.join(':') : priority;

      var myTickets = apex.item(_filterConfig.myTicketsFilterItem).getValue();
      filters.myTickets = Array.isArray(myTickets) ? myTickets.join(':') : myTickets;
    }
    logger.log('Filters collected', filters);
    return filters;
  };






  /* ================================================================ */
  /**
   * Load data for all columns
   * @returns {boolean} - Success status
   */
  var _loadColumnData = function(filters) {
    var columns = _findColumns();
    if (columns.length === 0) {
      logger.warning('No columns found');
      return false;
    }

    columns.each(function(index) {
      var column = $(this);
      var columnId = column.data('column-id');
      var container = _findContainer(column);

      if (container.length === 0) return;

      // Use SERVICES to get data
      namespace.kanbanServices.getTicketsForColumn(columnId, filters, function(ticketsData) {
        renderTicketsForColumn(columnId, ticketsData, true);
      });
    });

    return true;
  };






  /* ================================================================ */
  /**
   * Setup a synchronized top scrollbar for the board
   */
  var _setupSyncedTopScroll = function() {
    var board = $('.kanban-board-5');

    // Remove existing top scroll if re-initializing to prevent duplicates
    $('.kanban-top-scroll').remove();

    if (board.length) {
       var topScroll = $('<div class="kanban-top-scroll" style="overflow-x:auto; overflow-y:hidden; height:20px; margin-bottom: 0px;"><div class="kanban-top-scroll-content" style="height:1px;"></div></div>');
       board.before(topScroll);

       // Sync Widths function
       var syncWidths = function() {
           var scrollWidth = board[0].scrollWidth;
           var visibleWidth = board.width();

           // Only show top scroll if necessary
           if (scrollWidth > visibleWidth) {
              topScroll.find('.kanban-top-scroll-content').width(scrollWidth);
              topScroll.width(visibleWidth);
              topScroll.show();
           } else {
              topScroll.hide();
           }
       };

       // Initial sync and delayed sync to ensure DOM is ready
       syncWidths();
       setTimeout(syncWidths, 500);
       setTimeout(syncWidths, 1500);
       $(window).on('resize', syncWidths);

       // Sync Scroll Events
       topScroll.on('scroll', function(){
           board.scrollLeft($(this).scrollLeft());
       });
       board.on('scroll', function(){
           topScroll.scrollLeft($(this).scrollLeft());
       });

       logger.log('Synced top scrollbar initialized');
    }
  };


  /* ================================================================ */
  /**
   * Initialize kanban board functionality
   * @returns {boolean} - Success status
   */
  var initialize = function() {
    if (isInitialized) {
      logger.log('Already initialized, refreshing data instead...');
      return refresh();
    }

    logger.log('Initializing kanban board...');

    // 1. Setup Global Event Listeners (Clicks, etc)
    _setupEventListeners();

    // 2. Load data for all columns
    if (!_loadColumnData()) {
      return false;
    }

    // 3. Set up DnD for existing columns
    var columns = _findColumns();
    columns.each(function(index) {
      var column = $(this);

      // Sync top scroll functionality - Mirror scroll
      // var columnHeader = column.find('.column-header-5a');
      // column.on('scroll', function() {
      //      // Optional sync logic
      // });

      var columnId = column.data('column-id');
      _makeColumnDroppable(column[0], columnId);
    });

    // 4. Setup top scrollbar
    _setupSyncedTopScroll();

    isInitialized = true;
    logger.log('Kanban board initialization completed');
    return true;
  };






  /* ================================================================ */
  /**
   * Refresh kanban board data
   * @param {boolean|Object} useFilters - If true(default), reads from items. If false, no filters. If object, uses as filters.
   * @returns {boolean} - Success status
   */
  var refresh = function(useFilters) {
    var filters = {};

    // Determine filters based on argument
    if (useFilters === undefined || useFilters === true) {
      // Logic encapsulated: Read from APEX items
      filters = _collectFilters();
    } else if (typeof useFilters === 'object') {
      // Manual object passed
      filters = useFilters;
    }
    // Else if false, filters remains empty {}

    logger.log('Refreshing kanban board data...', filters);
    var result = _loadColumnData(filters);

    if (result) {
      var columns = _findColumns();
      columns.each(function(index) {
        var column = $(this);
        var columnId = column.data('column-id');
        _makeColumnDroppable(column[0], columnId);
      });
    }

    return result;
  };







  /* ================================================================ */
  /**
   * Refresh kanban board after APEX region refresh
   */
  var refreshAfterRegionUpdate = function() {
    logger.log('Refreshing kanban board after region update...');
    isInitialized = false;
    return initialize();
  };








  /* ================================================================ */
  /* Return public API */
  /* ================================================================ */
  return {
    initialize: initialize,
    refresh: refresh,
    refreshAfterRegionUpdate: refreshAfterRegionUpdate,
    renderTicketsForColumn: renderTicketsForColumn,
    // Expose actions if needed elsewhere
    showTicketDetails: showTicketDetails,
    addTicket: addTicket,
    openTicketDetails: openTicketDetails
  };

})(namespace, apex.jQuery);
