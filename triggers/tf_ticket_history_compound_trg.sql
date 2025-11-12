-- TF Ticket History Compound Trigger
-- Version: 1.0
-- Description: Compound trigger for tf_ticket_history table
-- Author: Angel Flores
-- Date: 2025/August/24

create or replace trigger tf_ticket_history_compound_trg
for insert or update on tf_ticket_history
compound trigger

  -- =================================================================================
  -- BEFORE EACH ROW section
  before each row is
  begin

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




end tf_ticket_history_compound_trg;
/
