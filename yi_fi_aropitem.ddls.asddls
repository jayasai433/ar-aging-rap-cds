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

  // Custom CDS view - RECREATED as YI_FI_ARBPGROUP (proper ADT/DDL object),
  // replacing the earlier key-user Custom CDS View 'YY1_AR_BP_Group' this was
  // originally pointed at. Join condition CONFIRMED directly from the person's
  // ADT "Define Join Conditions" screen for the key-user version: both Customer
  // and BusinessPartner joined to Item.Customer (person confirmed Business
  // Partner = Customer in their S/4HANA configuration).
  association [0..1] to YI_FI_ARBPGROUP                      as _BPGroup
    on  $projection.CustomerCode = _BPGroup.Customer
    and $projection.CustomerCode = _BPGroup.BusinessPartner

  association [0..1] to I_WBSElementBasicData                 as _WBSElement
    on $projection.WBSElementInternalID = _WBSElement.WBSElementInternalID

  // Sales Partner Function - routed through YI_FI_ARSLSPTNR, joined on Customer
  // only (Sales Area unavailable at this level, see YI_FI_ARSLSPTNR header
  // comment for the full explanation of this correction).
  association [0..1] to YI_FI_ARSLSPTNR                      as _SalesPartnerFunction
    on $projection.CustomerCode = _SalesPartnerFunction.Customer

  // Clearing history - CONFIRMED real, cardinality [0..*], from person's own
  // published Data Sources list. Fields confirmed: AmountInCompanyCodeCurrency,
  // ClearingCompanyCodeCurrency.
  // Clearing aggregate (SUM), built on our custom YI_FI_ARCLRAGG, which itself
  // selects from the standard I_OplAcctgDocItemClrgHist and aggregates it.
  // This is the only clearing-related association actually used by the report.
  // (A separate direct association straight to I_OplAcctgDocItemClrgHist was
  // removed here - it was unused except for one commented-out field.)
  association [0..1] to YI_FI_ARCLRAGG                        as _ClearingAgg
    on  $projection.CompanyCode        = _ClearingAgg.ClearedCompanyCode
    and $projection.AccountingDocument = _ClearingAgg.ClearedAccountingDocument
    and $projection.FiscalYear         = _ClearingAgg.ClearedFiscalYear
    and $projection.AccountingDocumentItem = _ClearingAgg.ClearedAccountingDocumentItem

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

      // PLACEHOLDER field - not yet confirmed which real field on
      // I_OperationalAcctgDocCube corresponds to "Invoice Number" per the
      // spec sheet. Mapped to DocumentReferenceID as a guess/dummy so the
      // field exists end-to-end and is easy to swap later. VERIFY AND
      // REPLACE the field name below once confirmed.
      Item.DocumentReferenceID           as InvoiceReference,

      Item.BillingDocument               as BillingNumber,             // CONFIRMED direct field
      Item.AccountingDocumentHeaderText  as InvoiceDescription,        // CONFIRMED direct field, header association removed
      Item.WBSElementInternalID          as WBSElementInternalID,
      _WBSElement.WBSDescription         as ProjectName,               // CONFIRMED alias, was WBSElementBasicDataText - wrong before
      _SalesPartnerFunction.PartnerFunction as SalesName,

      // ---- Amounts (raw, no derived logic at this layer) ----
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
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
      _ClearingAgg,
      _JournalEntry
}
where
  Item.FinancialAccountType = 'D'
