-- APEX Icons Table
-- Generated from icons.js

create table tf_apex_icons (
    category_code                varchar2(50 char) not null
  , category_name                varchar2(100 char) not null
  , icon_name                    varchar2(100 char) not null
  , tags                         varchar2(4000 char)
  , created_by                   varchar2(60 char) default
                                  coalesce(
                                    sys_context('APEX$SESSION','app_user')
                                  , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                                  , sys_context('userenv','session_user')
                                  )
                                  not null
  , created_on                   timestamp with local time zone default localtimestamp not null
  , constraint pk_tf_apex_icons primary key (category_code, icon_name)
  , constraint tf_apex_icons_ck_01 check (category_code = upper(trim(category_code)) and instr(category_code, ' ') = 0)
);

-- table comment
begin
  execute immediate 'comment on table tf_apex_icons is ''Stores Oracle APEX icons and their categories/tags.''';
  execute immediate 'comment on column tf_apex_icons.category_code is ''Internal category code (e.g. WEB_APPLICATION).''';
  execute immediate 'comment on column tf_apex_icons.category_name is ''Display name for the category (e.g. Web Application).''';
  execute immediate 'comment on column tf_apex_icons.icon_name is ''Icon class name (e.g. fa-user).''';
  execute immediate 'comment on column tf_apex_icons.tags is ''Search tags or filters associated with the icon.''';
end;
/
