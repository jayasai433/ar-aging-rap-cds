@AbapCatalog.sqlViewName: 'YIAROPITEM'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Customer Open Items (Interface)'
@VDM.viewType: #BASIC
define view entity YI_AROPITEM
  as select from I_OperationalAcctgDocItem as Item

  association [0..1] to I_Customer                        as _Customer
    on $projection.CustomerCode = _Customer.Customer

  association [0..1] to I_CustomerCompany                  as _CustomerCompany
    on  $projection.CustomerCode = _CustomerCompany.Customer
    and $projection.CompanyCode  = _CustomerCompany.CompanyCode

  association [0..1] to I_BusinessPlace                    as _BusinessPlace
    on  $projection.CompanyCode   = _BusinessPlace.CompanyCode
    and $projection.CompanyBranch = _BusinessPlace.BusinessPlace

  association [0..1] to I_GLAccountTextInCompanyCode        as _GLAccountText
    on  $projection.CompanyCode = _GLAccountText.CompanyCode
    and $projection.GLAccount   = _GLAccountText.GLAccount

  association [0..1] to I_WBSElementBasicData                as _WBSElement
    on $projection.WBSElementInternalID = _WBSElement.WBSElementInternalID

  association [0..1] to I_CustSalesPartnerFunc                as _SalesPartnerFunction
    on $projection.AccountingDocument = _SalesPartnerFunction.SalesDocument

  // Clearing aggregate, joined to bring Paid Amount onto the item
  association [0..1] to YI_ARCLEARINGAGG                     as _ClearingAgg
    on  $projection.CompanyCode        = _ClearingAgg.CompanyCode
    and $projection.AccountingDocument = _ClearingAgg.AccountingDocument
    and $projection.FiscalYear         = _ClearingAgg.FiscalYear
    and $projection.AccountingDocumentItem = _ClearingAgg.AccountingDocumentItem

{
      // ---- Keys ----
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.AccountingDocumentItem,
  key Item.CompanyCode,

      // ---- Org / partner dimensions ----
      Item.FiscalYear           as FiscalYearNum,         // FIS_GJAHR_NO_CONV
      Item.CompanyCode          as CompanyCode,           // FIS_BUKRS
      Item.BusinessPlace        as CompanyBranch,         // J_1BBRANC_ via I_BusinessPlace assoc key
      Item.Customer             as CustomerCode,          // KUNNR
      Item.GLAccount            as GLAccount,             // FIS_RACCT
      Item.AccountingDocumentType as DocumentType,        // FARP_BLART
      Item.AccountingDocument   as JournalEntry,           // document number
      Item.DocumentReferenceID  as InvoiceReference,       // FIS_AWKEY
      Item.BillingDocument      as BillingNumber,          // VBELN_VF
      Item.WBSElementInternalID as WBSElementInternalID,   // FIS_WBSINT_NO_CONV

      // ---- Amounts (raw, no derived logic at this layer) ----
      Item.AmountInTransactionCurrency as InvoiceAmount,    // FIS_HSL - local currency amount
      Item.TransactionCurrency         as TransactionCurrency,

      // ---- Dates / payment terms (raw) ----
      Item.PostingDate                 as PostingDate,      // FIS_BUDAT
      Item.NetDueDate                  as BaselineDate,     // FIS_DZFBDT - confirm exact field at build time
      Item.PaymentTerms                as PaymentTermsCode, // FARP_DZTERM
      Item.ClearingDate                as ClearingDate,     // FIS_AUGDT

      // Custom field - actual physical invoice submission date.
      // NOTE: only include this once confirmed visible in the extension include
      // of I_OperationalAcctgDocItem in ADT - placeholder name below.
      // Item.YY1_ActualBillingDate    as ActualBillingDate,

      // ---- Filter discriminator kept visible for transparency ----
      Item.FinancialAccountType        as FinancialAccountType,

      // ---- Associations exposed ----
      _Customer,
      _CustomerCompany,
      _BusinessPlace,
      _GLAccountText,
      _WBSElement,
      _SalesPartnerFunction,
      _ClearingAgg
}
where
  Item.FinancialAccountType = 'D'
