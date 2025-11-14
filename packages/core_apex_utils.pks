create or replace package core_apex_utils as

  -- ========================================
  -- Application Process

  function custom_authentication(
      p_username                  IN VARCHAR2,
      p_password                  IN VARCHAR2
  )
  return boolean;




end core_apex_utils;
/