@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Customer Open Items (Interface)'
@VDM.viewType: #BASIC
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #L
@ObjectModel.usageType.dataClass: #MIXED
define view entity YI_AROPITEM
  as select from I_OperationalAcctgDocItem as Item

  association [0..1] to I_Customer as _Customer
    on $projection.CustomerCode = _Customer.Customer

  association [0..1] to I_CustomerCompany as _CustomerCompany
    on  $projection.CustomerCode = _CustomerCompany.Customer
    and $projection.CompanyCode  = _CustomerCompany.CompanyCode

  association [0..1] to I_BusinessPlace as _BusinessPlace
    on  $projection.CompanyCode   = _BusinessPlace.CompanyCode
    and $projection.CompanyBranch = _BusinessPlace.BusinessPlace

  association [0..1] to I_GLAccountTextInCompanyCode as _GLAccountText
    on  $projection.CompanyCode = _GLAccountText.CompanyCode
    and $projection.GLAccount   = _GLAccountText.GLAccount

  association [0..1] to I_WBSElementBasicData as _WBSElement
    on $projection.WBSElementInternalID = _WBSElement.WBSElementInternalID

  association [0..1] to I_CustSalesPartnerFunc as _SalesPartnerFunction
    on $projection.AccountingDocument = _SalesPartnerFunction.SalesDocument

  association [0..1] to I_AccountingDocument as _AccountingDocumentHeader
    on  $projection.CompanyCode        = _AccountingDocumentHeader.CompanyCode
    and $projection.FiscalYear         = _AccountingDocumentHeader.FiscalYear
    and $projection.AccountingDocument = _AccountingDocumentHeader.AccountingDocument

  association [0..1] to I_BusinessPartnerGrouping as _BPGroup
    on $projection.BPGroupCode = _BPGroup.BusinessPartnerGrouping

  association [0..1] to I_CompanyCode as _CompanyCodeText
    on $projection.CompanyCode = _CompanyCodeText.CompanyCode

  association [0..1] to YI_ARCLEARINGAGG as _ClearingAgg
    on  $projection.CompanyCode           = _ClearingAgg.CompanyCode
    and $projection.AccountingDocument    = _ClearingAgg.AccountingDocument
    and $projection.FiscalYear            = _ClearingAgg.FiscalYear
    and $projection.AccountingDocumentItem = _ClearingAgg.AccountingDocumentItem

{
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.AccountingDocumentItem,
  key Item.CompanyCode,

      Item.FiscalYear                                as FiscalYearNum,
      Item.CompanyCode                               as CompanyCode,
      _CompanyCodeText.CompanyCodeName               as CompanyName,
      Item.BusinessPlace                             as CompanyBranch,
      Item.Customer                                  as CustomerCode,
      _Customer.CustomerFullName                     as CustomerName,
      _CustomerCompany.CustomerSupplierClearingAcct  as CustomerBranch,
      _BPGroup.BusinessPartnerGrouping               as BPGroupCode,
      _BPGroup.BusinessPartnerGroupingName           as BPGroupName,
      Item.GLAccount                                 as GLAccount,
      _GLAccountText.GLAccountName                   as GLAccountName,
      Item.AccountingDocumentType                    as DocumentType,
      Item.AccountingDocument                        as JournalEntry,
      Item.DocumentReferenceID                       as InvoiceReference,
      Item.BillingDocument                           as BillingNumber,
      _AccountingDocumentHeader.DocumentHeaderText   as InvoiceDescription,
      Item.WBSElementInternalID                      as WBSElementInternalID,
      _WBSElement.WBSElementBasicDataText            as ProjectName,
      _SalesPartnerFunction.PartnerFunction          as SalesName,

      Item.AmountInTransactionCurrency               as InvoiceAmount,
      Item.TransactionCurrency                       as TransactionCurrency,

      _AccountingDocumentHeader.DocumentDate         as InvoiceDate,
      Item.PostingDate                               as PostingDate,
      Item.NetDueDate                                as BaselineDate,
      Item.PaymentTerms                              as PaymentTermsCode,
      Item.ClearingDate                              as ClearingDate,

      Item.FinancialAccountType                      as FinancialAccountType,

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
