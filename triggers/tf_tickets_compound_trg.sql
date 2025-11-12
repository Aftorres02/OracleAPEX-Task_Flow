-- TF Tickets Compound Trigger
-- Version: 1.0
-- Description: Compound trigger for tf_tickets table
-- Author: Angel Flores
-- Date: 2025/August/24

create or replace trigger tf_tickets_compound_trg
for insert or update on tf_tickets
compound trigger

  -- =================================================================================
  -- BEFORE EACH ROW section
  before each row is
  begin

    -- =================================================================================
    -- INSERTING
    -- =================================================================================
    -- Handle INSERT operations
    if inserting then
      -- Set tenant_id from APEX session context
      -- :new.tenant_id := sys_context('APEX$SESSION', 'APP_TENANT_ID');
     /*  if :new.ticket_number is null then
        :new.ticket_number := tf_tickets_utils.generate_ticket_number(:new.ticket_type_id);
      end if; */
      -- :new.priority := 'MEDIUM';
      --:new.active_yn := 'Y';
      null;
    end if;
    -- =================================================================================




    -- =================================================================================
    -- UPDATING
    -- =================================================================================
    -- Handle UPDATE operations
    if updating then
      :new.last_updated_on := localtimestamp;
      :new.last_updated_by := coalesce(
                             sys_context('APEX$SESSION','app_user')
                           , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                           , sys_context('userenv','session_user')
                         );
    end if;
    -- =================================================================================


  end before each row;
  -- =================================================================================




end tf_tickets_compound_trg;
/
