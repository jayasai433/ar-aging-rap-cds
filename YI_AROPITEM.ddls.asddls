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

  // Header-level source - needed for Invoice Date (distinct from item-level Posting Date)
  // and Invoice Description (header text), per your spec sheet columns O/Y.
  association [0..1] to I_AccountingDocument                   as _AccountingDocumentHeader
    on  $projection.CompanyCode        = _AccountingDocumentHeader.CompanyCode
    and $projection.FiscalYear         = _AccountingDocumentHeader.FiscalYear
    and $projection.AccountingDocument = _AccountingDocumentHeader.AccountingDocument

  // BP Group - association unverified: BusinessPartnerGrouping field/key needs confirming
  // against I_Customer or I_BusinessPartner in your system before activation.
  association [0..1] to I_BusinessPartnerGrouping               as _BPGroup
    on $projection.BPGroupCode = _BPGroup.BusinessPartnerGrouping

  association [0..1] to I_CompanyCode                           as _CompanyCodeText
    on $projection.CompanyCode = _CompanyCodeText.CompanyCode

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
      _CompanyCodeText.CompanyCodeName as CompanyName,     // text for Company Code - field name unverified
      Item.BusinessPlace        as CompanyBranch,         // J_1BBRANC_ via I_BusinessPlace assoc key
      Item.Customer             as CustomerCode,          // KUNNR
      _Customer.CustomerFullName as CustomerName,          // MD_CUSTOMER_FULL_NAME
      _CustomerCompany.CustomerSupplierClearingAcct as CustomerBranch, // KNRZE - field name unverified, confirm in ADT
      _BPGroup.BusinessPartnerGrouping as BPGroupCode,      // BU_GROUP - association source unverified
      _BPGroup.BusinessPartnerGroupingName as BPGroupName,
      Item.GLAccount            as GLAccount,             // FIS_RACCT
      _GLAccountText.GLAccountName as GLAccountName,        // FIN_GLACCOUNT_NAME
      Item.AccountingDocumentType as DocumentType,        // FARP_BLART
      Item.AccountingDocument   as JournalEntry,           // document number
      Item.DocumentReferenceID  as InvoiceReference,       // FIS_AWKEY
      Item.BillingDocument      as BillingNumber,          // VBELN_VF
      _AccountingDocumentHeader.DocumentHeaderText as InvoiceDescription, // BKTXT - field name unverified
      Item.WBSElementInternalID as WBSElementInternalID,   // FIS_WBSINT_NO_CONV
      _WBSElement.WBSElementBasicDataText as ProjectName,   // PS_S4_POST1 - confirm field name in ADT
      _SalesPartnerFunction.PartnerFunction as SalesName,   // PARVW - your spec notes this is SD-only, NULL for FI-direct docs

      // ---- Amounts (raw, no derived logic at this layer) ----
      Item.AmountInTransactionCurrency as InvoiceAmount,    // FIS_HSL - local currency amount
      Item.TransactionCurrency         as TransactionCurrency,

      // ---- Dates / payment terms (raw) ----
      _AccountingDocumentHeader.DocumentDate as InvoiceDate, // header-level FIS_BUDAT - distinct from item PostingDate below
      Item.PostingDate                 as PostingDate,      // item-level FIS_BUDAT
      Item.NetDueDate                  as BaselineDate,     // FIS_DZFBDT - confirm exact field at build time
      Item.PaymentTerms                as PaymentTermsCode, // FARP_DZTERM
      Item.ClearingDate                as ClearingDate,     // FIS_AUGDT
      // "Receipt Date/Payment Date" from your spec sheet (column AC) is NOT mapped here -
      // unclear whether this is identical to ClearingDate or a distinct field. Confirm
      // before this column is treated as final.

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
      _AccountingDocumentHeader,
      _BPGroup,
      _CompanyCodeText,
      _ClearingAgg
}
where
  Item.FinancialAccountType = 'D'
