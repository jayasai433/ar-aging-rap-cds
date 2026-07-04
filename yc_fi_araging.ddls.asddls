@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging Report'
@Metadata.allowExtensions: true
@Search.searchable: true
@UI.headerInfo: {
  typeName: 'AR Invoice',
  typeNamePlural: 'AR Invoices',
  title: { type: #STANDARD, value: 'JournalEntry' }
}
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

      @UI.lineItem: [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
      FiscalYearNum,

      @UI.lineItem: [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
      CompanyCodeOut,

      @UI.lineItem: [{ position: 30 }]
      @UI.selectionField: [{ position: 21 }]
      // No verified value-help target for Business Place at this level -
      // filterable as free text/exact match, no dropdown.
      CompanyBranch,

      @UI.lineItem: [{ position: 35 }]
      @UI.selectionField: [{ position: 25 }]
      // Dropdown removed per instruction - only Invoice Status and Aging
      // Category should have value help dropdowns. Filterable as exact
      // match/text, no dropdown.
      BPGroupCode,

      @UI.lineItem: [{ position: 40 }]
      @UI.selectionField: [{ position: 30 }]
      // Dropdown removed per instruction - only Invoice Status and Aging
      // Category should have value help dropdowns.
      CustomerCode,

      @UI.lineItem: [{ position: 41 }]
      CustomerName,

      @UI.lineItem: [{ position: 42 }]
      @UI.selectionField: [{ position: 31 }]
      // No verified value-help target - filterable, no dropdown.
      CustomerBranch,

      @UI.lineItem: [{ position: 50 }]
      @UI.selectionField: [{ position: 45 }]
      // Dropdown removed per instruction - only Invoice Status and Aging
      // Category should have value help dropdowns. Filterable as exact
      // match/text, no dropdown.
      GLAccount,

      @UI.lineItem: [{ position: 51 }]
      GLAccountName,

      @UI.lineItem: [{ position: 60 }]
      @UI.selectionField: [{ position: 40 }]
      DocumentType,

      @UI.lineItem: [{ position: 70 }]
      @UI.selectionField: [{ position: 70 }]
      @Search.defaultSearchElement: true
      // Document number - free-text/exact-match filter, no dropdown by design.
      // @Search.defaultSearchElement added to satisfy the required-for-searchable-
      // view constraint (confirmed real SAP error ESH_ENG_CDSVAL_SRCH001/006:
      // "At least one element has to be set as 'defaultSearchElement'").
      JournalEntry,

      @UI.lineItem: [{ position: 80 }]
      @UI.selectionField: [{ position: 46 }]
      // PLACEHOLDER field - see YI_FI_AROPITEM comment. VERIFY the real
      // source field before relying on this in production.
      InvoiceReference,

      @UI.lineItem: [{ position: 90 }]
      BillingNumber,

      @UI.lineItem: [{ position: 91 }]
      InvoiceDescription,

      @UI.lineItem: [{ position: 100 }]
      // NOT adding a selection field here - WBSElementInternalID's related
      // description field (I_WBSElementBasicData) was confirmed NOT released
      // for Developer Extensibility (see README/conversation). Filtering on
      // the raw ID alone may still work, but leaving this unfiltered until
      // that WBS access question is resolved, to avoid half-working UX.
      WBSElementInternalID,

      @UI.lineItem: [{ position: 101 }]
      ProjectName,

      @UI.lineItem: [{ position: 102 }]
      @UI.selectionField: [{ position: 90 }]
      // Derived from our deterministic YI_FI_ARSLSPTNR (MIN-based pick) -
      // no dropdown, since this isn't a stable master-data value help target.
      SalesName,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 111 }]
      InvoiceAmount,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 120 }]
      PaidAmount,

      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 130 }]
      RemainingAmount,

      @Semantics.currencyCode: true
      CompanyCodeCurrency,

      @UI.lineItem: [{ position: 135 }]
      PostingDate,
      @UI.lineItem: [{ position: 136 }]
      BaselineDate,
      ClearingDate,
      @UI.lineItem: [{ position: 137 }]
      @UI.selectionField: [{ position: 80 }]
      // No verified value-help target for payment terms text - filterable,
      // no dropdown.
      PaymentTermsCode,
      @UI.lineItem: [{ position: 138 }]
      NetPaymentDays,
      @UI.lineItem: [{ position: 139 }]
      KeyDateOut,
      @UI.lineItem: [{ position: 145 }]
      ActualBillingDate,
      // "Receipt Date/Payment Date" (spec column AC) intentionally not exposed yet -
      // see README, still needs confirmation on whether it equals ClearingDate or is separate.

      // =========================================================
      // Invoice Status - NULL-safe, fixed-value dropdown
      // =========================================================
      // Calculation moved to YI_FI_ARAGING (2026-07-03) - CASE expressions
      // are not supported directly in a Projection view. This is now a plain
      // passthrough reference.
      @UI.lineItem: [{ position: 105 }]
      @UI.selectionField: [{ position: 50 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_FI_INVSTATUS_VH', element: 'InvoiceStatus' } }]
      InvoiceStatus,

      // =========================================================
      // Invoice Date basis
      // =========================================================
      @UI.lineItem: [{ position: 150 }]
      DueDateByInvoice,
      EffectiveAgingDate as EffectiveDateInvoice,
      @UI.lineItem: [{ position: 151 }]
      AgingDaysInvoice,

      // Calculation moved to YI_FI_ARAGING - see note above.
      @UI.lineItem: [{ position: 152 }]
      @UI.selectionField: [{ position: 60 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_FI_AGINGCAT_VH', element: 'InvoiceDateStatus' }, qualifier: 'Invoice' }]
      AgingCategoryInvoice,

      // ---- Aging amount buckets, Invoice Date basis ----
      // Calculations moved to YI_FI_ARAGING - see note above. Annotations
      // kept here too since currency semantics should be restated at each
      // projection layer per the earlier propagation-gap fix.
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 200 }]
      AmtInv0130,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 201 }]
      AmtInv3160,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 202 }]
      AmtInv6190,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 203 }]
      AmtInv91120,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 204 }]
      AmtInv121180,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 205 }]
      AmtInv181365,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 206 }]
      AmtInvOver365,

      // =========================================================
      // Actual Billing Date basis
      // =========================================================
      @UI.lineItem: [{ position: 160 }]
      DueDateByBilling,
      @UI.lineItem: [{ position: 161 }]
      AgingDaysBilling,

      // Calculation moved to YI_FI_ARAGING - see note above.
      @UI.lineItem: [{ position: 162 }]
      @UI.selectionField: [{ position: 61 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'YI_FI_AGINGCAT_VH', element: 'InvoiceDateStatus' }, qualifier: 'Billing' }]
      AgingCategoryBilling,

      // ---- Aging amount buckets, Actual Billing Date basis ----
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 210 }]
      AmtBil0130,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 211 }]
      AmtBil3160,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 212 }]
      AmtBil6190,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 213 }]
      AmtBil91120,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 214 }]
      AmtBil121180,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 215 }]
      AmtBil181365,
      @Semantics.amount.currencyCode: 'CompanyCodeCurrency'
      @UI.lineItem: [{ position: 216 }]
      AmtBilOver365,

      _Customer,
      _CustomerCompany,
      _BusinessPlace,
      _BPGroup,
      _WBSElement,
      _SalesPartnerFunction
}
