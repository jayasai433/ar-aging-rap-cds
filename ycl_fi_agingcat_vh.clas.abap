CLASS ycl_fi_agingcat_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.

ENDCLASS.


CLASS ycl_fi_agingcat_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.

    TYPES:
      BEGIN OF ty_result,
        agingcategory     TYPE char10,
        agingcategorytext TYPE char40,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    " Order matches the business sequence (Ondue first, then ascending buckets),
    " not alphabetical - intentional, since Fiori Elements dropdowns preserve
    " the order returned here unless the user sorts manually.
    DATA(lt_data) = VALUE tt_result(
      ( agingcategory = 'Ondue'    agingcategorytext = 'Not Yet Due' )
      ( agingcategory = '1-30'     agingcategorytext = '1-30 Days' )
      ( agingcategory = '31-60'    agingcategorytext = '31-60 Days' )
      ( agingcategory = '61-90'    agingcategorytext = '61-90 Days' )
      ( agingcategory = '91-120'   agingcategorytext = '91-120 Days' )
      ( agingcategory = '121-180'  agingcategorytext = '121-180 Days' )
      ( agingcategory = '181-365'  agingcategorytext = '181-365 Days' )
      ( agingcategory = '>365'     agingcategorytext = 'Over 365 Days' )
    ).

    " FIXED: io_response is a separate SELECT method parameter, not reached
    " via io_request->get_response() - that method does not exist on
    " if_rap_query_request. Confirmed against SAP's own official ADT tutorial
    " (developers.sap.com) and multiple independent real examples.
    IF io_request->is_data_requested( ).
      io_request->get_paging( ).
      io_request->get_sort_elements( ).

      io_response->set_total_number_of_records(
        value = lines( lt_data ) ).
      io_response->set_data( lt_data ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
