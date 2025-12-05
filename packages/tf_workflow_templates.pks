create or replace package tf_workflow_templates_api as


procedure create_board_columns_from_template(
    p_board_id                                  in tf_boards.board_id%type
  , p_workflow_template_id                      in tf_workflow_templates.workflow_template_id%type
);



function clone_template(
    p_workflow_template_id                       in tf_workflow_templates.workflow_template_id%type
  , p_new_template_name                          in tf_workflow_templates.template_name%type
  , p_new_template_code                          in tf_workflow_templates.template_code%type
)
return tf_workflow_templates.workflow_template_id%type;



end tf_workflow_templates_api;
/