set serveroutput on
variable g_estado number;
DECLARE

  p_dff_vg                      xx_util_pk.dff_vg_tbl_type;
  v_mesg_error                  VARCHAR2(2000) := NULL;
BEGIN
    :g_estado:=0;
    -- --------------------------------------
    -- Ejemplo de Ejecucion
    -- --------------------------------------
    p_dff_vg.delete;
    p_dff_vg(1).desc_appl_name := 'FND';
    p_dff_vg(1).desc_flex_name := 'FND_FLEX_VALUES';

    IF NOT xx_util_pk.validate_dff_view_generation(p_dff_vg, v_mesg_error) THEN
      :g_estado:=1;
      dbms_output.put_line( v_mesg_error);
    END IF;
END;
/
exit :g_estado
