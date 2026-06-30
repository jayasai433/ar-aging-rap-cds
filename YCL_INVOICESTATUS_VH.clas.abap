CLASS ycl_invoicestatus_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS ycl_invoicestatus_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    TYPES:
      BEGIN OF ty_result,
        invoicestatus     TYPE char20,
        invoicestatustext TYPE char40,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    DATA(lt_data) = VALUE tt_result(
      ( invoicestatus = 'Open'            invoicestatustext = 'Open' )
      ( invoicestatus = 'Partially Paid'  invoicestatustext = 'Partially Paid' )
      ( invoicestatus = 'Cleared'         invoicestatustext = 'Cleared' )
    ).

    " Fixed value list - paging/sorting are accepted but not meaningfully
    " applicable to a 3-row static set. Calls below are still made to avoid
    " the "GET_SORT_ELEMENTS / GET_PAGING not called" backend error reported
    " for custom entity value helps in RAP.
    IF io_request->is_data_requested( ).
      io_request->get_paging( ).
      io_request->get_sort_elements( ).

      io_request->get_response( )->set_total_number_of_records(
        value = lines( lt_data ) ).
      io_request->get_response( )->set_data( lt_data ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
