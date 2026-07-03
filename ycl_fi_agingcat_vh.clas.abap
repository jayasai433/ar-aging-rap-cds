CLASS ycl_fi_agingcat_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS ycl_fi_agingcat_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    " Field names and lengths CORRECTED (2026-07-03) to match the real, live
    " custom entity YI_FI_AGINGCAT_VH - confirmed via direct ADT screenshot.
    " Was invoicedatestatus/invoicedatestatustext -> actually
    " invoicedatestatus TYPE char20 (was char10), invoicedatestatustext
    " TYPE char40 (unchanged).
    TYPES:
      BEGIN OF ty_result,
        invoicedatestatus     TYPE char20,
        invoicedatestatustext TYPE char40,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    " Order matches the business sequence (Ondue first, then ascending buckets),
    " not alphabetical - intentional, since Fiori Elements dropdowns preserve
    " the order returned here unless the user sorts manually.
    DATA(lt_data) = VALUE tt_result(
      ( invoicedatestatus = 'Ondue'    invoicedatestatustext = 'Not Yet Due' )
      ( invoicedatestatus = '1-30'     invoicedatestatustext = '1-30 Days' )
      ( invoicedatestatus = '31-60'    invoicedatestatustext = '31-60 Days' )
      ( invoicedatestatus = '61-90'    invoicedatestatustext = '61-90 Days' )
      ( invoicedatestatus = '91-120'   invoicedatestatustext = '91-120 Days' )
      ( invoicedatestatus = '121-180'  invoicedatestatustext = '121-180 Days' )
      ( invoicedatestatus = '181-365'  invoicedatestatustext = '181-365 Days' )
      ( invoicedatestatus = '>365'     invoicedatestatustext = 'Over 365 Days' )
    ).

    IF io_request->is_data_requested( ).
      io_request->get_paging( ).
      io_request->get_sort_elements( ).

      io_response->set_total_number_of_records(
        value = lines( lt_data ) ).
      io_response->set_data( lt_data ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
