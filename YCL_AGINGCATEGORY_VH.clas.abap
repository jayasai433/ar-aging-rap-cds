CLASS ycl_agingcategory_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS ycl_agingcategory_vh IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    IF io_request->get_entity_id( ) NE 'YI_AGINGCATEGORY_VH'.
      RAISE EXCEPTION TYPE cx_a4c_rap_query_provider.
    ELSE.
      DATA aging_category TYPE STANDARD TABLE OF yi_agingcategory_vh.

      aging_category = VALUE #(
        ( AgingCategory = 'Ondue'    AgingCategoryText = 'Not Yet Due' )
        ( AgingCategory = '1-30'     AgingCategoryText = '1-30 Days' )
        ( AgingCategory = '31-60'    AgingCategoryText = '31-60 Days' )
        ( AgingCategory = '61-90'    AgingCategoryText = '61-90 Days' )
        ( AgingCategory = '91-120'   AgingCategoryText = '91-120 Days' )
        ( AgingCategory = '121-180'  AgingCategoryText = '121-180 Days' )
        ( AgingCategory = '181-365'  AgingCategoryText = '181-365 Days' )
        ( AgingCategory = '>365'     AgingCategoryText = 'Over 365 Days' )
      ).

      " Process number of records if requested
      IF io_request->is_total_numb_of_rec_requested( ).
        io_response->set_total_number_of_records( lines( aging_category ) ).
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
        SORT aging_category BY (sort_order).

        " Handle paging (mandatory step)
        DATA(paging) = io_request->get_paging( ).

        IF paging->get_offset( ) > 0.
          DELETE aging_category TO paging->get_offset( ).
        ENDIF.
        IF paging->get_page_size( ) > 0.
          DELETE aging_category FROM paging->get_page_size( ) + 1.
        ENDIF.

        " Return data
        io_response->set_data( aging_category ).

      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
