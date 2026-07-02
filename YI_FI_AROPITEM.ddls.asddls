@AbapCatalog.sqlViewName: 'YIAROPITEM'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Customer Open Items (Interface)'
@VDM.viewType: #BASIC
define view entity YI_FI_AROPITEM
  as select from I_OperationalAcctgDocCube as Item

  // ---- All associations below verified against the person's own published
  // Custom CDS View (Data Sources / Elements screenshots, confirmed 01.07.2026) ----

  association [0..1] to I_Customer                          as _Customer
    on $projection.CustomerCode = _Customer.Customer

  association [0..1] to I_CustomerCompany                    as _CustomerCompany
    on  $projection.CustomerCode = _CustomerCompany.Customer
    and $projection.CompanyCode  = _CustomerCompany.CompanyCode

  association [0..1] to I_BusinessPlace                      as _BusinessPlace
    on  $projection.CompanyCode   = _BusinessPlace.CompanyCode
    and $projection.CompanyBranch = _BusinessPlace.BusinessPlace

  // Custom CDS view - same one already used and published in the person's
  // key-user build (alias _YY1_AR_BP_Group in their Data Sources list).
  // Join condition CONFIRMED directly from the person's ADT "Define Join
  // Conditions" screen: both Customer and BusinessPartner on YY1_AR_BP_Group
  // are joined to Item.Customer (person confirmed Business Partner = Customer
  // in their S/4HANA configuration - this is their business-process
  // confirmation, not something I can independently verify).
  association [0..1] to YY1_AR_BP_Group                      as _BPGroup
    on  $projection.CustomerCode = _BPGroup.Customer
    and $projection.CustomerCode = _BPGroup.BusinessPartner

  association [0..1] to I_WBSElementBasicData                 as _WBSElement
    on $projection.WBSElementInternalID = _WBSElement.WBSElementInternalID

  // Sales Partner Function - routed through YI_FI_ARSLSPTNR to guarantee a
  // single deterministic row per document (MIN-based), since the full key
  // set for I_CustSalesPartnerFunc is not joined and multiple partner
  // functions can exist per document.
  association [0..1] to YI_FI_ARSLSPTNR                      as _SalesPartnerFunction
    on $projection.AccountingDocument = _SalesPartnerFunction.SalesDocument

  // Clearing history - CONFIRMED real, cardinality [0..*], from person's own
  // published Data Sources list. Fields confirmed: AmountInCompanyCodeCurrency,
  // ClearingCompanyCodeCurrency.
  association [0..*] to I_OplAcctgDocItemClrgHist               as _ClearingHistory
    on  $projection.CompanyCode        = _ClearingHistory.CompanyCode
    and $projection.AccountingDocument = _ClearingHistory.AccountingDocument
    and $projection.FiscalYear         = _ClearingHistory.FiscalYear
    and $projection.AccountingDocumentItem = _ClearingHistory.AccountingDocumentItem

  // Clearing aggregate (SUM), built on top of the association above -
  // see YI_FI_ARCLRAGG for the isolated aggregation logic.
  association [0..1] to YI_FI_ARCLRAGG                        as _ClearingAgg
    on  $projection.CompanyCode        = _ClearingAgg.CompanyCode
    and $projection.AccountingDocument = _ClearingAgg.AccountingDocument
    and $projection.FiscalYear         = _ClearingAgg.FiscalYear
    and $projection.AccountingDocumentItem = _ClearingAgg.AccountingDocumentItem

  // Journal Entry Item - confirmed real, this is how the custom Actual Billing
  // Date field is reached: _JournalEntry._JournalEntryItem.YY1_ActualBillingDate_JEI
  association [0..1] to I_JournalEntry                          as _JournalEntry
    on  $projection.CompanyCode        = _JournalEntry.CompanyCode
    and $projection.FiscalYear         = _JournalEntry.FiscalYear
    and $projection.AccountingDocument = _JournalEntry.AccountingDocument

{
      // ---- Keys ----
  key Item.AccountingDocument,
  key Item.FiscalYear,
  key Item.AccountingDocumentItem,
  key Item.CompanyCode,

      // ---- Org / partner dimensions ----
      Item.FiscalYear                    as FiscalYearNum,
      Item.CompanyCode                   as CompanyCode,
      Item.CompanyCodeCurrency           as CompanyCodeCurrency,       // CONFIRMED, replaces earlier TransactionCurrency guess
      Item.BusinessPlace                 as CompanyBranch,
      _BPGroup.BusinessPartnerGrouping   as BPGroupCode,
      // BPGroupName not yet confirmed on YY1_AR_BP_Group - left out until
      // the person confirms that view's own field list.
      Item.Customer                      as CustomerCode,
      _Customer.CustomerName             as CustomerName,              // CONFIRMED alias, was CustomerFullName - wrong before
      _CustomerCompany.CustomerHeadOffice as CustomerBranch,           // CONFIRMED, was CustomerSupplierClearingAcct - wrong before
      Item.GLAccount                     as GLAccount,
      Item.GLAccountName                 as GLAccountName,             // CONFIRMED direct field, association removed
      Item._AccountingDocumentType.AccountingDocumentType as DocumentType, // CONFIRMED path via association per screenshot
      Item.AccountingDocument            as JournalEntry,
      Item.BillingDocument               as BillingNumber,             // CONFIRMED direct field
      Item.AccountingDocumentHeaderText  as InvoiceDescription,        // CONFIRMED direct field, header association removed
      Item.WBSElementInternalID          as WBSElementInternalID,
      _WBSElement.WBSDescription         as ProjectName,               // CONFIRMED alias, was WBSElementBasicDataText - wrong before
      _SalesPartnerFunction.PartnerFunction as SalesName,

      // Original reference document - confirmed present, reached via
      // clearing history association's own _ClearingDocument association.
      // Kept here for visibility though it is clearing-side, not item-side.
      // _ClearingHistory._ClearingDocument.OriginalReferenceDocument as OriginalReferenceDocument,

      // ---- Amounts (raw, no derived logic at this layer) ----
      Item.InvoiceAmtInCoCodeCrcy        as InvoiceAmount,             // CONFIRMED, was AmountInTransactionCurrency - wrong before

      // ---- Dates / payment terms (raw) ----
      Item.PostingDate                   as PostingDate,
      Item.DueCalculationBaseDate        as BaselineDate,              // CONFIRMED field exists; confirm semantics if used for display
      Item.NetDueDate                    as DueDateByInvoice,          // CONFIRMED = Baseline Date + NetPaymentDays, verified by the person directly
      Item.NetPaymentDays                as NetPaymentDays,            // CONFIRMED direct field, no I_PaymentTerms lookup needed
      Item.PaymentTerms                  as PaymentTermsCode,
      Item.ClearingDate                  as ClearingDate,

      // Custom field - CONFIRMED real and reachable via Journal Entry Item association
      _JournalEntry._JournalEntryItem.YY1_ActualBillingDate_JEI as ActualBillingDate,

      // ---- Filter discriminator kept visible for transparency ----
      Item.FinancialAccountType          as FinancialAccountType,

      // ---- Associations exposed ----
      _Customer,
      _CustomerCompany,
      _BusinessPlace,
      _BPGroup,
      _WBSElement,
      _SalesPartnerFunction,
      _ClearingHistory,
      _ClearingAgg,
      _JournalEntry
}
where
  Item.FinancialAccountType = 'D'
