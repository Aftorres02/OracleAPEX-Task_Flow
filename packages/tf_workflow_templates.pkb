create or replace package body tf_workflow_templates as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';


  -- ========================================
  -- Phase 2: Board Creation Logic
  -- ========================================

  /**
   * Creates board columns from a workflow template
   */
  function create_board_columns_from_template(
      p_board_id                  in number
    , p_workflow_template_id      in number
    , p_include_optional          in varchar2 default 'Y'
  )
  return number
  as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'create_board_columns_from_template';
    l_params logger.tab_param;
    l_columns_created number := 0;
  begin
    -- logger.append_param(l_params, 'p_board_id', p_board_id);
    -- logger.append_param(l_params, 'p_workflow_template_id', p_workflow_template_id);
    -- logger.append_param(l_params, 'p_include_optional', p_include_optional);
    -- logger.log('START', l_scope, null, l_params);

    -- Validate board exists
    begin
      select 1
        into l_columns_created
        from tf_boards
       where board_id = p_board_id;
    exception
      when no_data_found then
        raise_application_error(-20001, 'Board ID ' || p_board_id || ' does not exist.');
    end;

    -- Validate template exists
    begin
      select 1
        into l_columns_created
        from tf_workflow_templates
       where workflow_template_id = p_workflow_template_id
         and active_yn = 'Y';
    exception
      when no_data_found then
        raise_application_error(-20002, 'Workflow template ID ' || p_workflow_template_id || ' does not exist or is inactive.');
    end;

    -- Create columns from template
    insert into tf_board_columns (
        board_id
      , column_name
      , display_seq
      , class_color
      , class_icon
      , description
      , active_yn
      , created_by
      , created_on
    )
    select
        p_board_id
      , wtc.column_name
      , wtc.display_seq
      , wtc.class_color
      , wtc.class_icon
      , wtc.description
      , 'Y'
      , coalesce(
          sys_context('APEX$SESSION','app_user')
        , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
        , sys_context('userenv','session_user')
        )
      , localtimestamp
      from tf_workflow_template_columns wtc
     where wtc.workflow_template_id = p_workflow_template_id
       and wtc.active_yn = 'Y'
       and (wtc.required_yn = 'Y' or p_include_optional = 'Y')
     order by wtc.display_seq;

    l_columns_created := sql%rowcount;

    -- Update board with template reference
    update tf_boards
       set workflow_template_id = p_workflow_template_id
     where board_id = p_board_id;

    -- logger.log('END', l_scope, null, l_params);
    return l_columns_created;
  exception
    when others then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end create_board_columns_from_template;


  -- ========================================
  -- Phase 3: Template Management CRUD
  -- ========================================

  /**
   * Clones a workflow template
   */
  function clone_template(
      p_workflow_template_id      in number
    , p_new_template_name         in varchar2
    , p_new_template_code         in varchar2
    , p_new_description           in varchar2 default null
  )
  return number
  as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'clone_template';
    l_params logger.tab_param;
    l_new_template_id number;
    l_description varchar2(500);
  begin
    -- logger.append_param(l_params, 'p_workflow_template_id', p_workflow_template_id);
    -- logger.append_param(l_params, 'p_new_template_name', p_new_template_name);
    -- logger.log('START', l_scope, null, l_params);

    -- Get original template description if not provided
    if p_new_description is null then
      select description
        into l_description
        from tf_workflow_templates
       where workflow_template_id = p_workflow_template_id;
    else
      l_description := p_new_description;
    end if;

    -- Create new template
    l_new_template_id := create_template(
        p_template_name => p_new_template_name
      , p_template_code => p_new_template_code
      , p_description => l_description
      , p_category => (select category from tf_workflow_templates where workflow_template_id = p_workflow_template_id)
      , p_system_template_yn => 'N'
    );

    -- Clone columns
    insert into tf_workflow_template_columns (
        workflow_template_id
      , column_name
      , display_seq
      , class_color
      , class_icon
      , description
      , wip_limit
      , required_yn
      , active_yn
      , created_by
      , created_on
    )
    select
        l_new_template_id
      , column_name
      , display_seq
      , class_color
      , class_icon
      , description
      , wip_limit
      , required_yn
      , active_yn
      , coalesce(
          sys_context('APEX$SESSION','app_user')
        , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
        , sys_context('userenv','session_user')
        )
      , localtimestamp
      from tf_workflow_template_columns
     where workflow_template_id = p_workflow_template_id
       and active_yn = 'Y';

    -- Clone transitions
    insert into tf_workflow_transitions (
        workflow_template_id
      , from_column_seq
      , to_column_seq
      , transition_name
      , required_fields
      , auto_assign_role
      , validation_rule
      , active_yn
      , created_by
      , created_on
    )
    select
        l_new_template_id
      , from_column_seq
      , to_column_seq
      , transition_name
      , required_fields
      , auto_assign_role
      , validation_rule
      , active_yn
      , coalesce(
          sys_context('APEX$SESSION','app_user')
        , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
        , sys_context('userenv','session_user')
        )
      , localtimestamp
      from tf_workflow_transitions
     where workflow_template_id = p_workflow_template_id
       and active_yn = 'Y';

    -- logger.log('END', l_scope, null, l_params);
    return l_new_template_id;
  exception
    when others then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end clone_template;


  -- ========================================
  -- Phase 4: Advanced Features
  -- ========================================

  /**
   * Adds a transition rule between two columns
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
  return number
  as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'add_transition';
    l_params logger.tab_param;
    l_transition_id number;
  begin
    -- logger.append_param(l_params, 'p_workflow_template_id', p_workflow_template_id);
    -- logger.log('START', l_scope, null, l_params);

    insert into tf_workflow_transitions (
        workflow_template_id
      , from_column_seq
      , to_column_seq
      , transition_name
      , required_fields
      , auto_assign_role
      , validation_rule
      , active_yn
      , created_by
      , created_on
    )
    values (
        p_workflow_template_id
      , p_from_column_seq
      , p_to_column_seq
      , p_transition_name
      , p_required_fields
      , p_auto_assign_role
      , p_validation_rule
      , 'Y'
      , coalesce(
          sys_context('APEX$SESSION','app_user')
        , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
        , sys_context('userenv','session_user')
        )
      , localtimestamp
    )
    returning transition_id into l_transition_id;

    -- logger.log('END', l_scope, null, l_params);
    return l_transition_id;
  exception
    when others then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end add_transition;


  /**
   * Validates if a ticket can transition from one column to another
   */
  function validate_transition(
      p_board_id                  in number
    , p_from_column_id            in number
    , p_to_column_id              in number
    , p_ticket_id                 in number default null
  )
  return varchar2
  as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'validate_transition';
    l_params logger.tab_param;
    l_workflow_template_id number;
    l_from_seq number;
    l_to_seq number;
    l_transition_exists number;
    l_required_fields varchar2(1000);
    l_ticket_assignee_id number;
    l_ticket_due_on date;
    l_validation_result varchar2(1) := 'Y';
  begin
    -- logger.append_param(l_params, 'p_board_id', p_board_id);
    -- logger.append_param(l_params, 'p_from_column_id', p_from_column_id);
    -- logger.append_param(l_params, 'p_to_column_id', p_to_column_id);
    -- logger.log('START', l_scope, null, l_params);

    -- Get board's workflow template
    select workflow_template_id
      into l_workflow_template_id
      from tf_boards
     where board_id = p_board_id;

    -- If no template, allow all transitions
    if l_workflow_template_id is null then
      return 'Y';
    end if;

    -- Get column sequences
    select display_seq
      into l_from_seq
      from tf_board_columns
     where board_column_id = p_from_column_id;

    select display_seq
      into l_to_seq
      from tf_board_columns
     where board_column_id = p_to_column_id;

    -- Check if transition exists
    begin
      select 1
        into l_transition_exists
        from tf_workflow_transitions
       where workflow_template_id = l_workflow_template_id
         and from_column_seq = l_from_seq
         and to_column_seq = l_to_seq
         and active_yn = 'Y';

      -- Get required fields if any
      select required_fields
        into l_required_fields
        from tf_workflow_transitions
       where workflow_template_id = l_workflow_template_id
         and from_column_seq = l_from_seq
         and to_column_seq = l_to_seq
         and active_yn = 'Y';

    exception
      when no_data_found then
        -- Transition not defined, not allowed
        return 'N';
    end;

    -- Validate required fields if ticket provided
    if p_ticket_id is not null and l_required_fields is not null then
      select assignee_id, due_on
        into l_ticket_assignee_id, l_ticket_due_on
        from tf_tickets
       where ticket_id = p_ticket_id;

      -- Check ASSIGNEE_ID requirement
      if instr(upper(l_required_fields), 'ASSIGNEE_ID') > 0 and l_ticket_assignee_id is null then
        l_validation_result := 'N';
      end if;

      -- Check DUE_ON requirement
      if instr(upper(l_required_fields), 'DUE_ON') > 0 and l_ticket_due_on is null then
        l_validation_result := 'N';
      end if;
    end if;

    -- logger.log('END', l_scope, null, l_params);
    return l_validation_result;
  exception
    when others then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      -- On error, allow transition (fail open)
      return 'Y';
  end validate_transition;


  /**
   * Gets workflow analytics for a board
   */
  function get_workflow_analytics(
      p_board_id                  in number
    , p_start_date                in date default null
    , p_end_date                  in date default null
  )
  return sys_refcursor
  as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'get_workflow_analytics';
    l_params logger.tab_param;
    l_cursor sys_refcursor;
    l_start_date date := nvl(p_start_date, trunc(sysdate) - 30);
    l_end_date date := nvl(p_end_date, trunc(sysdate));
  begin
    -- logger.append_param(l_params, 'p_board_id', p_board_id);
    -- logger.log('START', l_scope, null, l_params);

    open l_cursor for
      select
          bc.column_name
        , bc.display_seq
        , count(distinct t.ticket_id) as ticket_count
        , count(distinct case when t.end_on between l_start_date and l_end_date then t.ticket_id end) as completed_count
        , avg(case when t.end_on is not null then t.end_on - t.start_on end) as avg_cycle_days
        , sum(t.actual_hours) as total_hours
        , sum(t.estimated_hours) as estimated_hours
        , wtc.wip_limit
        , case when wtc.wip_limit is not null and count(distinct t.ticket_id) > wtc.wip_limit then 'Y' else 'N' end as wip_exceeded_yn
        from tf_board_columns bc
        left join tf_boards b
          on bc.board_id = b.board_id
        left join tf_workflow_template_columns wtc
          on b.workflow_template_id = wtc.workflow_template_id
         and bc.display_seq = wtc.display_seq
         and wtc.active_yn = 'Y'
        left join tf_tickets t
          on bc.board_column_id = t.board_column_id
         and t.active_yn = 'Y'
         and (t.created_on between l_start_date and l_end_date
           or t.end_on between l_start_date and l_end_date
           or (t.start_on <= l_end_date and (t.end_on is null or t.end_on >= l_start_date)))
       where bc.board_id = p_board_id
         and bc.active_yn = 'Y'
       group by bc.column_name, bc.display_seq, wtc.wip_limit
       order by bc.display_seq;

    -- logger.log('END', l_scope, null, l_params);
    return l_cursor;
  exception
    when others then
      -- logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end get_workflow_analytics;


end tf_workflow_templates;
/

