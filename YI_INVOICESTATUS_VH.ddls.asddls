@EndUserText.label: 'AR Aging - Invoice Status Value Help'
@ObjectModel.query.implementedBy: 'ABAP:YCL_INVOICESTATUS_VH'
define custom entity YI_INVOICESTATUS_VH
{
  key InvoiceStatus     : abap.char(20);
      InvoiceStatusText  : abap.char(40);
}
