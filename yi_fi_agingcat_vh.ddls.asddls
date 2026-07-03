@EndUserText.label: 'AR Aging - Aging Category Value Help'
@ObjectModel.query.implementedBy: 'ABAP:YCL_FI_AGINGCAT_VH'
define custom entity YI_FI_AGINGCAT_VH
{
  // CORRECTED (2026-07-03) to match the person's real, live activated object -
  // confirmed via direct ADT screenshot. Field names here were previously
  // AgingCategory/AgingCategoryText (char 10/40) - the real object uses
  // InvoiceDateStatus/InvoiceDateStatusText (char 20/40) instead. I don't know
  // why this naming was chosen (possibly an intentional rename on the person's
  // side); this update simply brings our repo in line with what's actually
  // activated, not a guess.
  key InvoiceDateStatus     : abap.char(20);
      InvoiceDateStatusText : abap.char(40);
}
