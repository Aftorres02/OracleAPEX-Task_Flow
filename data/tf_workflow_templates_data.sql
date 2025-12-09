-- TaskFlow Workflow Templates Data Load
-- Version: 1.0
-- Description: Load workflow templates with columns and transitions
-- This script loads 8 common workflow templates:
--   1. Simple Kanban (3 columns)
--   2. Software Development (6 columns)
--   3. Software Development Complete (8 columns)
--   4. Bug Tracking (6 columns)
--   5. Content Approval (5 columns)
--   6. Purchase Request (5 columns)
--   7. IT Support Ticket (6 columns)
--   8. HR Recruitment (6 columns)

prompt ====================================
prompt Loading Workflow Templates Data
prompt ====================================

-- Step 1: Load Workflow Templates
prompt Loading workflow templates...

merge into tf_workflow_templates t
using (
  select 'SIMPLE_KANBAN' as template_code, 'Simple Kanban' as template_name from dual union all
  select 'SOFTWARE_DEV', 'Software Development' from dual union all
  select 'SOFTWARE_DEV_COMPLETE', 'Software Development Complete' from dual union all
  select 'BUG_TRACKING', 'Bug Tracking' from dual union all
  select 'CONTENT_APPROVAL', 'Content Approval' from dual union all
  select 'PURCHASE_REQUEST', 'Purchase Request' from dual union all
  select 'IT_SUPPORT', 'IT Support Ticket' from dual union all
  select 'HR_RECRUITMENT', 'HR Recruitment' from dual
) s on (t.template_code = s.template_code)
when matched then
  update set
    t.template_name = s.template_name
  , t.active_yn = 'Y'
  , t.last_updated_by = coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                      )
  , t.last_updated_on = localtimestamp
when not matched then
  insert (
    template_code
  , template_name
  , active_yn
  , created_by
  , created_on
  )
  values (
    s.template_code
  , s.template_name
  , 'Y'
  , coalesce(
      sys_context('APEX$SESSION','app_user')
    , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
    , sys_context('userenv','session_user')
    )
  , localtimestamp
  );
/
commit;
/
-- Step 2: Load Workflow Template Columns
prompt Loading workflow template columns...
merge into tf_workflow_template_columns t
using (
  -- Simple Kanban (3 columns)
  select wt.workflow_template_id, 'To Do' as column_name, 'TODO' as column_code, 10 as display_seq, '#2196F3' as hex_color, 'fa-list' as class_icon, 'Items that need to be started.' as description from tf_workflow_templates wt where wt.template_code = 'SIMPLE_KANBAN' union all
  select wt.workflow_template_id, 'In Progress', 'IN_PROGRESS', 20, '#FFC107', 'fa-spinner', 'Items currently being worked on.' from tf_workflow_templates wt where wt.template_code = 'SIMPLE_KANBAN' union all
  select wt.workflow_template_id, 'Done', 'DONE', 30, '#4CAF50', 'fa-check-circle', 'Completed items.' from tf_workflow_templates wt where wt.template_code = 'SIMPLE_KANBAN' union all
  -- Software Development (6 columns)
  select wt.workflow_template_id, 'Backlog', 'BACKLOG', 10, '#9E9E9E', 'fa-archive', 'Items waiting to be prioritized.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 'To Do', 'TODO', 20, '#2196F3', 'fa-list', 'Items ready to be started.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 'In Progress', 'IN_PROGRESS', 30, '#FFC107', 'fa-code', 'Items currently being developed.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 'Code Review', 'CODE_REVIEW', 40, '#FF9800', 'fa-eye', 'Items awaiting code review.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 'Testing', 'TESTING', 50, '#9C27B0', 'fa-flask', 'Items in testing phase.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 'Done', 'DONE', 60, '#4CAF50', 'fa-check-circle', 'Completed and deployed items.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  -- Software Development Complete (8 columns)
  select wt.workflow_template_id, 'Backlog', 'BACKLOG', 10, '#9E9E9E', 'fa-archive', 'Items waiting to be prioritized.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'Ready', 'READY', 20, '#03A9F4', 'fa-rocket', 'Items ready to be started.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'In Progress', 'IN_PROGRESS', 30, '#FFC107', 'fa-code', 'Items currently being developed.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'Code Review', 'CODE_REVIEW', 40, '#FF9800', 'fa-eye', 'Items awaiting code review.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'Pass Code Review', 'PASS_CODE_REVIEW', 50, '#4CAF50', 'fa-check-square-o', 'Code review passed and approved.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'Testing', 'TESTING', 60, '#9C27B0', 'fa-flask', 'Items in testing phase.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'PROD', 'PROD', 70, '#1976D2', 'fa-server', 'Items deployed to production.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 'CLOSED', 'CLOSED', 80, '#616161', 'fa-times-circle', 'Items closed and archived.' from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  -- Bug Tracking (6 columns)
  select wt.workflow_template_id, 'New', 'NEW', 10, '#F44336', 'fa-bug', 'Newly reported bugs.' from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 'Assigned', 'ASSIGNED', 20, '#FF9800', 'fa-user-plus', 'Bugs assigned to a developer.' from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 'In Progress', 'IN_PROGRESS', 30, '#FFC107', 'fa-wrench', 'Bugs being actively fixed.' from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 'Testing', 'TESTING', 40, '#9C27B0', 'fa-flask', 'Bugs being tested after fix.' from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 'Resolved', 'RESOLVED', 50, '#8BC34A', 'fa-check', 'Bugs fixed and verified.' from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 'Closed', 'CLOSED', 60, '#616161', 'fa-times-circle', 'Bugs closed and archived.' from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  -- Content Approval (5 columns)
  select wt.workflow_template_id, 'Draft', 'DRAFT', 10, '#9E9E9E', 'fa-file-text-o', 'Content in draft stage.' from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 'Review', 'REVIEW', 20, '#FFC107', 'fa-search', 'Content under review.' from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 'Approved', 'APPROVED', 30, '#4CAF50', 'fa-check-circle', 'Content approved for publication.' from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 'Published', 'PUBLISHED', 40, '#2196F3', 'fa-globe', 'Content published and live.' from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 'Archived', 'ARCHIVED', 50, '#616161', 'fa-archive', 'Content archived.' from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  -- Purchase Request (5 columns)
  select wt.workflow_template_id, 'Requested', 'REQUESTED', 10, '#2196F3', 'fa-shopping-cart', 'Purchase requests submitted.' from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 'Approved', 'APPROVED', 20, '#4CAF50', 'fa-check', 'Purchase requests approved.' from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 'Ordered', 'ORDERED', 30, '#FF9800', 'fa-truck', 'Purchase orders placed.' from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 'Received', 'RECEIVED', 40, '#9C27B0', 'fa-cube', 'Items received.' from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 'Closed', 'CLOSED', 50, '#616161', 'fa-lock', 'Purchase requests closed.' from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  -- IT Support Ticket (6 columns)
  select wt.workflow_template_id, 'New', 'NEW', 10, '#F44336', 'fa-ticket', 'New support tickets.' from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 'Assigned', 'ASSIGNED', 20, '#FF9800', 'fa-user', 'Tickets assigned to support staff.' from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 'In Progress', 'IN_PROGRESS', 30, '#FFC107', 'fa-cog', 'Tickets being actively worked on.' from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 'Waiting Customer', 'WAITING_CUSTOMER', 40, '#2196F3', 'fa-clock-o', 'Tickets waiting for customer response.' from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 'Resolved', 'RESOLVED', 50, '#4CAF50', 'fa-check-circle', 'Tickets resolved.' from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 'Closed', 'CLOSED', 60, '#616161', 'fa-times', 'Tickets closed.' from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  -- HR Recruitment (6 columns)
  select wt.workflow_template_id, 'Open', 'OPEN', 10, '#2196F3', 'fa-briefcase', 'Open job positions.' from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 'Screening', 'SCREENING', 20, '#FFC107', 'fa-filter', 'Candidates being screened.' from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 'Interview', 'INTERVIEW', 30, '#FF9800', 'fa-handshake-o', 'Candidates in interview process.' from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 'Offer', 'OFFER', 40, '#9C27B0', 'fa-file-text-o', 'Job offers extended.' from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 'Hired', 'HIRED', 50, '#4CAF50', 'fa-check-square-o', 'Candidates hired.' from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 'Rejected', 'REJECTED', 60, '#F44336', 'fa-user-times', 'Candidates rejected.' from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT'
) s on (
  t.workflow_template_id = s.workflow_template_id
  and t.column_code = s.column_code
)
when matched then
  update set
    t.column_name = s.column_name
  , t.display_seq = s.display_seq
  , t.hex_color = s.hex_color
  , t.class_icon = s.class_icon
  , t.description = s.description
  , t.active_yn = 'Y'
  , t.last_updated_by = coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                      )
  , t.last_updated_on = localtimestamp
when not matched then
  insert (
    workflow_template_id
  , column_name
  , column_code
  , display_seq
  , hex_color
  , class_icon
  , description
  , active_yn
  , created_by
  , created_on
  )
  values (
    s.workflow_template_id
  , s.column_name
  , s.column_code
  , s.display_seq
  , s.hex_color
  , s.class_icon
  , s.description
  , 'Y'
  , coalesce(
      sys_context('APEX$SESSION','app_user')
    , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
    , sys_context('userenv','session_user')
    )
  , localtimestamp
  );

commit;
/
-- Step 3: Load Workflow Transitions
prompt Loading workflow transitions...
/*
merge into tf_workflow_transitions t
using (
  -- Simple Kanban transitions (linear flow)
  select wt.workflow_template_id, 10 as from_seq, 20 as to_seq, 'Start Work' as transition_name, null as required_fields, null as auto_assign_role, null as validation_rule from tf_workflow_templates wt where wt.template_code = 'SIMPLE_KANBAN' union all
  select wt.workflow_template_id, 20, 30, 'Complete', null, null, null from tf_workflow_templates wt where wt.template_code = 'SIMPLE_KANBAN' union all
  select wt.workflow_template_id, 20, 10, 'Move Back', null, null, null from tf_workflow_templates wt where wt.template_code = 'SIMPLE_KANBAN' union all
  
  -- Software Development transitions
  select wt.workflow_template_id, 10, 20, 'Prioritize', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 20, 30, 'Start Development', 'ASSIGNEE_ID', 'DEVELOPER', null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 30, 40, 'Submit for Review', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 40, 50, 'Approve and Test', null, 'QA', null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 40, 30, 'Request Changes', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 50, 60, 'Complete', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  select wt.workflow_template_id, 50, 30, 'Reopen', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV' union all
  
  -- Software Development Complete transitions
  select wt.workflow_template_id, 10, 20, 'Prioritize', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 20, 30, 'Start Development', 'ASSIGNEE_ID', 'DEVELOPER', null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 30, 40, 'Submit for Review', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 40, 50, 'Approve Code', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 40, 30, 'Request Changes', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 50, 60, 'Start Testing', null, 'QA', null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 60, 70, 'Deploy to PROD', null, 'DEVOPS', null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 60, 30, 'Reopen for Fixes', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  select wt.workflow_template_id, 70, 80, 'Close', null, null, null from tf_workflow_templates wt where wt.template_code = 'SOFTWARE_DEV_COMPLETE' union all
  
  -- Bug Tracking transitions
  select wt.workflow_template_id, 10, 20, 'Assign Bug', 'ASSIGNEE_ID', null, null from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 20, 30, 'Start Fix', null, null, null from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 30, 40, 'Submit for Testing', null, 'QA', null from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 40, 50, 'Verify Fix', null, null, null from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 40, 30, 'Reopen Bug', null, null, null from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  select wt.workflow_template_id, 50, 60, 'Close', null, null, null from tf_workflow_templates wt where wt.template_code = 'BUG_TRACKING' union all
  
  -- Content Approval transitions
  select wt.workflow_template_id, 10, 20, 'Submit for Review', null, null, null from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 20, 30, 'Approve', null, null, null from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 20, 10, 'Request Changes', null, null, null from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 30, 40, 'Publish', null, null, null from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  select wt.workflow_template_id, 40, 50, 'Archive', null, null, null from tf_workflow_templates wt where wt.template_code = 'CONTENT_APPROVAL' union all
  
  -- Purchase Request transitions
  select wt.workflow_template_id, 10, 20, 'Approve Request', null, 'MANAGER', null from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 10, 50, 'Reject Request', null, null, null from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 20, 30, 'Place Order', null, 'PROCUREMENT', null from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 30, 40, 'Receive Items', null, null, null from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  select wt.workflow_template_id, 40, 50, 'Close Request', null, null, null from tf_workflow_templates wt where wt.template_code = 'PURCHASE_REQUEST' union all
  
  -- IT Support Ticket transitions
  select wt.workflow_template_id, 10, 20, 'Assign Ticket', 'ASSIGNEE_ID', null, null from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 20, 30, 'Start Work', null, null, null from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 30, 40, 'Wait for Customer', null, null, null from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 40, 30, 'Resume Work', null, null, null from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 30, 50, 'Resolve', null, null, null from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  select wt.workflow_template_id, 50, 60, 'Close Ticket', null, null, null from tf_workflow_templates wt where wt.template_code = 'IT_SUPPORT' union all
  
  -- HR Recruitment transitions
  select wt.workflow_template_id, 10, 20, 'Screen Candidate', null, 'RECRUITER', null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 20, 30, 'Schedule Interview', null, null, null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 20, 60, 'Reject Early', null, null, null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 30, 40, 'Extend Offer', null, null, null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 30, 60, 'Reject After Interview', null, null, null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 40, 50, 'Accept Offer', null, null, null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT' union all
  select wt.workflow_template_id, 40, 60, 'Reject Offer', null, null, null from tf_workflow_templates wt where wt.template_code = 'HR_RECRUITMENT'
) s on (
  t.workflow_template_id = s.workflow_template_id
  and t.from_column_seq = s.from_seq
  and t.to_column_seq = s.to_seq
)
when matched then
  update set
    t.transition_name = s.transition_name
  , t.required_fields = s.required_fields
  , t.auto_assign_role = s.auto_assign_role
  , t.validation_rule = s.validation_rule
  , t.active_yn = 'Y'
  , t.last_updated_by = coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                      )
  , t.last_updated_on = localtimestamp
when not matched then
  insert (
    workflow_template_id
  , from_column_seq
  , to_column_seq
  , transition_name
  , required_fields
  , auto_assign_role
  , validation_rule
  , active_yn
  , created_by
  , created_on
  )
  values (
    s.workflow_template_id
  , s.from_seq
  , s.to_seq
  , s.transition_name
  , s.required_fields
  , s.auto_assign_role
  , s.validation_rule
  , 'Y'
  , coalesce(
      sys_context('APEX$SESSION','app_user')
    , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
    , sys_context('userenv','session_user')
    )
  , localtimestamp
  );

commit;
*/
/
prompt ====================================
prompt Workflow templates data loaded successfully
prompt ====================================
prompt 
prompt Loaded 8 workflow templates:
prompt   - Simple Kanban (3 columns)
prompt   - Software Development (6 columns)
prompt   - Software Development Complete (8 columns)
prompt   - Bug Tracking (6 columns)
prompt   - Content Approval (5 columns)
prompt   - Purchase Request (5 columns)
prompt   - IT Support Ticket (6 columns)
prompt   - HR Recruitment (6 columns)
prompt ====================================

