-- Core Users Compound Trigger
-- Version: 2.0
-- Description: Compound trigger for core_users table (refactored for entity structure)
-- Author: Angel Flores
-- Date: 2025/August/24

create or replace trigger core_users_compound_trg
for insert or update on core_users
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

end core_users_compound_trg;
/
