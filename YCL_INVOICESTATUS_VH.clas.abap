CLASS ycl_invoicestatus_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS ycl_invoicestatus_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    IF io_request->get_entity_id( ) NE 'YI_INVOICESTATUS_VH'.
      RAISE EXCEPTION TYPE cx_a4c_rap_query_provider.
    ELSE.
      DATA invoice_status TYPE STANDARD TABLE OF yi_invoicestatus_vh.

      invoice_status = VALUE #(
        ( InvoiceStatus = 'Open'           InvoiceStatusText = 'Open' )
        ( InvoiceStatus = 'Partially Paid' InvoiceStatusText = 'Partially Paid' )
        ( InvoiceStatus = 'Cleared'        InvoiceStatusText = 'Cleared' )
      ).

      " Process number of records if requested
      IF io_request->is_total_numb_of_rec_requested( ).
        io_response->set_total_number_of_records( lines( invoice_status ) ).
      ENDIF.

      " Process data if requested
      IF io_request->is_data_requested( ).

        " Handle sorting (mandatory step)
        DATA(sorting) = io_request->get_sort_elements( ).
        DATA(sort_order) = VALUE abap_sortorder_tab(
          FOR sort IN sorting (
            name       = sort-element_name
            descending = sort-descending
          )
        ).
        SORT invoice_status BY (sort_order).

        " Handle paging (mandatory step)
        DATA(paging) = io_request->get_paging( ).

        IF paging->get_offset( ) > 0.
          DELETE invoice_status TO paging->get_offset( ).
        ENDIF.
        IF paging->get_page_size( ) > 0.
          DELETE invoice_status FROM paging->get_page_size( ) + 1.
        ENDIF.

        " Return data
        io_response->set_data( invoice_status ).

      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
