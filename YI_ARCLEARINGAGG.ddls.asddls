@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Clearing History Aggregate (Interface)'
@VDM.viewType: #BASIC
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #M
@ObjectModel.usageType.dataClass: #MIXED
define view entity YI_ARCLEARINGAGG
  as select from I_OplAcctgDocItemClrgHist as Clr
{
  key Clr.CompanyCode,
  key Clr.FiscalYear,
  key Clr.AccountingDocument,
  key Clr.AccountingDocumentItem,

      sum( Clr.AmountInTransactionCurrency ) as PaidAmount
}
group by
  Clr.CompanyCode,
  Clr.FiscalYear,
  Clr.AccountingDocument,
  Clr.AccountingDocumentItem
