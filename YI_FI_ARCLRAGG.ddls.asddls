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
  // which describe the clearing document itself. This was a real bug in the
  // earlier draft, which incorrectly grouped by CompanyCode/AccountingDocument/
  // FiscalYear/AccountingDocumentItem - none of which exist under those exact
  // names on this view.

{
  key Clr.ClearedCompanyCode,
  key Clr.ClearedFiscalYear,
  key Clr.ClearedAccountingDocument,
  key Clr.ClearedAccountingDocumentItem,

      sum( Clr.AmountInCompanyCodeCurrency ) as PaidAmount

}
group by
  Clr.ClearedCompanyCode,
  Clr.ClearedFiscalYear,
  Clr.ClearedAccountingDocument,
  Clr.ClearedAccountingDocumentItem
