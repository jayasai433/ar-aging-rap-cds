@AbapCatalog.sqlViewName: 'YIARCLRAGG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Clearing History Aggregate'
@VDM.viewType: #BASIC
define view entity YI_FI_ARCLRAGG
  as select from I_OplAcctgDocItemClrgHist as Clr
  // Field names below CONFIRMED from the person's real ADT screen (photo,
  // 2026-07-03). Grouping is on the "Cleared*" fields, which point back to
  // the ORIGINAL invoice item being paid off - not the "Clearing*" fields,
  // which describe the clearing document itself.

{
  key Clr.ClearedCompanyCode,
  key Clr.ClearedFiscalYear,
  key Clr.ClearedAccountingDocument,
  key Clr.ClearedAccountingDocumentItem,

      sum( Clr.AmountInCompanyCodeCurrency ) as PaidAmount

}
where
  // Filter added per the person's direct confirmation in ADT that FinancialAccountType
  // exists on this view (not independently verified by me against a screenshot).
  // Scopes the aggregation to customer-only clearing rows before the join to
  // YI_FI_AROPITEM, avoiding unnecessary aggregation of vendor/GL/asset clearing rows.
  Clr.FinancialAccountType = 'D'
group by
  Clr.ClearedCompanyCode,
  Clr.ClearedFiscalYear,
  Clr.ClearedAccountingDocument,
  Clr.ClearedAccountingDocumentItem
