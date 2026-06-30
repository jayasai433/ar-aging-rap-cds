@AbapCatalog.sqlViewName: 'YIARAGING'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Remaining Amount and Due Dates (Interface)'
@VDM.viewType: #COMPOSITE
define view entity YI_ARAGING
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    P_KeyDate : abap.dats

  as select from YI_AROPITEM as Item

  // NOTE: association name/target unverified - confirm the released CDS view
  // that exposes net payment days for a given payment terms code before activation.
  // Candidates to check in ADT: I_PaymentTerms / I_PaymentTermsText / similar.
  association [0..1] to I_PaymentTerms                      as _PaymentTerms
    on $projection.PaymentTermsCode = _PaymentTerms.PaymentTerms

{
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.AccountingDocumentItem,
  key Item.CompanyCode,

      Item.FiscalYearNum,
      Item.CompanyCode          as CompanyCodeOut,         // avoid name clash, kept for downstream readability
      Item.CompanyBranch,
      Item.CustomerCode,
      Item.GLAccount,
      Item.DocumentType,
      Item.JournalEntry,
      Item.InvoiceReference,
      Item.BillingNumber,
      Item.WBSElementInternalID,

      Item.InvoiceAmount,
      Item.TransactionCurrency,
      Item.PaymentTermsCode,

      // Paid Amount surfaced from the isolated aggregate - flat column, safe to use below
      coalesce( Item._ClearingAgg.PaidAmount, 0 ) as PaidAmount,

      // Remaining Amount - single arithmetic expression, no nested aggregate
      Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) as RemainingAmount,

      Item.PostingDate,
      Item.BaselineDate,
      Item.ClearingDate,
      // Item.ActualBillingDate,   // uncomment once custom field name confirmed

      // ---- Net payment days from payment terms lookup ----
      // Field name NetPaymentDays is a placeholder pending confirmation of I_PaymentTerms element name.
      _PaymentTerms.NetPaymentDays as NetPaymentDays,

      // ---- Due Date - Invoice Date basis ----
      dats_add_days(
        Item.BaselineDate,
        cast( _PaymentTerms.NetPaymentDays as abap.int4 ),
        'INITIAL'
      ) as DueDateByInvoice,

      // ---- Due Date - Actual Billing Date basis ----
      // Placeholder uses BaselineDate until ActualBillingDate field is confirmed and uncommented above.
      dats_add_days(
        Item.BaselineDate,
        cast( _PaymentTerms.NetPaymentDays as abap.int4 ),
        'INITIAL'
      ) as DueDateByBilling,

      $parameters.P_KeyDate as KeyDateOut,

      // ---- Effective "as-of" date per basis: frozen at clearing date once fully paid ----
      case
        when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
          then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
        else $parameters.P_KeyDate
      end as EffectiveAgingDate,

      // ---- Aging Days, flat columns, computed once here ----
      dats_days_between(
        dats_add_days( Item.BaselineDate, cast( _PaymentTerms.NetPaymentDays as abap.int4 ), 'INITIAL' ),
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      ) as AgingDaysInvoice,

      // NOTE: placeholder - duplicates AgingDaysInvoice's due-date expression until
      // DueDateByBilling is wired to the real ActualBillingDate field (see comment above).
      // Replace this DATS_ADD_DAYS argument with the billing-date version once confirmed.
      dats_days_between(
        dats_add_days( Item.BaselineDate, cast( _PaymentTerms.NetPaymentDays as abap.int4 ), 'INITIAL' ),
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      ) as AgingDaysBilling,

      Item._Customer,
      Item._CustomerCompany,
      Item._BusinessPlace,
      Item._GLAccountText,
      Item._WBSElement,
      Item._SalesPartnerFunction,
      _PaymentTerms
}
