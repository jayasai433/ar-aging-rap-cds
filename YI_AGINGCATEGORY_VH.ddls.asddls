@EndUserText.label: 'AR Aging - Aging Category Value Help'
@ObjectModel.query.implementedBy: 'ABAP:YCL_AGINGCATEGORY_VH'
define custom entity YI_AGINGCATEGORY_VH
{
  key AgingCategory     : abap.char(10);
      AgingCategoryText  : abap.char(40);
}
