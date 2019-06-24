CLASS zcl_trans_controller_http DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_extension .
  PROTECTED SECTION.
    TYPES: BEGIN OF ts_user,
             username TYPE syuname,
           END OF ts_user.
    TYPES: BEGIN OF ts_user_info,
             username      TYPE uname,
             username_text TYPE bsstring,
           END OF ts_user_info.

    DATA          mo_server TYPE REF TO if_http_server.
    DATA mo_process TYPE REF TO zcl_trans_transports .

    METHODS get_info_user .
    METHODS get_orders .
    METHODS get_system .
    METHODS process_http .
    METHODS do_transport .
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_trans_controller_http IMPLEMENTATION.


  METHOD do_transport.

    TYPES: BEGIN OF ty_result_transport,
             order  TYPE trkorr,
             return TYPE bapiret2_t,
           END OF ty_result_transport.

    DATA ls_return_order TYPE ty_result_transport.

    DATA ls_orders TYPE ztrans_s_orders_transport.


* Recupero el usuario que se quiere recuperar los datos
    CALL METHOD zcl_trans_utilidades=>conv_json_2_abap
      EXPORTING
        iv_json = mo_server->request->get_cdata( )
      IMPORTING
        ev_abap = ls_orders.


    CALL METHOD mo_process->do_transport
      EXPORTING
        it_orders            = ls_orders-orders
        iv_system            = ls_orders-params-system
        iv_order_description = ls_orders-params-description
      IMPORTING
        et_return            = ls_return_order-return
        ev_order_created     = ls_return_order-order.


* Devuelvo el resultado
    CALL METHOD mo_server->response->set_data( data = zcl_trans_utilidades=>conv_abap_2_json( ls_return_order ) ).

  ENDMETHOD.


  METHOD get_info_user.
    DATA lt_return TYPE bapiret2_t.
    DATA: ls_address TYPE bapiaddr3.
    DATA ls_user TYPE ts_user.
    DATA ls_info TYPE ts_user_info.

* Recupero el usuario que se quiere recuperar los datos
    CALL METHOD zcl_trans_utilidades=>conv_json_2_abap
      EXPORTING
        iv_json = mo_server->request->get_cdata( )
      IMPORTING
        ev_abap = ls_user.

* Si no viene usuario pongo el de conexion
    IF ls_user-username IS INITIAL.
      ls_user-username = sy-uname.
    ENDIF.


* Información del usuario
    CALL FUNCTION 'BAPI_USER_GET_DETAIL'
      EXPORTING
        username = ls_user-username
      IMPORTING
        address  = ls_address
      TABLES
        return   = lt_return[].

    READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
    IF sy-subrc NE 0.
      ls_info-username = ls_user-username.
      ls_info-username_text = ls_address-fullname.
    ENDIF.

* Devuelvo las ordenes
    CALL METHOD mo_server->response->set_data( data = zcl_trans_utilidades=>conv_abap_2_json( ls_info ) ).

  ENDMETHOD.


  METHOD get_orders.
    TYPES: BEGIN OF ty_get_orders,
             username TYPE syuname,
           END OF ty_get_orders.
    DATA ls_get_orders TYPE ty_get_orders.

    DATA lt_userorders TYPE ztrans_i_userorders.

* Recupero el usuario que se quiere recuperar los datos
    CALL METHOD zcl_trans_utilidades=>conv_json_2_abap
      EXPORTING
        iv_json = mo_server->request->get_cdata( )
      IMPORTING
        ev_abap = ls_get_orders.

* Si no viene usuario pongo el de conexion
    IF ls_get_orders-username IS INITIAL.
      ls_get_orders-username = sy-uname.
    ENDIF.

* Paso el usuario al proceso para la recuperacion de sus ordenes
    CALL METHOD mo_process->get_user_orders
      EXPORTING
        iv_username   = ls_get_orders-username
      IMPORTING
        et_userorders = lt_userorders.

* Devuelvo las ordenes
    CALL METHOD mo_server->response->set_data( data = zcl_trans_utilidades=>conv_abap_2_json( lt_userorders ) ).

  ENDMETHOD.


  METHOD get_system.
    DATA lt_system TYPE ztrans_i_system.


    lt_system = mo_process->get_system_transport( ).

* Devuelvo las ordenes
    CALL METHOD mo_server->response->set_data( data = zcl_trans_utilidades=>conv_abap_2_json( lt_system ) ).

  ENDMETHOD.


  METHOD if_http_extension~handle_request.
    FIELD-SYMBOLS <ls_header_fields> TYPE LINE OF tihttpnvp.
    DATA ld_verb TYPE string.
    DATA ld_path_info TYPE string.
    DATA lt_header_fields TYPE tihttpnvp.
*  DATA lo_raise TYPE REF TO zcx_ms_raise.
*  DATA lo_contrl_appl TYPE REF TO zcl_ms_controller_master.


    ld_verb = server->request->get_header_field( name = '~request_method' ).
    ld_path_info = server->request->get_header_field( name = '~path_info' ).


    IF ( ld_verb NE 'GET' ) AND ( ld_verb NE 'POST' ) AND
       ( ld_verb NE 'PUT' ) AND ( ld_verb NE 'DELETE' ).

      " For any other method the service should return the error code 405
      CALL METHOD server->response->set_status(
          code   = '405'
          reason = 'Method not allowed' ).

      CALL METHOD server->response->set_header_field(
          name  = 'Allow'
          value = 'POST, GET, PUT, DELETE' ).

      EXIT.

    ENDIF.

* Recuperación de las cabeceras HTTP
    server->request->get_header_fields( CHANGING fields = lt_header_fields ).

* Se mira si viene el parametro origen. Si viene, se pasa que ese origen tiene permiso en la aplicacion.
    READ TABLE lt_header_fields ASSIGNING <ls_header_fields> WITH KEY name = 'origin'.
    IF sy-subrc EQ 0.
      server->response->set_header_field( name = 'Access-Control-Allow-Origin' value = <ls_header_fields>-value ).
    ENDIF.

* Guardo los datos HTTP para poderlos usar en cualquier momento de la clase
    mo_server = server.

* Creo el objeto que controla el proceso
    CREATE OBJECT mo_process
      EXPORTING
        iv_langu = zcl_trans_utilidades=>iso_2_idioma( mo_server->request->get_form_field( 'LANGUAGE' ) ).

* Se proceso la llamada
    process_http( ).



  ENDMETHOD.


  METHOD process_http.

    CASE mo_server->request->get_form_field('EVENT').
      WHEN 'GET_USER_INFO'. " Información del usuario
        get_info_user( ).
      WHEN 'GET_ORDERS'. " Ordenes del usuario
        get_orders( ).
      WHEN 'GET_SYSTEM'. " Sistemas de transporte
        get_system( ).
      WHEN 'DO_TRANSPORT'. " Realiza el transporte
        do_transport( ).
    ENDCASE.

  ENDMETHOD.
ENDCLASS.
