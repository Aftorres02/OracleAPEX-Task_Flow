set define off;

prompt tf_ticket_types_data.sql
prompt ...Merges into tf_ticket_types

merge into tf_ticket_types t
using (
    select 'Bug' as ticket_type_name
         , 'BUG' as ticket_type_code
         , 'BUG' as ticket_type_prefix
         , 'A defect or error in the software' as description
         , '#dc3545' as hex_color
         , 'fa-bug' as class_icon
         , 10 as display_seq
         , 'N' as default_yn
         , 'Y' as active_yn
    from dual
    union all
    select 'Feature'
         , 'FEATURE'
         , 'FEAT'
         , 'A new functionality or feature'
         , '#28a745' as hex_color
         , 'fa-star' as class_icon
         , 20
         , 'Y'
         , 'Y'
    from dual
    union all
    select 'Task'
         , 'TASK'
         , 'TASK'
         , 'A generic task or work item'
         , '#007bff' as hex_color
         , 'fa-check-square-o' as class_icon
         , 30
         , 'N'
         , 'Y'
    from dual
    union all
    select 'Documentation'
         , 'DOCUMENTATION'
         , 'DOC'
         , 'Documentation updates or creation'
         , '#17a2b8' as hex_color
         , 'fa-book' as class_icon
         , 40
         , 'N'
         , 'Y'
    from dual
    union all
    select 'Enhancement'
         , 'ENHANCEMENT'
         , 'ENH'
         , 'Improvement to an existing feature'
         , '#ffc107' as hex_color
         , 'fa-rocket' as class_icon
         , 50
         , 'N'
         , 'Y'
    from dual
) s
on (t.ticket_type_code = s.ticket_type_code)
when matched then update set
    t.ticket_type_name = s.ticket_type_name
  , t.ticket_type_prefix = s.ticket_type_prefix
  , t.description = s.description
  , t.hex_color = s.hex_color
  , t.class_icon = s.class_icon
  , t.display_seq = s.display_seq
  , t.default_yn = s.default_yn
  , t.active_yn = s.active_yn
when not matched then insert (
    ticket_type_name
  , ticket_type_code
  , ticket_type_prefix
  , description
  , hex_color
  , class_icon
  , display_seq
  , default_yn
  , active_yn
) values (
    s.ticket_type_name
  , s.ticket_type_code
  , s.ticket_type_prefix
  , s.description
  , s.hex_color
  , s.class_icon
  , s.display_seq
  , s.default_yn
  , s.active_yn
);

commit;
/
