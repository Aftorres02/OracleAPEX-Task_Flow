create or replace package body core_utils as

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
 * @created  Tuesday, 09/September/2025
 * @param p_apex_application_g_f0x_value
 * @param p_index
 * @return varchar2 with
 */
function get_apex_application_g_f0x_value(
    p_apex_application_g_f0x_value                   in sys.dbms_sql.varchar2a
  , p_index                                          in number
)
return varchar2
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_apex_application_g_f0x_value';
  l_params logger.tab_param;
begin
  logger.append_param(l_params, 'p_index', p_index);
  --logger.log('START', l_scope, null, l_params);

  logger.log('g_f0x index: ' || p_index || ': ' || p_apex_application_g_f0x_value(p_index), l_scope, null, l_params);
  return p_apex_application_g_f0x_value(p_index);

  --logger.log('END', l_scope, null, l_params);


  exception
    when OTHERS then
      --logger.log_error('Unhandled Exception', l_scope, null, l_params);
      return null;
end get_apex_application_g_f0x_value;









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
procedure get_url_ajax
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_url_ajax';
  l_params logger.tab_param;
  l_url                          varchar2(1000);

  l_application             varchar2(100) := apex_application.g_x01;
  l_page                    varchar2(100) := apex_application.g_x02;
  l_session                 number   := apex_application.g_x03;
  l_request                 varchar2(100) := apex_application.g_x04;
  l_debug                   varchar2(100) := apex_application.g_x05;
  l_clear_cache             varchar2(100) := apex_application.g_x06;
  l_items                   varchar2(100) := apex_application.g_x07;
  l_values                  varchar2(100) := apex_application.g_x08;
  l_printer_friendly        varchar2(100) := apex_application.g_x09;
  l_trace                   varchar2(100) := apex_application.g_x10;


  l_custom_action           varchar2(100);
  l_custom_param_1          varchar2(100);
  l_custom_param_2          varchar2(100);
  l_custom_param_3          varchar2(100);
  l_modal_title             varchar2(500);

  l_column_name              tf_boards.board_name%type;
  l_board_id                 tf_boards.board_id%type;
begin
  logger.append_param(l_params, 'p_application', l_application);
  logger.append_param(l_params, 'p_page', l_page);
  logger.append_param(l_params, 'p_session', l_session);
  logger.append_param(l_params, 'p_request', l_request);
  logger.append_param(l_params, 'p_debug', l_debug);
  logger.append_param(l_params, 'p_clear_cache', l_clear_cache);
  logger.append_param(l_params, 'p_items', l_items);
  logger.append_param(l_params, 'p_values', l_values);
  logger.append_param(l_params, 'p_printer_friendly', l_printer_friendly);
  logger.append_param(l_params, 'p_trace', l_trace);
  logger.append_param(l_params, 'p_custom_action', l_custom_action);
  logger.append_param(l_params, 'p_custom_param_1', l_custom_param_1);
  logger.append_param(l_params, 'p_custom_param_2', l_custom_param_2);
  logger.append_param(l_params, 'p_custom_param_3', l_custom_param_3);
  logger.log('START', l_scope, null, l_params);


  l_custom_action := get_apex_application_g_f0x_value(apex_application.g_f01, 1);
  l_custom_param_1 := get_apex_application_g_f0x_value(apex_application.g_f01, 2);
  l_custom_param_2 := get_apex_application_g_f0x_value(apex_application.g_f01, 3);
  l_custom_param_3 := get_apex_application_g_f0x_value(apex_application.g_f01, 4);




  if l_custom_action = 'ADD_TICKET_MODAL_TITLE' then

    begin
      select column_name
           , board_id
        into l_column_name
           , l_board_id
        from tf_board_columns
       where board_column_id = l_custom_param_1;

      l_modal_title := 'Column: ' || l_column_name;

      -- Set the board id to the APEX Item
      l_items := case when l_items is not null then l_items || ',' || 'P1010_BOARD_ID'
                      else 'P1010_BOARD_ID'
                 end;

      -- Set the board id to the APEX Value
      l_values := case when l_values is not null then l_values || ',' || l_board_id
                       else l_board_id
                  end;

     logger.log('l_items: ' || l_items, l_scope, null, l_params);
     logger.log('l_values: ' || l_values, l_scope, null, l_params);

    exception
      when others then
      l_modal_title := 'New Ticket';
    end;
  end if;



  l_url :=
    apex_page.get_url (
        p_application        => l_application
      , p_page               => l_page
      , p_session            => coalesce(l_session, apex_application.g_instance)
      , p_request            => l_request
      , p_debug              => l_debug
      , p_clear_cache        => l_clear_cache
      , p_items              => l_items
      , p_values             => l_values
      , p_printer_friendly   => l_printer_friendly
      , p_trace              => l_trace
    );
  logger.append_param(l_params, 'l_url', l_url);




  logger.log('END', l_scope, null, l_params);

  apex_json.open_object;
  apex_json.write('success',true);
  apex_json.write('modal_title',l_modal_title);
  apex_json.write('url',l_url);
  apex_json.close_object;

exception
  when others then 
    apex_json.open_object;
    apex_json.write('success',false);
    apex_json.write('error_msg',sqlerrm);
    apex_json.close_object;
end get_url_ajax;









end core_utils;
/