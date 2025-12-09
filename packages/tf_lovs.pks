create or replace package tf_lovs as


function get_workflow_templates(
  include_inactive_yn in varchar2 default 'N'
) return core_lov_table;



function get_boards(
    p_sprint_id                            in pms_sprints.sprint_id%type default null
  , p_include_inactive_yn                  in varchar2 default 'N'
) return core_lov_table;




end tf_lovs;
/