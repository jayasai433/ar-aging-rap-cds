@AbapCatalog.sqlViewName: 'YIARCLRAGG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Clearing History Aggregate (Interface)'
@VDM.viewType: #BASIC
define view entity YI_ARCLEARINGAGG
  as select from I_OplAcctgDocItemClrgHist as Clr
  // CONFIRMED real view, cardinality [0..*] from source item - verified
  // against the person's own published Custom CDS View Data Sources list.

{
  key Clr.CompanyCode,
  key Clr.FiscalYear,
  key Clr.AccountingDocument,
  key Clr.AccountingDocumentItem,

      // CONFIRMED field name - AmountInCompanyCodeCurrency, was
      // AmountInTransactionCurrency in the earlier unverified draft.
      sum(Clr.AmountInCompanyCodeCurrency) as PaidAmount

}
group by
  Clr.CompanyCode,
  Clr.FiscalYear,
  Clr.AccountingDocument,
  Clr.AccountingDocumentItem
