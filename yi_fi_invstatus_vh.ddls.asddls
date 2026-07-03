@EndUserText.label: 'AR Aging - Invoice Status Value Help'
@ObjectModel.query.implementedBy: 'ABAP:YCL_FI_INVSTATUS_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity YI_FI_INVSTATUS_VH
{
  key InvoiceStatus     : abap.char(20);
      InvoiceStatusText  : abap.char(40);
}
