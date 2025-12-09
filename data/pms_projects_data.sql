-- PMS Projects Data Examples
-- These examples assume tenant_id = 1. Please adjust according to your actual tenant setup.
-- Ensure that referenced currency_id and user_ids (project_manager_id, project_lead_id) exist in their respective tables.

-- Example 1: Minimal required fields
INSERT INTO pms_projects (tenant_id, project_code, project_name)
VALUES (1, 'PROJ-001', 'Website Redesign');

-- Example 2: Full record with budget, dates, and URLs
INSERT INTO pms_projects (
    tenant_id
  , project_code
  , project_name
  , project_description
  , start_date
  , end_date
  , budget
  , currency_id
  , project_url
  , repository_url
  , active_yn
) VALUES (
    1
  , 'PROJ-002'
  , 'Mobile App Development'
  , 'Development of iOS and Android apps for the new platform.'
  , TO_DATE('2023-01-01', 'YYYY-MM-DD')
  , TO_DATE('2023-06-30', 'YYYY-MM-DD')
  , 50000
  , 1 -- Assuming 1 is USD or base currency
  , 'https://confluence.example.com/display/MOBILE'
  , 'https://github.com/example/mobile-app'
  , 'Y'
);

-- Example 3: Internal Project with current date as start date
INSERT INTO pms_projects (
    tenant_id
  , project_code
  , project_name
  , project_description
  , start_date
  , active_yn
) VALUES (
    1
  , 'INT-001'
  , 'Internal Training'
  , 'Employee upskilling program for Q1.'
  , TRUNC(SYSDATE)
  , 'Y'
);

COMMIT;
