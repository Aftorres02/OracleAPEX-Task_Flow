create or replace package body core_lovs as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';



  /**
   * Returns currencies as a pipelined table for use in APEX LOVs
   * 
   * @example
   * select display_value d, return_value r, display_seq s
   *   from table(core_lovs.get_currencies(include_inactive_yn => 'N'))
   *  order by display_seq;
   * 
   * @param include_inactive_yn Include inactive currencies (Y) or only active (N)
   * @return core_lov_table Table with display_value, return_value, and display_seq
   * @author Angel Flores (Contractor)
   * @created 16/November/2025
   */
  function get_currencies(
    include_inactive_yn in varchar2 default 'N'
  ) return core_lov_table
  is
    l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_currencies';
    l_params logger.tab_param;

    l_result core_lov_table;
  begin
    -- logger.append_param(l_params, 'include_inactive_yn', include_inactive_yn);
    -- logger.log('START', l_scope, null, l_params);

      select core_lov_row(
             currency_code || ' - ' || currency_name || ' (' || currency_symbol || ')'
           , currency_id
           , display_seq
      )
        bulk collect
        into l_result
        from core_lov_currencies
       where active_yn = 'Y' or include_inactive_yn = 'Y'
       order by display_seq;

    --logger.log('END', l_scope, null, l_params);
    return l_result;
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end get_currencies;





/*
 * Returns users as a pipelined table for use in APEX LOVs
 *
 * @example
 * select display_value d, return_value r, display_seq s
 *   from table(core_lovs.get_users(include_inactive_yn => 'N'))
 *  order by display_seq;
 *
 * @param include_inactive_yn Include inactive users (Y) or only active (N)
 * @return core_lov_table Table with display_value, return_value, and display_seq
 * @author Angel Flores (Contractor)
 * @created 16/November/2025
 */
function get_users(
    include_inactive_yn in varchar2 default 'N'
) return core_lov_table
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_users';
  l_params logger.tab_param;

  l_result core_lov_table;
begin
  -- logger.append_param(l_params, 'include_inactive_yn', include_inactive_yn);
  -- logger.log('START', l_scope, null, l_params);

    select core_lov_row(
            display_username
          , user_id
          , display_username
    )
      bulk collect
      into l_result
      from core_users
      where active_yn = 'Y' or include_inactive_yn = 'Y'
      order by display_username;

  --logger.log('END', l_scope, null, l_params);
  return l_result;
exception
  when OTHERS then
    logger.log_error('Unhandled Exception', l_scope, null, l_params);
    raise;
end get_users;





end core_lovs;
/