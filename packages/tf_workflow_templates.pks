create or replace package tf_workflow_templates as

  -- ========================================
  -- Phase 2: Board Creation Logic
  -- ========================================

  /**
   * Creates board columns from a workflow template
   *
   * @param p_board_id Board ID to create columns for
   * @param p_workflow_template_id Workflow template ID to use
   * @param p_include_optional If Y, includes optional columns; if N, only required columns
   * @return Number of columns created
   */
  function create_board_columns_from_template(
      p_board_id                  in number
    , p_workflow_template_id      in number
    , p_include_optional          in varchar2 default 'Y'
  )
  return number;


  -- ========================================
  -- Phase 3: Template Management CRUD
  -- ========================================


  /**
   * Clones a workflow template
   *
   * @param p_workflow_template_id Source template ID
   * @param p_new_template_name New template name
   * @param p_new_template_code New template code
   * @param p_new_description New description
   * @return New template ID
   */
  function clone_template(
      p_workflow_template_id      in number
    , p_new_template_name         in varchar2
    , p_new_template_code         in varchar2
    , p_new_description           in varchar2 default null
  )
  return number;


  -- ========================================
  -- Phase 4: Advanced Features
  -- ========================================

  /**
   * Adds a transition rule between two columns
   *
   * @param p_workflow_template_id Template ID
   * @param p_from_column_seq Source column sequence
   * @param p_to_column_seq Target column sequence
   * @param p_transition_name Transition name
   * @param p_required_fields Comma-separated required fields
   * @param p_auto_assign_role Role to auto-assign
   * @param p_validation_rule Validation rule expression
   * @return Created transition ID
   */
  function add_transition(
      p_workflow_template_id      in number
    , p_from_column_seq           in number
    , p_to_column_seq             in number
    , p_transition_name           in varchar2 default null
    , p_required_fields           in varchar2 default null
    , p_auto_assign_role          in varchar2 default null
    , p_validation_rule           in varchar2 default null
  )
  return number;


  /**
   * Validates if a ticket can transition from one column to another
   *
   * @param p_board_id Board ID
   * @param p_from_column_id Source column ID
   * @param p_to_column_id Target column ID
   * @param p_ticket_id Ticket ID (for field validation)
   * @return Y if valid, N if invalid
   */
  function validate_transition(
      p_board_id                  in number
    , p_from_column_id            in number
    , p_to_column_id              in number
    , p_ticket_id                 in number default null
  )
  return varchar2;


  /**
   * Gets workflow analytics for a board
   *
   * @param p_board_id Board ID
   * @param p_start_date Start date for analytics
   * @param p_end_date End date for analytics
   * @return Cursor with analytics data
   */
  function get_workflow_analytics(
      p_board_id                  in number
    , p_start_date                in date default null
    , p_end_date                  in date default null
  )
  return sys_refcursor;


end tf_workflow_templates;
/

