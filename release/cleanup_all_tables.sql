-- TaskFlow Cleanup Script
-- Version: 1.0
-- Description: Drops all tables created by release/all_tables.sql in dependency-safe order

prompt ====================================
prompt Dropping TaskFlow tables
prompt ====================================

declare
  procedure drop_table(p_table_name in varchar2) is
  begin
    execute immediate 'drop table ' || p_table_name || ' cascade constraints purge';
    dbms_output.put_line('Dropped table ' || p_table_name || '.');
  exception
    when others then
      if sqlcode = -942 then
        dbms_output.put_line('Table ' || p_table_name || ' does not exist. Skipping.');
      else
        raise;
      end if;
  end;
begin
  drop_table('tf_ticket_attachments');
  drop_table('tf_ticket_comments');
  drop_table('tf_ticket_history');
  drop_table('tf_tickets');
  drop_table('tf_board_columns');
  drop_table('tf_boards');
  drop_table('tf_ticket_priorities');
  drop_table('tf_ticket_types');
  drop_table('pms_sprints');
  drop_table('pms_projects');
  drop_table('core_users');
end;
/

prompt ====================================
prompt TaskFlow tables dropped
prompt ====================================

