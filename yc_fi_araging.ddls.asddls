@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging Report'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity YC_FI_ARAGING
  provider contract transactional_query
  // CONFIRMED real restriction: "Parameters are prohibited in Transactional
  // Projected Views" - transactional_query does not support parameters at
  // all. Verified against official SAP documentation. Key Date is therefore
  // fixed to system date here, not user-overridable at this layer -
  // functionality loss versus the original spec sheet requirement
  // ("Key Date... like current date but can be changed"). Alternatives
  // considered and ruled out: analytical_query (requires an analytical cube
  // view source, incompatible with our design), transactional_interface
  // (no new fields/associations allowed), sql_query (not supported in this
  // system's release, per the person's direct check in ADT).
  as projection on YI_FI_ARAGING( P_KeyDate: $session.system_date )
{
  key AccountingDocument,
  key FiscalYear,
  key AccountingDocumentItem,
  key CompanyCode,

      FiscalYearNum,

      CompanyCodeOut,

      CompanyBranch,

      BPGroupCode,

      CustomerCode,

      CustomerName,

      CustomerBranch,

      GLAccount,

      GLAccountName,

      DocumentType,

      @Search.defaultSearchElement: true
      // Document number - free-text/exact-match filter, no dropdown by design.
      // @Search.defaultSearchElement added to satisfy the required-for-searchable-
      // view constraint (confirmed real SAP error ESH_ENG_CDSVAL_SRCH001/006:
      // "At least one element has to be set as 'defaultSearchElement'").
      JournalEntry,

      // PLACEHOLDER field - see YI_FI_AROPITEM comment. VERIFY the real
      // source field before relying on this in production.
      InvoiceReference,

      BillingNumber,

      InvoiceDescription,

      WBSElementInternalID,

      ProjectName,

      SalesName,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      InvoiceAmount,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      PaidAmount,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      RemainingAmount,

      @Semantics.currencyCode: true
      CompanyCodeCurrency,

      PostingDate,
      BaselineDate,
      ClearingDate,
      PaymentTermsCode,
      NetPaymentDays,
      KeyDateOut,
      ActualBillingDate,
      // "Receipt Date/Payment Date" (spec column AC) intentionally not exposed yet -
      // see README, still needs confirmation on whether it equals ClearingDate or is separate.

      // =========================================================
      // Invoice Status - NULL-safe, fixed-value dropdown
      // =========================================================
      // Calculation moved to YI_FI_ARAGING (2026-07-03) - CASE expressions
      // are not supported directly in a Projection view. This is now a plain
      // passthrough reference.
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_FI_INVSTATUS_VH', element: 'InvoiceStatus' } }]
      InvoiceStatus,

      // =========================================================
      // Invoice Date basis
      // =========================================================
      DueDateByInvoice,
      EffectiveAgingDate as EffectiveDateInvoice,
      AgingDaysInvoice,

      // Calculation moved to YI_FI_ARAGING - see note above.
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_FI_AGINGCAT_VH', element: 'InvoiceDateStatus' }, qualifier: 'Invoice' }]
      AgingCategoryInvoice,

      // ---- Aging amount buckets, Invoice Date basis ----
      // Calculations moved to YI_FI_ARAGING - see note above. Annotations
      // kept here too since currency semantics should be restated at each
      // projection layer per the earlier propagation-gap fix.
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInv0130,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInv3160,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInv6190,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInv91120,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInv121180,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInv181365,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtInvOver365,

      // =========================================================
      // Actual Billing Date basis
      // =========================================================
      DueDateByBilling,
      AgingDaysBilling,

      // Calculation moved to YI_FI_ARAGING - see note above.
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_FI_AGINGCAT_VH', element: 'InvoiceDateStatus' }, qualifier: 'Billing' }]
      AgingCategoryBilling,

      // ---- Aging amount buckets, Actual Billing Date basis ----
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBil0130,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBil3160,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBil6190,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBil91120,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBil121180,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBil181365,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      AmtBilOver365,

      _Customer,
      _CustomerCompany,
      _BusinessPlace,
      _BPGroup,
      _WBSElement,
      _SalesPartnerFunction
}
