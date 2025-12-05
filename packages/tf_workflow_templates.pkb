create or replace package body tf_workflow_templates_api as

  gc_scope_prefix constant varchar2(31) := lower($$plsql_unit) || '.';




/**
 * 
 *
 *
 * @example
 *
 * @issue
 *
 * @author Angel Flores
 * @created  Tuesday, 02/December/2025
 * @param p_board_id
 * @param p_workflow_template_id
 */
procedure create_board_columns_from_template(
      p_board_id                                      in tf_boards.board_id%type
    , p_workflow_template_id                          in tf_workflow_templates.workflow_template_id%type
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'create_board_columns_from_template';
  l_params logger.tab_param;
begin
  logger.append_param(l_params, 'p_board_id', p_board_id);
  logger.append_param(l_params, 'p_workflow_template_id', p_workflow_template_id);
  logger.log('START', l_scope, null, l_params);

    -- Create columns from template
    insert
      into tf_board_columns (
           board_id
         , column_name
         , display_seq
         , class_color
         , class_icon
         , description
         , active_yn
       )
    select p_board_id
         , wtc.column_name
         , wtc.display_seq
         , wtc.hex_color
         , wtc.class_icon
         , wtc.description
         , 'Y'
      from tf_workflow_template_columns wtc
     where wtc.workflow_template_id = p_workflow_template_id
       and wtc.active_yn = 'Y'
     order by wtc.display_seq;


    -- Update board with template reference
    update tf_boards
       set workflow_template_id = p_workflow_template_id
     where board_id = p_board_id;

  logger.log('END', l_scope, null, l_params);
  exception
    when OTHERS then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
end create_board_columns_from_template;






  /**
   * Clones a workflow template
   */
  function clone_template(
      p_workflow_template_id                     in tf_workflow_templates.workflow_template_id%type
    , p_new_template_name                        in tf_workflow_templates.template_name%type
    , p_new_template_code                        in tf_workflow_templates.template_code%type
  )
  return tf_workflow_templates.workflow_template_id%type
  as
    l_scope logger_logs.scope%type := gc_scope_prefix || 'clone_template';
    l_params logger.tab_param;
    l_new_template_id number;
  begin
    -- logger.append_param(l_params, 'p_workflow_template_id', p_workflow_template_id);
    -- logger.append_param(l_params, 'p_new_template_name', p_new_template_name);
    -- logger.log('START', l_scope, null, l_params);

    -- Create new template
/*     l_new_template_id := create_template(
        p_template_name => p_new_template_name
      , p_template_code => p_new_template_code
      , p_system_template_yn => 'N'
    ); */

    -- Clone columns
    insert into tf_workflow_template_columns (
        workflow_template_id
      , column_name
      , display_seq
      , hex_color
      , class_icon
      , description
      , active_yn
    )
    select
        l_new_template_id
      , column_name
      , display_seq
      , hex_color
      , class_icon
      , description
      , active_yn
      from tf_workflow_template_columns
     where workflow_template_id = p_workflow_template_id
       and active_yn = 'Y';

    -- Clone transitions
/*     insert into tf_workflow_transitions (
        workflow_template_id
      , from_column_seq
      , to_column_seq
      , transition_name
      , required_fields
      , auto_assign_role
      , validation_rule
      , active_yn
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
      from tf_workflow_transitions
     where workflow_template_id = p_workflow_template_id
       and active_yn = 'Y'; */

    return l_new_template_id;

    logger.log('END', l_scope, null, l_params);
  exception
    when others then
      logger.log_error('Unhandled Exception', l_scope, null, l_params);
      raise;
  end clone_template;





end tf_workflow_templates_api;
/