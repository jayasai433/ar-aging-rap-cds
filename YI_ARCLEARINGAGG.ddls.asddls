@AbapCatalog.sqlViewName: 'YIARCLRAGG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Clearing History Aggregate (Interface)'
@VDM.viewType: #BASIC
define view entity YI_ARCLEARINGAGG
  as select from I_OplAcctgDocItemClrgHist as Clr

{
  key Clr.CompanyCode,
  key Clr.FiscalYear,
  key Clr.AccountingDocument,
  key Clr.AccountingDocumentItem,

      // Sum of cleared/paid amounts across all clearing line items
      // belonging to this invoice item. Kept as the ONLY aggregate
      // expression in the stack - nothing downstream re-aggregates it.
      sum(Clr.AmountInTransactionCurrency) as PaidAmount

}
group by
  Clr.CompanyCode,
  Clr.FiscalYear,
  Clr.AccountingDocument,
  Clr.AccountingDocumentItem
