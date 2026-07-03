CLASS ycl_fi_invstatus_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS ycl_fi_invstatus_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    TYPES:
      tt_result TYPE STANDARD TABLE OF YI_FI_INVSTATUS_VH WITH EMPTY KEY.

    DATA(lt_data) = VALUE tt_result(
      ( invoicestatus = 'Open'            invoicestatustext = 'Open' )
      ( invoicestatus = 'Partially Paid'  invoicestatustext = 'Partially Paid' )
      ( invoicestatus = 'Cleared'         invoicestatustext = 'Cleared' )
    ).

    IF io_request->is_data_requested( ).
      io_request->get_paging( ).
      io_request->get_sort_elements( ).

      " Parameter name iv_total_number_of_records confirmed directly from the
      " person's own ADT (matches their real system's method signature via
      " autocomplete) - not independently re-verified by me beyond that.
      io_response->set_total_number_of_records( iv_total_number_of_records = lines( lt_data ) ).
      io_response->set_data( lt_data ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
