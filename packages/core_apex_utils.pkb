create or replace package body core_apex_utils as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';




/**
 *
 *
 *
 * @example
 *
 * @issue
 *
 * @author Angel Flores (Contractor)
 * @created  Tuesday, 26/August/2025
 * @param p_username
 * @param p_password
 * @return boolean
 */
function custom_authentication(
    p_username                  in varchar2
  , p_password                  in varchar2
)
return boolean
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'custom_authentication';
  l_params logger.tab_param;
  l_count                       number;
begin
  logger.append_param(l_params, 'p_username', p_username);
  logger.append_param(l_params, 'p_password', p_password);

  logger.log('START', l_scope, null, l_params);

  begin
    insert
      into core_users (
           username
         , display_username
         , system_email
         , last_login
      )
    values (
           upper(p_username)
         , p_username -- display_username
         , p_username -- system_email
         , current_timestamp
      );

      return true;

  exception
    when dup_val_on_index then
      logger.log('Username already exists', l_scope, null, l_params);
      return true;
  end;




/*   select count(*)
    into l_count
    from core_users
   where username = lower(p_username);


  if l_count > 0 then
    return true;
  else
    return false;

  end if; */

  logger.log('END', l_scope, null, l_params);

exception
  when OTHERS then
    logger.log_error('Unhandled Exception', l_scope, null, l_params);
    raise;
end custom_authentication;







end core_apex_utils;
/