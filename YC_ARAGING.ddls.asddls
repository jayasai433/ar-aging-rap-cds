@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging Report'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #L
@ObjectModel.usageType.dataClass: #MIXED
define root view entity YC_ARAGING
  provider contract transactional_query
  as projection on YI_ARAGING
{
  key AccountingDocument,
  key FiscalYear,
  key AccountingDocumentItem,
  key CompanyCode,

      FiscalYearNum,

      CompanyCodeOut,

      CompanyName,

      CompanyBranch,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessPartnerGrouping', element: 'BusinessPartnerGrouping' } }]
      BPGroupCode,

      BPGroupName,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
      CustomerCode,

      CustomerName,

      CustomerBranch,

      GLAccount,

      GLAccountName,

      DocumentType,

      JournalEntry,

      InvoiceReference,

      InvoiceDescription,

      BillingNumber,

      WBSElementInternalID,

      ProjectName,

      SalesName,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      InvoiceAmount,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      PaidAmount,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      RemainingAmount,

      @Semantics.currencyCode: true
      TransactionCurrency,

      InvoiceDate,
      PostingDate,
      BaselineDate,
      ClearingDate,
      PaymentTermsCode,
      PaymentTermsText,
      KeyDateOut,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_INVOICESTATUS_VH', element: 'InvoiceStatus' } }]
      case
        when RemainingAmount = InvoiceAmount or PaidAmount = 0 or PaidAmount is null
          then 'Open'
        when RemainingAmount = 0
          then 'Cleared'
        else 'Partially Paid'
      end as InvoiceStatus,

      DueDateByInvoice,
      EffectiveAgingDate as EffectiveDateInvoice,
      AgingDaysInvoice,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_AGINGCATEGORY_VH', element: 'AgingCategory' }, qualifier: 'Invoice' }]
      case
        when AgingDaysInvoice < 1                 then 'Ondue'
        when AgingDaysInvoice between 1 and 30    then '1-30'
        when AgingDaysInvoice between 31 and 60   then '31-60'
        when AgingDaysInvoice between 61 and 90   then '61-90'
        when AgingDaysInvoice between 91 and 120  then '91-120'
        when AgingDaysInvoice between 121 and 180 then '121-180'
        when AgingDaysInvoice between 181 and 365 then '181-365'
        else '>365'
      end as AgingCategoryInvoice,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice between 1 and 30 then RemainingAmount else 0 end as AmtInv0130,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice between 31 and 60 then RemainingAmount else 0 end as AmtInv3160,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice between 61 and 90 then RemainingAmount else 0 end as AmtInv6190,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice between 91 and 120 then RemainingAmount else 0 end as AmtInv91120,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice between 121 and 180 then RemainingAmount else 0 end as AmtInv121180,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice between 181 and 365 then RemainingAmount else 0 end as AmtInv181365,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysInvoice > 365 then RemainingAmount else 0 end as AmtInvOver365,

      DueDateByBilling,
      AgingDaysBilling,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_AGINGCATEGORY_VH', element: 'AgingCategory' }, qualifier: 'Billing' }]
      case
        when AgingDaysBilling < 1                 then 'Ondue'
        when AgingDaysBilling between 1 and 30    then '1-30'
        when AgingDaysBilling between 31 and 60   then '31-60'
        when AgingDaysBilling between 61 and 90   then '61-90'
        when AgingDaysBilling between 91 and 120  then '91-120'
        when AgingDaysBilling between 121 and 180 then '121-180'
        when AgingDaysBilling between 181 and 365 then '181-365'
        else '>365'
      end as AgingCategoryBilling,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling between 1 and 30 then RemainingAmount else 0 end as AmtBil0130,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling between 31 and 60 then RemainingAmount else 0 end as AmtBil3160,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling between 61 and 90 then RemainingAmount else 0 end as AmtBil6190,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling between 91 and 120 then RemainingAmount else 0 end as AmtBil91120,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling between 121 and 180 then RemainingAmount else 0 end as AmtBil121180,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling between 181 and 365 then RemainingAmount else 0 end as AmtBil181365,
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      case when AgingDaysBilling > 365 then RemainingAmount else 0 end as AmtBilOver365,

      _Customer,
      _CustomerCompany,
      _BusinessPlace,
      _GLAccountText,
      _WBSElement,
      _SalesPartnerFunction,
      _PaymentTerms
}
