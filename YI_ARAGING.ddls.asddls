@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Remaining Amount and Due Dates (Interface)'
@VDM.viewType: #COMPOSITE
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #L
@ObjectModel.usageType.dataClass: #MIXED
define view entity YI_ARAGING
  with parameters
    @Environment.systemField: #SYSTEM_DATE
    P_KeyDate : abap.dats
  as select from YI_AROPITEM as Item
  association [0..1] to I_PaymentTerms as _PaymentTerms
    on $projection.PaymentTermsCode = _PaymentTerms.PaymentTerms
{
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.AccountingDocumentItem,
  key Item.CompanyCode,

      Item.FiscalYearNum,
      Item.CompanyCode                                    as CompanyCodeOut,
      Item.CompanyName,
      Item.CompanyBranch,
      Item.CustomerCode,
      Item.CustomerName,
      Item.CustomerBranch,
      Item.BPGroupCode,
      Item.BPGroupName,
      Item.GLAccount,
      Item.GLAccountName,
      Item.DocumentType,
      Item.JournalEntry,
      Item.InvoiceReference,
      Item.BillingNumber,
      Item.InvoiceDescription,
      Item.WBSElementInternalID,
      Item.ProjectName,
      Item.SalesName,

      Item.InvoiceAmount,
      Item.TransactionCurrency,
      Item.PaymentTermsCode,

      coalesce( Item._ClearingAgg.PaidAmount, 0 )        as PaidAmount,

      Item.InvoiceAmount
        - coalesce( Item._ClearingAgg.PaidAmount, 0 )    as RemainingAmount,

      Item.InvoiceDate,
      Item.PostingDate,
      Item.BaselineDate,
      Item.ClearingDate,

      _PaymentTerms.NetPaymentDays                        as NetPaymentDays,
      _PaymentTerms.PaymentTermsName                      as PaymentTermsText,

      dats_add_days(
        Item.BaselineDate,
        cast( _PaymentTerms.NetPaymentDays as abap.int4 ),
        'INITIAL'
      )                                                   as DueDateByInvoice,

      dats_add_days(
        Item.BaselineDate,
        cast( _PaymentTerms.NetPaymentDays as abap.int4 ),
        'INITIAL'
      )                                                   as DueDateByBilling,

      $parameters.P_KeyDate                               as KeyDateOut,

      case
        when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
          then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
        else $parameters.P_KeyDate
      end                                                 as EffectiveAgingDate,

      dats_days_between(
        dats_add_days(
          Item.BaselineDate,
          cast( _PaymentTerms.NetPaymentDays as abap.int4 ),
          'INITIAL'
        ),
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      )                                                   as AgingDaysInvoice,

      dats_days_between(
        dats_add_days(
          Item.BaselineDate,
          cast( _PaymentTerms.NetPaymentDays as abap.int4 ),
          'INITIAL'
        ),
        case
          when ( Item.InvoiceAmount - coalesce( Item._ClearingAgg.PaidAmount, 0 ) ) = 0
            then coalesce( Item.ClearingDate, $parameters.P_KeyDate )
          else $parameters.P_KeyDate
        end
      )                                                   as AgingDaysBilling,

      Item._Customer,
      Item._CustomerCompany,
      Item._BusinessPlace,
      Item._GLAccountText,
      Item._WBSElement,
      Item._SalesPartnerFunction,
      _PaymentTerms
}
