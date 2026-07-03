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

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      Item.InvoiceAmount,
      Item.CompanyCodeCurrency,
      Item.PaymentTermsCode,
      Item.NetPaymentDays,

      // Paid Amount surfaced from the isolated aggregate - flat column
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      coalesce( Item._ClearingAgg.PaidAmount, cast( 0 as abap.curr( 23, 2 ) ) ) as PaidAmount,

      // Remaining Amount - single arithmetic expression, no nested aggregate
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, cast( 0 as abap.curr( 23, 2 ) ) ) as RemainingAmount,

      Item.PostingDate,
      Item.BaselineDate,
      Item.ClearingDate,
      Item.ActualBillingDate,

      $parameters.P_KeyDate as KeyDateOut,

      // ---- Effective "as-of" date: frozen at clearing date once fully paid ----
      case
        when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, cast( 0 as abap.curr( 23, 2 ) ) ) ) = 0
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
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, cast( 0 as abap.curr( 23, 2 ) ) ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      ) as AgingDaysInvoice,

      // ---- Aging Days, Actual Billing basis ----
      dats_days_between(
        dats_add_days( Item.ActualBillingDate, cast( Item.NetPaymentDays as abap.int4 ), 'INITIAL' ),
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, cast( 0 as abap.curr( 23, 2 ) ) ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      ) as AgingDaysBilling,

      // ---- InvoiceStatus, AgingCategoryInvoice, AgingCategoryBilling, and all
      // 14 aging amount buckets ----
      // Moved UP from YC_FI_ARAGING (2026-07-03): CONFIRMED real, known SAP
      // limitation - calculated/CASE expressions are not supported directly
      // inside a Projection view (YC_FI_ARAGING uses "as projection on"),
      // even though identical logic works fine in a regular view entity like
      // this one. Source: SAP Community thread describing the identical
      // symptom ("Field XXXXXX contains a not supported expression" in a
      // projection view, same logic working in a normal view entity) -
      // I have not independently verified this is officially documented by
      // SAP beyond that community thread, but the symptom match is exact.
      // All calculated fields now live here as flat columns; YC_FI_ARAGING
      // only references them as plain passthrough fields.

      case
        when RemainingAmount = InvoiceAmount or PaidAmount = cast( 0 as abap.curr( 23, 2 ) )
          then 'Open'
        when RemainingAmount = cast( 0 as abap.curr( 23, 2 ) )
          then 'Cleared'
        else 'Partially Paid'
      end as InvoiceStatus,

      case
        when AgingDaysInvoice < 1                 then 'Ondue'
        when AgingDaysInvoice between 1   and 30  then '1-30'
        when AgingDaysInvoice between 31  and 60  then '31-60'
        when AgingDaysInvoice between 61  and 90  then '61-90'
        when AgingDaysInvoice between 91  and 120 then '91-120'
        when AgingDaysInvoice between 121 and 180 then '121-180'
        when AgingDaysInvoice between 181 and 365 then '181-365'
        else '>365'
      end as AgingCategoryInvoice,

      case
        when AgingDaysBilling < 1                 then 'Ondue'
        when AgingDaysBilling between 1   and 30  then '1-30'
        when AgingDaysBilling between 31  and 60  then '31-60'
        when AgingDaysBilling between 61  and 90  then '61-90'
        when AgingDaysBilling between 91  and 120 then '91-120'
        when AgingDaysBilling between 121 and 180 then '121-180'
        when AgingDaysBilling between 181 and 365 then '181-365'
        else '>365'
      end as AgingCategoryBilling,

      // ---- Aging amount buckets, Invoice Date basis ----
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice between 1 and 30 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInv0130,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice between 31 and 60 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInv3160,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice between 61 and 90 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInv6190,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice between 91 and 120 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInv91120,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice between 121 and 180 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInv121180,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice between 181 and 365 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInv181365,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysInvoice > 365 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtInvOver365,

      // ---- Aging amount buckets, Actual Billing Date basis ----
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling between 1 and 30 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBil0130,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling between 31 and 60 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBil3160,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling between 61 and 90 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBil6190,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling between 91 and 120 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBil91120,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling between 121 and 180 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBil121180,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling between 181 and 365 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBil181365,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      case when AgingDaysBilling > 365 then RemainingAmount else cast( 0 as abap.curr( 23, 2 ) ) end as AmtBilOver365,

      Item._Customer,
      Item._CustomerCompany,
      Item._BusinessPlace,
      Item._BPGroup,
      Item._WBSElement,
      Item._SalesPartnerFunction
}
