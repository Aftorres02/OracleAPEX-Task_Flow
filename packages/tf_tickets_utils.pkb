create or replace package body tf_tickets_utils as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';







function generate_ticket_sequence(
    p_ticket_type_code                          in varchar2
)
return varchar2
is
begin
  -- Generate ticket number: Simple Sequence (e.g. 1001, 1002...)
  return lpad(to_char(tf_tickets_seq.nextval), 8, '0');
end generate_ticket_sequence;






/**
 * this function generate a ticket number for a ticket type
 *
 * @example
 * select tf_tickets_utils.generate_ticket_number(1) from dual;
 *
 * @issue
 *
 * @author Angel Flores (Contractor)
 * @created  Wednesday, 27/August/2025
 * @param p_ticket_type_id
 * @return l_ticket_type_prefix with 8 characters example: STD-00000001
 */
function generate_ticket_number(
    p_ticket_type_id                        in tf_ticket_types.ticket_type_id%type default null
)
return varchar2
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'generate_ticket_number';
  l_params logger.tab_param;

  l_ticket_type_prefix                       tf_ticket_types.ticket_type_prefix%type;
  l_ticket_type_code                         tf_ticket_types.ticket_type_code%type;
  l_ticket_number                            varchar2(15);
  l_result                                   varchar2(25);
begin
  logger.append_param(l_params, 'p_ticket_type_id', p_ticket_type_id);
  logger.log('START', l_scope, null, l_params);

  begin
    select ticket_type_prefix
         , ticket_type_code
      into l_ticket_type_prefix
         , l_ticket_type_code
      from tf_ticket_types
     where ticket_type_id = p_ticket_type_id;
  exception
    when no_data_found then
      l_ticket_type_prefix := 'STD';
      l_ticket_type_code := 'STD';
  end;

  l_ticket_number   := generate_ticket_sequence(l_ticket_type_code);
  l_result         := l_ticket_type_prefix || '-' || l_ticket_number;

  return l_result;

  logger.log('END', l_scope, null, l_params);
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end generate_ticket_number;











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
 * @param p_application
 * @param p_page
 * @param p_session
 * @param p_request
 * @param p_debug
 * @param p_clear_cache
 * @param p_items
 * @param p_values
 * @param p_printer_friendly
 * @param p_trace
 * @return l_url with
 */
procedure get_ticket_url_ajax
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_ticket_url_ajax';
  l_params logger.tab_param;
  l_url                          varchar2(1000);

  l_board_column_id         varchar2(100) := apex_application.g_x01;
  l_edit_mode_yn            varchar2(1) := apex_application.g_x02;
  l_ticket_id               tf_tickets.ticket_id%type := apex_application.g_x03;

  l_items                    varchar2(100);
  l_values                   varchar2(100);
  l_ticket_page_id           number;
  l_application_id           number := v('APP_ID');

  l_column_name              tf_boards.board_name%type;
  l_board_id                 tf_boards.board_id%type;
  l_sprint_id                pms_sprints.sprint_id%type;
  l_project_id               pms_sprints.project_id%type;

begin
  logger.append_param(l_params, 'p_board_column_id', l_board_column_id);
  logger.log('START', l_scope, null, l_params);

  if l_edit_mode_yn = 'Y' then
    l_ticket_page_id := 1015;

    l_items := 'P' || l_ticket_page_id || '_TICKET_ID';
    l_values := l_ticket_id;
  else
    l_ticket_page_id := 1010;


    begin
      select bc.column_name
           , bc.board_id
           , s.sprint_id
           , s.project_id
        into l_column_name
           , l_board_id
           , l_sprint_id
           , l_project_id
        from tf_board_columns bc
       inner join tf_boards b on b.board_id = bc.board_id
       inner join pms_sprints s on s.sprint_id = b.sprint_id
       where bc.board_column_id = l_board_column_id;


      -- Set the board id to the APEX Item
      l_items := 'P' || l_ticket_page_id || '_BOARD_ID'
            || ',P' || l_ticket_page_id || '_BOARD_COLUMN_ID'
            || ',P' || l_ticket_page_id || '_SPRINT_ID'
            || ',P' || l_ticket_page_id || '_PROJECT_ID'
            || ',P' || l_ticket_page_id || '_QUICK_CREATION_FLAG';

      -- Set the board id to the APEX Value
      l_values := l_board_id
        || ',' || l_board_column_id
        || ',' || l_sprint_id
        || ',' || l_project_id
        || ',' || 'Y';

      logger.log('l_items: ' || l_items, l_scope, null, l_params);
      logger.log('l_values: ' || l_values, l_scope, null, l_params);

    exception
      when others then
        null;
    end;
  end if;





  l_url :=
    apex_page.get_url (
        p_application        => l_application_id
      , p_page               => l_ticket_page_id
      , p_session            => apex_application.g_instance
      , p_request            => null
      , p_debug              => null
      , p_clear_cache        => null
      , p_items              => l_items
      , p_values             => l_values
      , p_printer_friendly   => null
      , p_trace              => null
    );
  logger.append_param(l_params, 'l_url', l_url);

  logger.log('END', l_scope, null, l_params);

  apex_json.open_object;
  apex_json.write('success',true);
  apex_json.write('url',l_url);
  apex_json.close_object;

exception
  when others then 
    apex_json.open_object;
    apex_json.write('success',false);
    apex_json.write('error_msg',sqlerrm);
    apex_json.close_object;
end get_ticket_url_ajax;








end tf_tickets_utils;
/