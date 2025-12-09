create or replace package body tf_lovs as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';



  /**
   * Returns workflow templates as a pipelined table for use in APEX LOVs
   * 
   * @example
   * select display_value d, return_value r, display_seq s
   *   from table(tf_lovs.get_workflow_templates(include_inactive_yn => 'N'))
   *  order by display_seq;
   * 
   * @param include_inactive_yn Include inactive workflow templates (Y) or only active (N)
   * @return core_lov_table Table with display_value, return_value, and display_seq
   * @author Angel Flores
   * @created 16/November/2025
   */
  function get_workflow_templates(
    include_inactive_yn in varchar2 default 'N'
  ) return core_lov_table
  is
    l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_workflow_templates';
    l_params logger.tab_param;

    l_result core_lov_table;
  begin
    -- logger.append_param(l_params, 'include_inactive_yn', include_inactive_yn);
    -- logger.log('START', l_scope, null, l_params);

      select core_lov_row(
             template_name
           , workflow_template_id
           , template_name
      )
        bulk collect
        into l_result
        from tf_workflow_templates
       where active_yn = 'Y' or include_inactive_yn = 'Y'
       order by template_name;

    --logger.log('END', l_scope, null, l_params);
    return l_result;
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end get_workflow_templates;







/**
 * Returns boards as a pipelined table for use in APEX LOVs
 *
 * @example
 * select display_value d
        , return_value r
     from table(tf_lovs.get_boards(sprint_id => 1))
    order by display_value;
 *
 * @param p_sprint_id Sprint ID to filter boards by
 * @param p_include_inactive_yn Include inactive boards (Y) or only active (N)
 * @return core_lov_table Table with display_value, return_value, and display_seq
 * @author Angel Flores
 * @created 16/November/2025
 */
function get_boards(
    p_sprint_id                            in pms_sprints.sprint_id%type default null
  , p_include_inactive_yn                  in varchar2 default 'N'
) return core_lov_table
is
    l_scope  logger_logs.scope%type := gc_scope_prefix || 'get_boards';
    l_params logger.tab_param;

    l_result core_lov_table;
begin
    -- logger.append_param(l_params, 'p_sprint_id', p_sprint_id);
    -- logger.log('START', l_scope, null, l_params);

      select core_lov_row(
             b.board_name
           , b.board_id
           , b.board_name
      )
        bulk collect
        into l_result
        from tf_boards b
       where (b.sprint_id = p_sprint_id or p_sprint_id is null)
         and (b.active_yn = 'Y' or p_include_inactive_yn = 'Y')
       order by b.board_name;

    --logger.log('END', l_scope, null, l_params);
    return l_result;
exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end get_boards;


end tf_lovs;
/