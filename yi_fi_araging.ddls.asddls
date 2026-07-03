@AbapCatalog.sqlViewName: 'YIARAGING'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Remaining Amount and Due Dates (Interface)'
@VDM.viewType: #COMPOSITE
define view entity YI_FI_ARAGING
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    P_KeyDate : abap.dats

  as select from YI_FI_AROPITEM as Item

{
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.AccountingDocumentItem,
  key Item.CompanyCode,

      Item.FiscalYearNum,
      Item.CompanyCode          as CompanyCodeOut,
      Item.CompanyBranch,
      Item.BPGroupCode,
      Item.CustomerCode,
      Item.CustomerName,
      Item.CustomerBranch,
      Item.GLAccount,
      Item.GLAccountName,
      Item.DocumentType,
      Item.JournalEntry,
      Item.BillingNumber,
      Item.InvoiceDescription,
      Item.WBSElementInternalID,
      Item.ProjectName,
      Item.SalesName,

      Item.InvoiceAmount,
      Item.CompanyCodeCurrency,
      Item.PaymentTermsCode,
      Item.NetPaymentDays,

      // Paid Amount surfaced from the isolated aggregate - flat column
      coalesce( Item._ClearingAgg.PaidAmount, 0 ) as PaidAmount,

      // Remaining Amount - single arithmetic expression, no nested aggregate
      Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) as RemainingAmount,

      Item.PostingDate,
      Item.BaselineDate,
      Item.ClearingDate,
      Item.ActualBillingDate,

      $parameters.P_KeyDate as KeyDateOut,

      // ---- Effective "as-of" date: frozen at clearing date once fully paid ----
      case
        when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
          then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
        else $parameters.P_KeyDate
      end as EffectiveAgingDate,

      // ---- Due Date, Invoice basis: CONFIRMED direct field, no calculation ----
      // Verified by the person: NetDueDate = Baseline Date + NetPaymentDays, already computed by SAP.
      Item.DueDateByInvoice,

      // ---- Due Date, Actual Billing basis: genuinely needs calculation ----
      // No equivalent pre-computed field exists for the custom ActualBillingDate,
      // since it is a custom field with no standard SAP due-date derivation behind it.
      dats_add_days( Item.ActualBillingDate, cast( Item.NetPaymentDays as abap.int4 ), 'INITIAL' ) as DueDateByBilling,

      // ---- Aging Days, Invoice basis ----
      dats_days_between(
        Item.DueDateByInvoice,
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      ) as AgingDaysInvoice,

      // ---- Aging Days, Actual Billing basis ----
      dats_days_between(
        dats_add_days( Item.ActualBillingDate, cast( Item.NetPaymentDays as abap.int4 ), 'INITIAL' ),
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      ) as AgingDaysBilling,

      Item._Customer,
      Item._CustomerCompany,
      Item._BusinessPlace,
      Item._BPGroup,
      Item._WBSElement,
      Item._SalesPartnerFunction
}
