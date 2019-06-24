CLASS zcl_trans_transports DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPE-POOLS abap .
    TYPE-POOLS sctsc .
    TYPE-POOLS trwbo .

    CONSTANTS cv_msag TYPE symsgid VALUE 'ZTRANS' ##NO_TEXT.
    CONSTANTS cv_msg_type_success TYPE symsgty VALUE 'S' ##NO_TEXT.
    CONSTANTS cv_msg_type_error TYPE symsgty VALUE 'E' ##NO_TEXT.

    METHODS do_transport
      IMPORTING
        !it_orders            TYPE ztrans_i_orders_list
        !iv_system            TYPE sysname
        !iv_order_description TYPE any
        !iv_auto_transport    TYPE sap_bool DEFAULT abap_false
      EXPORTING
        !et_return            TYPE bapiret2_t
        !ev_order_created     TYPE trkorr .
    METHODS get_system_transport
      RETURNING
        VALUE(rt_system) TYPE ztrans_i_system .
    METHODS constructor
      IMPORTING
        !iv_langu TYPE sylangu DEFAULT sy-langu .
    METHODS get_user_orders
      IMPORTING
        !iv_username   TYPE syuname DEFAULT sy-uname
      EXPORTING
        !et_userorders TYPE ztrans_i_userorders .
  PROTECTED SECTION.

    DATA mv_langu TYPE sylangu .

    METHODS check_before_release
      IMPORTING
        !iv_trkorr TYPE trkorr
      EXPORTING
        !et_return TYPE bapiret2_t .
    METHODS check_inactive_objects
      IMPORTING
        !is_request TYPE trwbo_request
      EXPORTING
        !et_return  TYPE bapiret2_t .
    METHODS fill_selections_orders
      IMPORTING
        !iv_type_workbench   TYPE sap_bool DEFAULT abap_true
        !iv_type_customizing TYPE sap_bool DEFAULT abap_true
        !iv_type_transport   TYPE sap_bool DEFAULT abap_true
        !iv_status_modif     TYPE sap_bool DEFAULT abap_true
        !iv_status_rele      TYPE sap_bool DEFAULT abap_false
      RETURNING
        VALUE(rt_selections) TYPE trwbo_selection .
    METHODS load_domain_texts
      EXPORTING
        et_functions TYPE dd07v_tab
        et_status    TYPE dd07v_tab .
    METHODS create_transporte_copies
      IMPORTING
        it_orders            TYPE ztrans_i_orders_list
        iv_system            TYPE sysname
        iv_order_description TYPE any
      EXPORTING
        et_return            TYPE bapiret2_t
        ev_order_created     TYPE trkorr.
    METHODS transport_request_system
      IMPORTING
        iv_order  TYPE trkorr
        iv_system TYPE sysname
      CHANGING
        ct_return TYPE bapiret2_t.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_trans_transports IMPLEMENTATION.


  METHOD check_before_release.
    DATA ls_request TYPE trwbo_request.


    CLEAR et_return.

    ls_request-h-trkorr = iv_trkorr.
    CALL FUNCTION 'TR_READ_REQUEST'
      EXPORTING
        iv_read_e070       = 'X'
        iv_read_e07t       = 'X'
        iv_read_e070c      = 'X'
        iv_read_e070m      = 'X'
        iv_read_objs_keys  = 'X'
        iv_read_attributes = 'X'
      CHANGING
        cs_request         = ls_request
      EXCEPTIONS
        OTHERS             = 1.

* Validacion de objetos inactivos
    check_inactive_objects( EXPORTING is_request = ls_request IMPORTING et_return  = et_return ).


  ENDMETHOD.


  METHOD check_inactive_objects.
    FIELD-SYMBOLS <ls_log> TYPE sprot_u.
    DATA ls_e070  TYPE e070.
    DATA lt_log TYPE STANDARD TABLE OF sprot_u.
    DATA ls_return TYPE bapiret2.

    MOVE-CORRESPONDING is_request-h TO ls_e070.
    CALL FUNCTION 'TRINT_CHECK_INACTIVE_OBJECTS'
      EXPORTING
        is_e070 = ls_e070
        it_e071 = is_request-objects
      TABLES
        et_log  = lt_log[].

    READ TABLE lt_log TRANSPORTING NO FIELDS
                      WITH KEY severity = 'E'.
    IF sy-subrc <> 0.
      READ TABLE lt_log TRANSPORTING NO FIELDS
                        WITH KEY severity = 'A'.
    ENDIF.

    IF sy-subrc = 0.

* Paso el log a la tabla bapiret2
      LOOP AT lt_log ASSIGNING <ls_log>.
        ls_return = zcl_trans_utilidades=>fill_return( iv_type = <ls_log>-severity
                                                       iv_id = <ls_log>-ag
                                                       iv_number = <ls_log>-msgnr
                                                       iv_message_v1 = <ls_log>-var1
                                                       iv_message_v2 = <ls_log>-var2
                                                       iv_message_v3 = <ls_log>-var3
                                                       iv_message_v4 = <ls_log>-var4
                                                       iv_langu      = <ls_log>-langu ).
        INSERT ls_return INTO TABLE et_return.
      ENDLOOP.




    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    IF iv_langu IS INITIAL.
      mv_langu = sy-langu.
    ELSE.
      mv_langu = iv_langu.
    ENDIF.

  ENDMETHOD.


  METHOD create_transporte_copies.
    FIELD-SYMBOLS <ls_orders> TYPE LINE OF ztrans_i_orders_list.
    DATA ld_order_text TYPE e07t-as4text.
    DATA ls_return TYPE bapiret2.
    DATA lt_messages TYPE ctsgerrmsgs.
    CLEAR: et_return, ev_order_created.

* Creamos la orden de transporte de copias
    ld_order_text = iv_order_description.

    CALL FUNCTION 'TRINT_INSERT_NEW_COMM'
      EXPORTING
        wi_kurztext   = ld_order_text
        wi_trfunction = 'T'
        iv_username   = sy-uname
        iv_tarsystem  = iv_system
        wi_client     = sy-mandt
      IMPORTING
        we_trkorr     = ev_order_created
      EXCEPTIONS
        OTHERS        = 1.
    IF sy-subrc = 0.

* Recorro las ordenes/tareas pasadas y voy copiando su contenido a la nueva orden.
      LOOP AT it_orders ASSIGNING <ls_orders>.
        CALL FUNCTION 'TR_COPY_COMM'
          EXPORTING
            wi_dialog                = space
            wi_trkorr_from           = <ls_orders>-order
            wi_trkorr_to             = ev_order_created
            wi_without_documentation = abap_true
          EXCEPTIONS
            OTHERS                   = 1.
      ENDLOOP.

* Chequeo de la orden antes de liberar
      check_before_release( EXPORTING iv_trkorr = ev_order_created
                            IMPORTING et_return = et_return ).

* Si no hay errores se libera la orden
      IF et_return IS INITIAL.

        CALL FUNCTION 'TRINT_RELEASE_REQUEST'
          EXPORTING
            iv_trkorr                   = ev_order_created
            iv_dialog                   = abap_false
            iv_as_background_job        = abap_false
            iv_success_message          = abap_false
            iv_without_objects_check    = abap_false
            iv_without_locking          = abap_true " Evitamos el error de objetos de bloqueo por transporte de copias
            iv_display_export_log       = abap_false
          EXCEPTIONS
            cts_initialization_failure  = 1
            enqueue_failed              = 2
            no_authorization            = 3
            invalid_request             = 4
            request_already_released    = 5
            repeat_too_early            = 6
            object_lock_error           = 7
            object_check_error          = 8
            docu_missing                = 9
            db_access_error             = 10
            action_aborted_by_user      = 11
            export_failed               = 12
            execute_objects_check       = 13
            release_in_bg_mode          = 14
            release_in_bg_mode_w_objchk = 15
            error_in_export_methods     = 16
            object_lang_error           = 17.
        IF sy-subrc = 0.
          ls_return = zcl_trans_utilidades=>fill_return( iv_type = cv_msg_type_success
                                                             iv_id = cv_msag
                                                             iv_number = '001'
                                                             iv_message_v1 = ev_order_created
                                                             iv_langu      = mv_langu ).
          INSERT ls_return INTO TABLE et_return.
        ELSE.
          ls_return = zcl_trans_utilidades=>fill_return( iv_type = cv_msg_type_error
                                                             iv_id = sy-msgid
                                                             iv_number = sy-msgno
                                                             iv_message_v1 = sy-msgv1
                                                             iv_message_v2 = sy-msgv2
                                                             iv_message_v3 = sy-msgv3
                                                             iv_message_v4 = sy-msgv4
                                                             iv_langu      = mv_langu ).
          INSERT ls_return INTO TABLE et_return.
        ENDIF.
      ELSE.

* Borro la orden generada. No controlo posibles errores, porque no deberia de haberlos
        CALL FUNCTION 'TR_DELETE_COMM'
          EXPORTING
            wi_dialog                     = space
            wi_trkorr                     = ev_order_created
          EXCEPTIONS
            file_access_error             = 1
            order_already_released        = 2
            order_contains_c_member       = 3
            order_contains_locked_entries = 4
            order_is_refered              = 5
            repair_order                  = 6
            user_not_owner                = 7
            delete_was_cancelled          = 8
            ordernumber_empty             = 9
            tr_enqueue_failed             = 10
            objects_free_but_still_locks  = 11
            order_lock_failed             = 12
            no_authorization              = 13
            wrong_client                  = 14
            project_still_referenced      = 15
            successors_already_released   = 16
            OTHERS                        = 17.

        CLEAR ev_order_created.

      ENDIF.
    ELSE.
      ls_return = zcl_trans_utilidades=>fill_return( iv_type = cv_msg_type_error
                                                     iv_id = sy-msgid
                                                     iv_number = sy-msgno
                                                     iv_message_v1 = sy-msgv1
                                                     iv_message_v2 = sy-msgv2
                                                     iv_message_v3 = sy-msgv3
                                                     iv_message_v4 = sy-msgv4
                                                     iv_langu      = mv_langu ).
      INSERT ls_return INTO TABLE et_return.
    ENDIF.
  ENDMETHOD.


  METHOD do_transport.
*importing it_orders  type ztrans_i_orders_list
*  iv_system  type sysname
*  iv_order_description  type any
* exporting et_return  type bapiret2_t
*  ev_order_created  type trkorr


* Primero se genera la orden de tipo transporte de copias
    create_transporte_copies( EXPORTING it_orders = it_orders
                                        iv_system = iv_system
                                        iv_order_description = iv_order_description
                              IMPORTING ev_order_created = ev_order_created
                                        et_return = et_return ).

* Si no hay errores y esta marcada la opcion de generar el transporte, se realiza.
    READ TABLE et_return TRANSPORTING NO FIELDS WITH KEY type = cv_msg_type_error.
    IF sy-subrc NE 0 AND iv_auto_transport = abap_true.

      transport_request_system( EXPORTING iv_order = ev_order_created
                                          iv_system = iv_system
                                CHANGING ct_return = et_return ).

    ENDIF.

  ENDMETHOD.


  METHOD fill_selections_orders.

    CLEAR rt_selections.

    IF iv_type_workbench = abap_true.
      rt_selections-reqfunctions(1)     = sctsc_type_workbench.
    ENDIF.
    IF iv_type_customizing = abap_true.
      rt_selections-reqfunctions+1(1)   = sctsc_type_customizing.
    ENDIF.
    IF iv_type_transport = abap_true.
      rt_selections-reqfunctions+2(1)   = sctsc_type_transport.
    ENDIF.

* Types of assigned tasks
    rt_selections-taskfunctions      = sctsc_types_tasks.

* Status para ordenes modificables
    IF iv_status_modif = abap_true.
      rt_selections-taskstatus(1)     = sctsc_state_protected.
      rt_selections-taskstatus+1(1)   = sctsc_state_changeable.
    ENDIF.

* Status para ordenes liberadas
    IF iv_status_rele = abap_true.
      rt_selections-taskstatus+2(1)   = sctsc_state_released.
      rt_selections-taskstatus+3(1)   = sctsc_state_notconfirmed.
    ENDIF.

    IF iv_status_modif = abap_true AND iv_status_rele = abap_false.
      rt_selections-reqstatus(1)   = sctsc_state_protected.
      rt_selections-reqstatus+1(1) = sctsc_state_changeable.
*    r_selections-reqstatus+2(1) = sctsc_state_export_started.
    ELSEIF iv_status_modif = abap_false AND iv_status_rele = abap_true.
      rt_selections-reqstatus(1)   = sctsc_state_released.
      rt_selections-reqstatus+1(1) = sctsc_state_export_started.
    ELSEIF iv_status_modif = abap_true AND iv_status_rele = abap_true.
      rt_selections-reqstatus      = sctsc_states_all.
    ENDIF.


  ENDMETHOD.


  METHOD get_system_transport.

    DATA ld_version TYPE tcevers-version.

    CLEAR rt_system.

* Version activa del sistema de transporte
    CALL FUNCTION 'TR_GET_CONFIG_VERSION'
      IMPORTING
        ev_active_version       = ld_version
      EXCEPTIONS
        no_active_version_found = 1.

    IF sy-subrc = 0.
      SELECT sysname AS system_name ddtext AS system_desc INTO TABLE rt_system
              FROM  tcesystt
               WHERE version = ld_version
               AND   spras  = mv_langu.

    ENDIF.
  ENDMETHOD.


  METHOD get_user_orders.
    FIELD-SYMBOLS <ls_request> TYPE LINE OF trwbo_request_headers.
    FIELD-SYMBOLS <ls_request_son> TYPE LINE OF trwbo_request_headers.
    FIELD-SYMBOLS <ls_dd07v> TYPE LINE OF dd07v_tab.
    DATA ls_selection TYPE trwbo_selection.
    DATA lt_request TYPE trwbo_request_headers.
    DATA lt_functions_txt TYPE dd07v_tab.
    DATA lt_status_txt TYPE dd07v_tab.
    DATA lt_tasks TYPE ztrans_i_order_tasks.
    DATA ls_tasks TYPE LINE OF ztrans_i_order_tasks.
    DATA ls_orders TYPE LINE OF ztrans_i_userorders.

    CLEAR et_userorders.

* Relleno de los datos de seleccion
    ls_selection = fill_selections_orders( ).

* Carga de los textos
    CALL METHOD load_domain_texts
      IMPORTING
        et_functions = lt_functions_txt
        et_status    = lt_status_txt.


* Lectura de las ordenes
    CALL FUNCTION 'TRINT_SELECT_REQUESTS'
      EXPORTING
        iv_username_pattern  = iv_username
        is_selection         = ls_selection
        iv_complete_projects = 'X'
      IMPORTING
        et_requests          = lt_request.

* Leo las ordenes padre.
    LOOP AT lt_request ASSIGNING <ls_request> WHERE strkorr IS INITIAL.

      CLEAR ls_orders.
      ls_orders-order = <ls_request>-trkorr.
      ls_orders-user = <ls_request>-as4user.
      ls_orders-description = <ls_request>-as4text.
      ls_orders-type = <ls_request>-trfunction.
      READ TABLE lt_functions_txt ASSIGNING <ls_dd07v> WITH KEY domvalue_l = <ls_request>-trfunction.
      IF sy-subrc = 0.
        ls_orders-type_desc = <ls_dd07v>-ddtext.
      ENDIF.

* Busco las ordenes hijo de la orden.
      LOOP AT lt_request ASSIGNING <ls_request_son> WHERE strkorr = <ls_request>-trkorr.

        ls_tasks-order = <ls_request_son>-trkorr.
        ls_tasks-user = <ls_request_son>-as4user.
        CASE  <ls_request_son>-trstatus.
          WHEN sctsc_state_protected OR sctsc_state_changeable.
            ls_tasks-status = sctsc_state_changeable.
          WHEN sctsc_state_released OR sctsc_state_export_started.
            ls_tasks-status = sctsc_state_released.
        ENDCASE.
        READ TABLE lt_status_txt ASSIGNING <ls_dd07v> WITH KEY domvalue_l = ls_tasks-status.
        IF sy-subrc = 0.
          ls_tasks-status_desc = <ls_dd07v>-ddtext.
        ENDIF.
        INSERT ls_tasks INTO TABLE ls_orders-tasks.
      ENDLOOP.

* Añado la orden padre con sus subtareas
      INSERT ls_orders INTO TABLE et_userorders.

    ENDLOOP.


  ENDMETHOD.


  METHOD load_domain_texts.
    DATA lt_functions_n TYPE dd07v_tab.
    DATA lt_status_n TYPE dd07v_tab.

    CLEAR: et_functions, et_status.


* Textos de tipo de orden
    IF et_functions IS SUPPLIED.
      CALL FUNCTION 'DD_DOMA_GET'
        EXPORTING
          domain_name   = 'TRFUNCTION'
          langu         = mv_langu
        TABLES
          dd07v_tab_a   = et_functions
          dd07v_tab_n   = lt_functions_n
        EXCEPTIONS
          illegal_value = 1
          op_failure    = 2
          OTHERS        = 3.
    ENDIF.

* Textos de status
    IF et_status IS SUPPLIED.
      CALL FUNCTION 'DD_DOMA_GET'
        EXPORTING
          domain_name   = 'TRSTATUS'
          langu         = mv_langu
        TABLES
          dd07v_tab_a   = et_status
          dd07v_tab_n   = lt_status_n
        EXCEPTIONS
          illegal_value = 1
          op_failure    = 2
          OTHERS        = 3.
    ENDIF.

  ENDMETHOD.


  METHOD transport_request_system.
    FIELD-SYMBOLS <ls_system> TYPE tmscsys.
    FIELD-SYMBOLS <ls_requests> TYPE LINE OF tmsiqreqs.
    FIELD-SYMBOLS <ls_tp_import> TYPE LINE OF stms_tp_imports.
    FIELD-SYMBOLS <ls_buffer> TYPE tmsbuffer.
    DATA lt_domain TYPE STANDARD TABLE OF tmscdom.
    DATA lt_system TYPE STANDARD TABLE OF tmscsys.
    DATA lt_group TYPE STANDARD TABLE OF tmscnfs.
    DATA lt_requests TYPE tmsiqreqs.
    DATA lt_buffer TYPE STANDARD TABLE OF tmsbuffer.
    DATA ls_return TYPE bapiret2.
    DATA lt_tp_import TYPE stms_tp_imports.
    DATA lv_tp_ret_code TYPE stpa-retcode.
    DATA ls_exception TYPE stmscalert.
    DATA lv_tp_alog TYPE stpa-file.
    DATA lv_tp_slog TYPE stpa-file.
    DATA lv_tp_pid TYPE stpa-pid.
    DATA lv_tpstat_key TYPE tmstpkey.

*    CLEAR ct_return.

    CALL FUNCTION 'TMS_CFG_READ_CONFIGURATION'
      EXPORTING
        iv_plus_cluster     = abap_true
        iv_plus_nonabap     = abap_true
        iv_plus_virtual     = abap_true
        iv_only_active      = abap_true
        iv_check_dual_stack = abap_true
      TABLES
        tt_dom              = lt_domain
        tt_sys              = lt_system
        tt_nfs              = lt_group
      EXCEPTIONS
        OTHERS              = 99.

    IF sy-subrc = 0.

      READ TABLE lt_system ASSIGNING <ls_system> WITH KEY sysnam = iv_system.
      IF sy-subrc = 0.

        " Leemos las ordenes de la cola. Si la orden no esta, nos esperamos y volvemos a leer.
        DO 10 TIMES.

          CALL FUNCTION 'TMS_MGR_GREP_TRANSPORT_QUEUE'
            EXPORTING
              iv_system        = <ls_system>-sysnam
              iv_domain        = <ls_system>-domnam
              iv_request       = iv_order
*             iv_tarcli        = lv_client
              iv_refresh_queue = abap_true
*             iv_full_queue    = abap_true
*             iv_completed_requests = abap_true
              iv_monitor       = abap_true
              iv_verbose       = abap_false
            TABLES
              tt_buffer        = lt_buffer
            EXCEPTIONS
              OTHERS           = 99.

*          CLEAR lt_requests.
*          CALL FUNCTION 'TMS_UIQ_IQD_READ_QUEUE'
*            EXPORTING
*              iv_system         = <ls_system>-sysnam
*              iv_domain         = <ls_system>-domnam
*              iv_collect        = abap_true
*              iv_read_shadow    = abap_true
*              iv_monitor        = abap_true
*              iv_verbose        = abap_false
*            IMPORTING
*              et_requests       = lt_requests
*            EXCEPTIONS
*              read_queue_failed = 1
*              OTHERS            = 99.

*          READ TABLE lt_requests ASSIGNING <ls_requests> WITH KEY trkorr = iv_order.
          READ TABLE lt_buffer ASSIGNING <ls_buffer> WITH KEY trkorr = iv_order.
          IF sy-subrc = 0.
            EXIT.
          ELSE.
            WAIT UP TO 2 SECONDS.
          ENDIF.

        ENDDO.

        " Si el puntero existe es que se ha encontrado la orden y se procede a transportar
        IF <ls_buffer> IS ASSIGNED .

          CALL FUNCTION 'ZCA_TRANS_IMPORT_REQUEST' DESTINATION 'GPI_STMS'
            EXPORTING
              iv_system      = <ls_system>-sysnam
              iv_domain      = <ls_system>-domnam
              iv_request     = iv_order
              iv_subset      = abap_true
              iv_offline     = abap_true
              iv_monitor     = abap_true
              iv_verbose     = abap_false
            IMPORTING
              ev_tp_ret_code = lv_tp_ret_code
              ev_tp_alog     = lv_tp_alog
              ev_tp_slog     = lv_tp_slog
              ev_tp_pid      = lv_tp_pid
              ev_tpstat_key  = lv_tpstat_key
              es_exception   = ls_exception
            EXCEPTIONS
              OTHERS         = 99.
          IF sy-subrc NE 0.
            ls_return = zcl_trans_utilidades=>fill_return( iv_type = 'E'
                                            iv_id = ls_exception-msgid
                                            iv_number = sy-msgno
                                            iv_message_v1 = sy-msgv1
                                            iv_message_v2 = sy-msgv2
                                            iv_message_v3 = sy-msgv3
                                            iv_message_v4 = sy-msgv4
                                            iv_langu      = mv_langu ).
            INSERT ls_return INTO TABLE ct_return.

          ELSE.
* Si hay un OK (el lv_tp_ret_code vale 0004) o inicial (el lv_tp_ret_code vale 0000) se rellena un mensaje que ha ido todo bien. En caso contrario se monta el mensaje de error que pueda venir
            IF ls_exception-error = 'OK' OR ls_exception-error IS INITIAL.
              ls_return = zcl_trans_utilidades=>fill_return( iv_type = cv_msg_type_success
                                                         iv_id = cv_msag
                                                         iv_number = '003' " Orden transportada sin problema
                                                         iv_message_v1 = iv_order
                                                         iv_message_v2 = iv_system
                                                         iv_langu      = mv_langu ).
              INSERT ls_return INTO TABLE ct_return.
            ELSE.
              ls_return = zcl_trans_utilidades=>fill_return( iv_type = 'E'
                                         iv_id = ls_exception-msgid
                                         iv_number = ls_exception-msgno
                                         iv_message_v1 = ls_exception-msgv1
                                         iv_message_v2 = ls_exception-msgv2
                                         iv_message_v3 = ls_exception-msgv3
                                         iv_message_v4 = ls_exception-msgv4
                                         iv_langu      = mv_langu ).
              INSERT ls_return INTO TABLE ct_return.

            ENDIF.
          ENDIF.

        ELSE.
          ls_return = zcl_trans_utilidades=>fill_return( iv_type = cv_msg_type_success
                                                     iv_id = cv_msag
                                                     iv_number = '002' " Orden no encontrada en la cola
                                                     iv_message_v1 = iv_order
                                                     iv_message_v2 = iv_system
                                                     iv_langu      = mv_langu ).
          INSERT ls_return INTO TABLE ct_return.
        ENDIF.

      ELSE.
        " Actualmente el sistema siempre existira porque la aplicación UI5 envia los systemas configurads en SAP
      ENDIF.

    ENDIF.

  ENDMETHOD.
ENDCLASS.
