@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging Report'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #L
@ObjectModel.usageType.dataClass: #MIXED
@UI.headerInfo: {
  typeName: 'AR Invoice',
  typeNamePlural: 'AR Invoices',
  title: { type: #STANDARD, value: 'JournalEntry' }
}
define root view entity YC_ARAGING
  provider contract transactional_query
  as projection on YI_ARAGING
{
  key AccountingDocument,
  key FiscalYear,
  key AccountingDocumentItem,
  key CompanyCode,

      @UI.lineItem: [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
      FiscalYearNum,

      @UI.lineItem: [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
      CompanyCodeOut,

      @UI.lineItem: [{ position: 21 }]
      CompanyName,

      @UI.lineItem: [{ position: 30 }]
      CompanyBranch,

      @UI.lineItem: [{ position: 35 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_BusinessPartnerGrouping', element: 'BusinessPartnerGrouping' } }]
      BPGroupCode,

      @UI.lineItem: [{ position: 36 }]
      BPGroupName,

      @UI.lineItem: [{ position: 40 }]
      @UI.selectionField: [{ position: 30 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
      CustomerCode,

      @UI.lineItem: [{ position: 41 }]
      CustomerName,

      @UI.lineItem: [{ position: 42 }]
      CustomerBranch,

      @UI.lineItem: [{ position: 50 }]
      GLAccount,

      @UI.lineItem: [{ position: 51 }]
      GLAccountName,

      @UI.lineItem: [{ position: 60 }]
      @UI.selectionField: [{ position: 40 }]
      DocumentType,

      @UI.lineItem: [{ position: 70 }]
      JournalEntry,

      @UI.lineItem: [{ position: 80 }]
      InvoiceReference,

      @UI.lineItem: [{ position: 85 }]
      InvoiceDescription,

      @UI.lineItem: [{ position: 90 }]
      BillingNumber,

      @UI.lineItem: [{ position: 100 }]
      WBSElementInternalID,

      @UI.lineItem: [{ position: 101 }]
      ProjectName,

      @UI.lineItem: [{ position: 102 }]
      SalesName,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      @UI.lineItem: [{ position: 110 }]
      InvoiceAmount,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      @UI.lineItem: [{ position: 120 }]
      PaidAmount,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      @UI.lineItem: [{ position: 130 }]
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

      @UI.lineItem: [{ position: 140 }]
      @UI.selectionField: [{ position: 50 }]
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

      @UI.selectionField: [{ position: 60 }]
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
