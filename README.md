# AR Aging Report - RAP/CDS Rebuild (Developer Extensibility)

S/4HANA Cloud Public Edition 2602. Namespace prefix: Y (YI_ = interface layer, YC_ = consumption layer).

## Layer stack

1. `YI_AROPITEM` - base interface view on `I_OperationalAcctgDocItem`, FinancialAccountType = 'D' filter,
   associations to Customer/CustomerCompany/BusinessPlace/GLAccountText/WBSElement/SalesPartnerFunction.
2. `YI_ARCLEARINGAGG` - isolated SUM aggregation on clearing history (Paid Amount). Kept as the only
   aggregate expression in the stack so nothing downstream re-aggregates it.
3. `YI_ARAGING` - joins 1+2. Computes Remaining Amount, Due Date (Invoice basis), Net Payment Days
   lookup, Effective Aging Date (frozen at clearing date once fully paid), Aging Days (flat columns,
   both bases). Carries the Key Date parameter (`P_KeyDate`, defaults to system date via
   `@Environment.systemField: #SYSTEM_DATE`).
4. `YC_ARAGING` - consumption/query view. Invoice Status (NULL-safe CASE), Aging Category (CASE on the
   flat AgingDays columns inherited from layer 3), 14 aging amount bucket columns (7 buckets x 2 date
   bases), value help annotations.
5. `YI_INVOICESTATUS_VH` / `YCL_INVOICESTATUS_VH` - custom entity + ABAP class, fixed 3-value list
   (Open / Partially Paid / Cleared). Avoids the calculated-field value-help limitation from the
   key-user tool.
6. `YI_AGINGCATEGORY_VH` / `YCL_AGINGCATEGORY_VH` - same pattern, 8 fixed aging category buckets.
7. `YC_ARAGING.ddlx` - metadata extension. UI facets group the Invoice-Date-basis and
   Actual-Billing-Date-basis columns into separate object page sections.
8. `YC_ARAGING_SD` - service definition exposing the consumption view and both value help entities.
9. Service binding - NOT included as a text file. Create manually in ADT: right-click `YC_ARAGING_SD`
   -> New Service Binding -> ODATA V4 UI -> publish.

## Open items - confirm before activation

- **Field names on `I_OperationalAcctgDocItem`**: several element names in `YI_AROPITEM`
  (`NetDueDate`, `ClearingDate`, `BusinessPlace`, `WBSElementInternalID`, `DocumentReferenceID`,
  `BillingDocument`) are my best mapping from standard SAP naming conventions against the technical
  field names from the spec sheet (`FIS_DZFBDT`, `FIS_AUGDT`, etc.) - NOT independently verified
  against your system. Check the actual element list in ADT before compiling.
- **`I_OplAcctgDocItemClrgHist`**: clearing history source view name and its
  `AmountInTransactionCurrency` field are unverified.
- **`I_PaymentTerms` / `NetPaymentDays`**: the association in `YI_ARAGING` and the field it reads are
  placeholders. Confirm the actual released CDS view that maps a payment terms code to a net day
  count, and its exact element name.
- **Actual Billing Date (custom field)**: `DueDateByBilling` and `AgingDaysBilling` currently fall
  back to the same Baseline-Date-based calculation as the Invoice basis - this is a known placeholder,
  not a finished calculation. Confirm the custom field's technical name in the extension include of
  `I_OperationalAcctgDocItem`, then wire it in.
- **Multi-level/grouped column headers**: the metadata extension currently groups columns into
  separate UI facets (standard, confirmed mechanism), not true merged spanning headers in a flat list
  table. Whether Fiori Elements List Report/Analytical List Page supports literal merged headers is
  still unverified and may require a freestyle UI5 extension - treat as a separate spike.

## Field coverage update (second pass)

Originally pushed without: Customer Name, Customer Branch, GL Account Name, Project Name, Sales Name
(associations existed but fields were never selected), plus BP Group, Invoice Description, Invoice
Date (header-level, distinct from item-level Posting Date), Company Name, and a readable Payment
Terms text were missing entirely. All of these have now been added across `YI_AROPITEM`, `YI_ARAGING`,
and `YC_ARAGING`.

Still NOT resolved, by design (need your input, not guessed):

- **DSO (Days Sales Outstanding)**: not implemented. Your spec sheet shows it as an aggregate
  per-customer metric (Image 4/5), which doesn't fit cleanly into a per-line-item CDS view - it would
  typically be a separate aggregation query or a measure computed in the Fiori Elements Analytical
  List Page, not a row-level field. Confirm whether this is in scope for this CDS build at all before
  it gets added.
- **Receipt Date / Payment Date** (spec sheet column AC): not exposed. Unclear if this duplicates
  `ClearingDate` or is a genuinely separate field (e.g. bank receipt date vs. system clearing date).
- New associations added this pass (`_AccountingDocumentHeader`, `_BPGroup`, `_CompanyCodeText`) and
  the fields read through them (`InvoiceDate`, `InvoiceDescription`, `BPGroupCode`/`BPGroupName`,
  `CompanyName`, `CustomerBranch`, `ProjectName`, `SalesName`, `PaymentTermsText`) are UNVERIFIED
  element names - confirm each one in ADT before activation, same caution as the original field list.

## Things confirmed via SAP documentation during this build

- `DATS_DAYS_BETWEEN(date1, date2)` and `DATS_ADD_DAYS(date, days, on_error)` syntax.
- `@Environment.systemField: #SYSTEM_DATE` for defaulting a CDS parameter to system date.
- Custom entity + ABAP class (`IF_RAP_QUERY_PROVIDER`) as the standard pattern for fixed-value-help
  lists, used here for Invoice Status and Aging Category instead of the broken calculated-field
  association approach from the key-user tool.
- `I_OperationalAcctgDocCube` selects from `I_OperationalAcctgDocItem` with no additional filters
  (confirmed directly in ADT) - building straight off Item rather than Cube.
