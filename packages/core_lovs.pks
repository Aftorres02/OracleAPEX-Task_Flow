create or replace package core_lovs as

  /**
   * Returns currencies as a pipelined table for use in APEX LOVs
   * 
   * @example
   * select display_value d, return_value r, display_seq s
   *   from table(core_lovs.get_currencies(include_inactive_yn => 'N'))
   *  order by display_seq;
   * 
   * @param include_inactive_yn Include inactive currencies (Y) or only active (N)
   * @return core_lov_table Table with display_value, return_value, and display_seq
   * @author Angel Flores (Contractor)
   * @created 16/November/2025
   */
  function get_currencies(
    include_inactive_yn in varchar2 default 'N'
  ) return core_lov_table;




function get_users(
    include_inactive_yn in varchar2 default 'N'
) return core_lov_table;





end core_lovs;
/