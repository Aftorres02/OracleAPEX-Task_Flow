-- TaskFlow All Tables
-- Version: 1.0
-- Description: Combined script to create all TaskFlow tables
-- Execution Order: Tables are ordered by dependencies to ensure proper creation

prompt ====================================
prompt Creating TaskFlow Tables
prompt ====================================

-- ====================================
-- Base Tables (no TF dependencies)
-- ====================================

prompt Creating core_users table...
@../tables/core_users.sql

prompt Creating pms_projects table...
@../tables/pms_projects.sql

prompt Creating pms_sprints table...
@../tables/pms_sprints.sql

prompt Creating tf_ticket_types table...
@../tables/tf_ticket_types.sql

prompt Creating tf_ticket_priorities table...
@../tables/tf_ticket_priorities.sql

prompt Creating tf_boards table...
@../tables/tf_boards.sql

-- ====================================
-- Dependent Tables
-- ====================================

prompt Creating tf_board_columns table...
@../tables/tf_board_columns.sql

prompt Creating tf_tickets table...
@../tables/tf_tickets.sql

-- ====================================
-- Ticket Related Tables
-- ====================================

prompt Creating tf_ticket_history table...
@../tables/tf_ticket_history.sql

prompt Creating tf_ticket_attachments table...
@../tables/tf_ticket_attachments.sql

prompt Creating tf_ticket_comments table...
@../tables/tf_ticket_comments.sql

prompt ====================================
prompt All TaskFlow tables created successfully
prompt ====================================
