create or replace package body tf_tickets_utils as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';







function generate_ticket_sequence(
    p_ticket_type_code                          in varchar2
)
return varchar2
is
begin
  -- Generate ticket number: Simple Sequence (e.g. 1001, 1002...)
  return to_char(tf_tickets_seq.nextval);
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
 * @return l_ticket_type_name with 8 characters example: STD-00000001
 */
function generate_ticket_number(
    p_ticket_type_id                        in tf_ticket_types.ticket_type_id%type default null
)
return varchar2
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'generate_ticket_number';
  l_params logger.tab_param;

  l_ticket_type_name                         tf_ticket_types.ticket_type_name%type;
  l_ticket_type_code                         tf_ticket_types.ticket_type_code%type;
  l_ticket_number                            varchar2(15);
  l_result                                   varchar2(25);
begin
  logger.append_param(l_params, 'p_ticket_type_id', p_ticket_type_id);
  logger.log('START', l_scope, null, l_params);

  begin
    select ticket_type_name
         , ticket_type_code
      into l_ticket_type_name
         , l_ticket_type_code
      from tf_ticket_types
     where ticket_type_id = p_ticket_type_id;
  exception
    when no_data_found then
      l_ticket_type_name := 'STD';
      l_ticket_type_code := 'STD';
  end;

  l_ticket_number   := generate_ticket_sequence(l_ticket_type_code);
  l_result         := l_ticket_type_name || '-' || l_ticket_number;

  return l_result;

  logger.log('END', l_scope, null, l_params);
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end generate_ticket_number;











end tf_tickets_utils;
/