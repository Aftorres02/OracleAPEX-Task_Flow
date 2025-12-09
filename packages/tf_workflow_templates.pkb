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
 * @param p_workflow_template_id
 */
procedure create_board_columns_from_template(
    p_sprint_id                                     in pms_sprints.sprint_id%type
  , p_workflow_template_id                          in tf_workflow_templates.workflow_template_id%type
)
is
  l_scope  logger_logs.scope%type := gc_scope_prefix || 'create_board_columns_from_template';
  l_params logger.tab_param;

  l_board_id                                  tf_boards.board_id%type;
  l_template_name                             tf_workflow_templates.template_name%type;
  l_template_code                             tf_workflow_templates.template_code%type;
  l_exists                                    number;
begin
  logger.append_param(l_params, 'p_sprint_id', p_sprint_id);
  logger.append_param(l_params, 'p_workflow_template_id', p_workflow_template_id);
  logger.log('START', l_scope, null, l_params);

  select template_name
       , template_code
    into l_template_name
       , l_template_code
    from tf_workflow_templates
   where workflow_template_id = p_workflow_template_id;


  begin
    select count(1)
      into l_exists
      from tf_boards b
     where b.sprint_id = p_sprint_id
       and b.workflow_template_id = p_workflow_template_id;

    if l_exists > 0 then
      raise_application_error(-20001, 'Board "' || l_template_name || '" already exists for this sprint and template');
    end if;
  exception
    when no_data_found then
      null;
  end;


  insert
    into tf_boards (
         sprint_id
       , board_name
       , board_code
       , description
       , workflow_template_id
       , active_yn
     )
  values (p_sprint_id
       , l_template_name
       , l_template_code
       , null
       , p_workflow_template_id
       , 'Y'
      )
 returning board_id into l_board_id;

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
    select l_board_id
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