create or replace package body tf_tickets_api as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';






/**
 *
 *
 *
 * @example
 *
 * @issue
 *
 * @author Angel Flores ()
 * @created  Sunday, 31/August/2025
 * @param p_board_column_id
 * @param p_ticket_type_id
 * @param p_title
 * @param p_description
 * @param p_priority
 * @param p_assignee_id
 * @param p_reporter_id
 * @param p_estimated_hours
 * @param p_actual_hours
 * @param p_story_points
 * @param p_due_date
 * @param p_start_date
 * @param p_completion_date
 * @param p_tags
 * @param p_active_yn
 */
procedure add_ticket(
    p_board_column_id             in tf_board_columns.board_column_id%type
  , p_ticket_type_id              in tf_tickets.ticket_type_id%type
  , p_title                       in tf_tickets.title%type
  , p_description                 in tf_tickets.description%type default null
  , p_priority_id                 in tf_tickets.priority_id%type
  , p_assignee_id                 in tf_tickets.assignee_id%type default null
  , p_reporter_id                 in tf_tickets.reporter_id%type default null
  , p_estimated_hours             in tf_tickets.estimated_hours%type default null
  , p_actual_hours                in tf_tickets.actual_hours%type default null
  , p_due_on                      in tf_tickets.due_on%type default null
  , p_start_on                    in tf_tickets.start_on%type default sysdate
  , p_end_on                      in tf_tickets.end_on%type default null
  , p_tags                        in tf_tickets.tags%type default null
  , p_active_yn                   in tf_tickets.active_yn%type default 'Y'
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'add_ticket';
  l_params logger.tab_param;

  l_sprint_id                             pms_sprints.sprint_id%type;
  l_board_id                              tf_boards.board_id%type;
  l_ticket_number                         tf_tickets.ticket_number%type;
begin
  logger.append_param(l_params, 'p_board_column_id: ', p_board_column_id);
  logger.append_param(l_params, 'p_ticket_type_id: ', p_ticket_type_id);
  logger.append_param(l_params, 'p_title: ', p_title);
  logger.append_param(l_params, 'p_description: ', p_description);
  logger.append_param(l_params, 'p_priority_id: ', p_priority_id);
  logger.append_param(l_params, 'p_assignee_id: ', p_assignee_id);
  logger.append_param(l_params, 'p_reporter_id: ', p_reporter_id);
  logger.append_param(l_params, 'p_estimated_hours: ', p_estimated_hours);
  logger.append_param(l_params, 'p_actual_hours: ', p_actual_hours);
  logger.append_param(l_params, 'p_due_on: ', p_due_on);
  logger.append_param(l_params, 'p_start_on: ', p_start_on);
  logger.append_param(l_params, 'p_end_on: ', p_end_on);
  logger.append_param(l_params, 'p_tags: ', p_tags);
  logger.append_param(l_params, 'p_active_yn: ', p_active_yn);
  logger.log('START', l_scope, null, l_params);

  select board_id
    into l_board_id
    from tf_board_columns
   where board_column_id = p_board_column_id;

  select sprint_id
    into l_sprint_id
    from tf_boards
   where board_id = l_board_id;

  l_ticket_number := tf_tickets_utils.generate_ticket_number(p_ticket_type_id);

  logger.append_param(l_params, 'l_ticket_number: ', l_ticket_number);

  insert into tf_tickets (
      board_id
    , board_column_id
    , ticket_type_id
    , sprint_id
    , ticket_number
    , title
    , description
    , priority_id
    , assignee_id
    , reporter_id
    , estimated_hours
    , actual_hours
    , due_on
    , start_on
    , end_on
    , tags
    , active_yn
  ) values (
      l_board_id
    , p_board_column_id
    , p_ticket_type_id
    , l_sprint_id
    , l_ticket_number
    , p_title
    , p_description
    , p_priority_id
    , p_assignee_id
    , p_reporter_id
    , p_estimated_hours
    , p_actual_hours
    , p_due_on
    , p_start_on
    , p_end_on
    , p_tags
    , p_active_yn
  );

  logger.log('END', l_scope, null, l_params);
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end add_ticket;











/**
 * Gets tickets for a specific board column and returns them as JSON
 *
 * @example
 *   tf_tickets_api.get_tickets_for_column_ajax(1);
 *
 * @issue
 *
 * @author Angel Flores ()
 * @created  Sunday, 31/August/2025
 * @param p_board_column_id - The board column ID to get tickets for
 */
procedure get_tickets_for_column_ajax
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_tickets_for_column_ajax';
  l_params logger.tab_param;

  l_cursor                      sys_refcursor;
  l_board_column_id             tf_board_columns.board_column_id%type := apex_application.g_x01;
begin
  logger.append_param(l_params, 'p_board_column_id', l_board_column_id);
  logger.log('START', l_scope, null, l_params);

  -- Open cursor to get tickets for the column
  open l_cursor for
    select t.ticket_id
         , t.ticket_number
         , t.title
         , t.priority_id
         , null as assigned_to
         , to_char(t.created_on, 'DD/MM/YYYY HH24:MI') as created_date
      from tf_tickets t
      --left join core_users assignee on t.assignee_id = assignee.user_id
     where t.board_column_id = l_board_column_id
       and t.active_yn = 'Y'
       --and t.tenant_id = sys_context('APEX$SESSION','APP_TENANT_ID')
     order by t.ticket_number;

  -- Return JSON array of tickets
  apex_json.open_object;
  apex_json.write('success', true);
  apex_json.write('tickets', l_cursor);
  apex_json.close_object;

  logger.log('END', l_scope, null, l_params);

exception
  when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params);
    apex_json.open_object;
    apex_json.write('success', false);
    apex_json.write('message', sqlerrm);
    apex_json.close_object;
end get_tickets_for_column_ajax;






/**
 * 
 *
 *
 * @example
 *   tf_tickets_api.move_ticket_ajax;
 *
 * @issue
 *
 * @author Angel Flores ()
 * @created  Monday, 01/September/2025
 * @param l_ticket_id
 * @param l_board_column_id
 */
procedure move_ticket_ajax
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'move_ticket_ajax';
  l_params logger.tab_param;

  l_ticket_id                         tf_tickets.ticket_id%type := apex_application.g_x01;
  l_board_column_id                   tf_board_columns.board_column_id%type := apex_application.g_x02;
begin
  logger.append_param(l_params, 'l_ticket_id: ', l_ticket_id);
  logger.append_param(l_params, 'l_board_column_id: ', l_board_column_id);
  logger.log('START', l_scope, null, l_params);

  logger.log('moving ticket: ' || l_ticket_id || ' to column: ' || l_board_column_id, l_scope, null, l_params);

  update tf_tickets
     set board_column_id = l_board_column_id
   where ticket_id = l_ticket_id;


  apex_json.open_object;
  apex_json.write('success', true);
  apex_json.close_object;

  logger.log('END', l_scope, null, l_params);

exception
  when others then 
    logger.log_error('Unhandled Exception', l_scope, null, l_params);
    
    DBMS_SESSION.SLEEP(2);

    apex_json.open_object;
    apex_json.write('success', false);
    apex_json.write('message', sqlerrm);
    apex_json.close_object;
end move_ticket_ajax;







end tf_tickets_api;
/