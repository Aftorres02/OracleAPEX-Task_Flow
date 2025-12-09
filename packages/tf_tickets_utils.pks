create or replace package tf_tickets_utils as

function generate_ticket_number(
    p_ticket_type_id                        in tf_ticket_types.ticket_type_id%type default null
)
return varchar2;

end tf_tickets_utils;
/