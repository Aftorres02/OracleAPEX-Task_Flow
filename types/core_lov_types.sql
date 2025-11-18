-- Core LOV Types
-- Version: 1.0
-- Description: Reusable table types for LOV functions

begin
  execute immediate 'drop type core_lov_table force';
exception
  when others then null;
end;
/

begin
  execute immediate 'drop type core_lov_row force';
exception
  when others then null;
end;
/

create or replace type core_lov_row as object (
    display_value    varchar2(4000 char)
  , return_value     varchar2(4000 char)
  , display_seq      number
);
/

create or replace type core_lov_table as table of core_lov_row;
/

