create or replace package tf_tickets_api as




procedure add_ticket(
    p_board_column_id             in tf_board_columns.board_column_id%type
  , p_ticket_type_id              in tf_tickets.ticket_type_id%type
  , p_title                       in tf_tickets.title%type
  , p_description                 in tf_tickets.description%type default null
  , p_priority_id                 in tf_tickets.priority_id%type
  , p_assignee_id                 in tf_tickets.assignee_id%type default null
  , p_reporter_id                 in tf_tickets.reporter_id%type default null
  , p_estimated_hours             in tf_tickets.estimated_hours%type default null
  , p_actual_hours                in tf_tickets.actual_hours%type default null
  , p_due_on                      in tf_tickets.due_on%type default null
  , p_start_on                    in tf_tickets.start_on%type default sysdate
  , p_end_on                      in tf_tickets.end_on%type default null
  , p_tags                        in tf_tickets.tags%type default null
  , p_active_yn                   in tf_tickets.active_yn%type default 'Y'
);








-- ======================================================
-- AJAX PROCEDURES
-- ======================================================

procedure get_tickets_for_column_ajax;


procedure move_ticket_ajax;


end tf_tickets_api;
/