CLASS zcl_trans_utilidades DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

*"* public components of class ZCL_TRANS_UTILIDADES
*"* do not include other source files here!!!
    CLASS-METHODS conv_fecha_json_2_abap
      IMPORTING
        !iv_fecha_json       TYPE bsstring
      RETURNING
        VALUE(rv_fecha_abap) TYPE sydatum .
    CLASS-METHODS conv_json_2_abap
      IMPORTING
        !iv_json TYPE string
      EXPORTING
        !ev_abap TYPE any .
    CLASS-METHODS conv_abap_2_json
      IMPORTING
        !iv_abap       TYPE any
      RETURNING
        VALUE(rv_json) TYPE xstring .
    CLASS-METHODS fill_return
      IMPORTING
        !iv_type         TYPE any
        !iv_id           TYPE any
        !iv_number       TYPE any
        !iv_message_v1   TYPE any OPTIONAL
        !iv_message_v2   TYPE any OPTIONAL
        !iv_message_v3   TYPE any OPTIONAL
        !iv_message_v4   TYPE any OPTIONAL
        !iv_langu        TYPE sylangu DEFAULT sy-langu
        !iv_row          TYPE any OPTIONAL
      RETURNING
        VALUE(rs_return) TYPE bapiret2 .
    CLASS-METHODS iso_2_idioma
      IMPORTING
        !iv_laiso       TYPE any
      RETURNING
        VALUE(rv_langu) TYPE sy-langu .
    CLASS-METHODS idioma_2_iso
      IMPORTING
        !iv_lang        TYPE sylangu OPTIONAL
      RETURNING
        VALUE(rv_laiso) TYPE laiso .
    CLASS-METHODS ajustar_json
      CHANGING
        !cv_json TYPE xstring .
    CLASS-METHODS conv_fecha_abap_2_json
      IMPORTING
        !iv_fecha_abap       TYPE sydatum
      RETURNING
        VALUE(rv_fecha_json) TYPE bsstring .
  PROTECTED SECTION.
*"* protected components of class ZCL_TRANS_UTILIDADES
*"* do not include other source files here!!!
  PRIVATE SECTION.
*"* private components of class ZCL_TRANS_UTILIDADES
*"* do not include other source files here!!!
ENDCLASS.



CLASS zcl_trans_utilidades IMPLEMENTATION.


  METHOD ajustar_json.
    DATA ld_json TYPE string.

    CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING'
      EXPORTING
        im_xstring = cv_json
      IMPORTING
        ex_string  = ld_json.


* Reemplazo los literales "true"/"false" por true/false. De esta manera pasan a ser booleanos
    REPLACE ALL OCCURRENCES OF '"true"' IN ld_json WITH 'true'.
    REPLACE ALL OCCURRENCES OF '"false"' IN ld_json WITH 'false'.


    CALL FUNCTION 'ECATT_CONV_STRING_TO_XSTRING'
      EXPORTING
        im_string  = ld_json
      IMPORTING
        ex_xstring = cv_json.

  ENDMETHOD.


  METHOD conv_abap_2_json.
    DATA lo_json_writer TYPE REF TO cl_sxml_string_writer.

    lo_json_writer = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
    CALL TRANSFORMATION id SOURCE data = iv_abap RESULT XML lo_json_writer.
    rv_json = lo_json_writer->get_output( ).

* Ajusto el JSON para adaptar ciertas cosas
    ajustar_json( CHANGING cv_json =  rv_json ).


  ENDMETHOD.


  METHOD conv_fecha_abap_2_json.
    CLEAR rv_fecha_json.

    rv_fecha_json = iv_fecha_abap(4) && '-' && iv_fecha_abap+4(2) && '-' && iv_fecha_abap+6(2) && 'T00:00:00.000Z'.

  ENDMETHOD.


  METHOD conv_fecha_json_2_abap.

    CLEAR rv_fecha_abap.

    rv_fecha_abap = iv_fecha_json(4) && iv_fecha_json+5(2) && iv_fecha_json+8(2).

  ENDMETHOD.


  METHOD conv_json_2_abap.
    DATA ld_xjson TYPE xstring.
    DATA lo_json_reader TYPE REF TO if_sxml_reader.

    CALL FUNCTION 'ECATT_CONV_STRING_TO_XSTRING'
      EXPORTING
        im_string   = iv_json
        im_encoding = 'UTF-8'
      IMPORTING
        ex_xstring  = ld_xjson.

    lo_json_reader = cl_sxml_string_reader=>create( input = ld_xjson ).

    CALL TRANSFORMATION id SOURCE XML lo_json_reader
                           RESULT data = ev_abap.
  ENDMETHOD.


  METHOD fill_return.
    CLEAR rs_return.

    rs_return-type = iv_type.
    rs_return-id = iv_id.
    rs_return-number = iv_number.
    rs_return-message_v1 = iv_message_v1.
    rs_return-message_v2 = iv_message_v2.
    rs_return-message_v3 = iv_message_v3.
    rs_return-message_v4 = iv_message_v4.
    rs_return-row = iv_row.

    CALL FUNCTION 'BAPI_MESSAGE_GETDETAIL'
      EXPORTING
        id         = rs_return-id
        number     = rs_return-number
        language   = iv_langu
        textformat = 'ASC'
        message_v1 = rs_return-message_v1
        message_v2 = rs_return-message_v2
        message_v3 = rs_return-message_v3
        message_v4 = rs_return-message_v4
      IMPORTING
        message    = rs_return-message.
  ENDMETHOD.


  METHOD idioma_2_iso.
    DATA ld_lang TYPE sylangu.

    IF iv_lang IS INITIAL.
      ld_lang = sy-langu.
    ELSE.
      ld_lang = iv_lang.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
      EXPORTING
        input            = ld_lang
      IMPORTING
        output           = rv_laiso
      EXCEPTIONS
        unknown_language = 1
        OTHERS           = 2.

  ENDMETHOD.


  METHOD iso_2_idioma.
    IF iv_laiso IS INITIAL.
      rv_langu = sy-langu.
    ELSE.

      CALL FUNCTION 'CONVERSION_EXIT_ISOLA_INPUT'
        EXPORTING
          input            = iv_laiso
        IMPORTING
          output           = rv_langu
        EXCEPTIONS
          unknown_language = 1
          OTHERS           = 2.
      IF sy-subrc NE 0.
        rv_langu = sy-langu.
      ENDIF.

    ENDIF.
  ENDMETHOD.
ENDCLASS.
