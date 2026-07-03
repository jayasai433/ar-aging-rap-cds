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

## Third pass - corrected against person's own published Custom CDS View (01.07.2026)

The person shared screenshots of their actual published, working key-user Custom CDS View
(Data Sources, Elements, and additional Elements tabs). This let several previously "unverified"
field names get corrected against real, confirmed data - not guesses.

**Confirmed real and now used:**
- `I_OplAcctgDocItemClrgHist` - the clearing history view genuinely exists, cardinality [0..*].
  Field used for Paid Amount: `AmountInCompanyCodeCurrency` (was wrongly assumed to be
  `AmountInTransactionCurrency`).
- `NetPaymentDays` - DEC(3,0), directly on the item/Cube. The `I_PaymentTerms` association and
  lookup built in the second pass has been REMOVED - it was unnecessary.
- `NetDueDate` - DATS(8), directly on the item. CONFIRMED BY THE PERSON DIRECTLY to equal
  Baseline Date + NetPaymentDays, already computed by SAP. Used as-is for `DueDateByInvoice` -
  no `DATS_ADD_DAYS` calculation needed for the Invoice basis.
- `YY1_ActualBillingDate_JEI` - DATS(8), the custom field, reached via
  `_JournalEntry._JournalEntryItem.YY1_ActualBillingDate_JEI`. This was a placeholder in the
  second pass and is now wired in for real. The Actual Billing Date aging block now does its
  own real `DATS_ADD_DAYS(ActualBillingDate, NetPaymentDays)` calculation, since no equivalent
  pre-computed field exists for this custom basis.
- `InvoiceAmtInCoCodeCrcy` (was wrongly `AmountInTransactionCurrency`), `CompanyCodeCurrency`
  (was wrongly `TransactionCurrency`), `_Customer.CustomerName` (was wrongly `CustomerFullName`),
  `_CustomerCompany.CustomerHeadOffice` (was wrongly `CustomerSupplierClearingAcct`),
  `GLAccountName` direct on item (association removed), `AccountingDocumentHeaderText` direct
  on item (header association removed), `_WBSElementBasicData.WBSDescription` (was wrongly
  `WBSElementBasicDataText`).
- Primary data source corrected to `I_OperationalAcctgDocCube`, matching the person's actual
  published view, rather than `I_OperationalAcctgDocItem` directly.

**Changed / removed:**
- BP Group now associates to the person's own custom view `YY1_AR_BP_Group` (already published
  and used in their key-user build) instead of the standard `I_BusinessPartnerGrouping` - the
  latter was never confirmed to be the right target. `YY1_AR_BP_Group`'s own field list has not
  been seen, so only `BusinessPartnerGrouping` (the join key) is used for now; BP Group Name is
  not yet exposed pending confirmation of that view's fields.
- Invoice Date (header-level) removed - was based on an unconfirmed `_AccountingDocumentHeader`
  association that the person's real view does not use. Not reinstated until a real need and a
  confirmed field are established.
- Invoice Reference (`DocumentReferenceID`) removed - not seen anywhere in the person's real
  Elements list; may not exist as named, or may require a different path. Needs re-investigation
  if this field is actually required.
- Payment Terms text (readable label) removed - was based on the now-removed `I_PaymentTerms`
  association. `PaymentTermsCode` (raw code) is still exposed.

**Still open, unchanged from before:**
- DSO - still not implemented, still a scope question.
- Receipt Date / Payment Date (spec sheet column AC) - still not mapped, still unclear if it
  equals `ClearingDate` or is separate.
- `YY1_AR_BP_Group`'s own fields (beyond the join key) are unseen - if BP Group Name or other
  attributes are needed, that view's Elements list needs to be shared too.
- The 14 aging amount bucket columns and both Aging Category columns are now genuinely correct
  for both bases, since `DueDateByBilling` no longer silently duplicates the Invoice basis - this
  was flagged as a known placeholder bug in the second pass and is now fixed.

**Still NOT verified, flagged honestly:**
- I have not seen `I_JournalEntry` / `_JournalEntryItem`'s full field list beyond the one custom
  field confirmed in the screenshot - the association path is inferred from the alias shown
  (`_JournalEntry._JournalEntryItem.YY1_ActualBillingDate_JEI`) and may need adjustment if the
  actual association structure differs.
- Sales Name / Partner Function fan-out risk - CONFIRMED by the person that `I_CustSalesPartnerFunc`
  is real, but its full key set is not joined (deliberately, to avoid needing every key field), which
  means multiple partner function rows can exist per document. Fixed by routing through a new
  isolated view, `YI_ARSALESPARTNER`, which uses `MIN(PartnerFunction) GROUP BY SalesDocument` to
  deterministically pick one row every time - avoiding both fan-out (duplicate report rows) and
  non-deterministic results from unordered SQL. The join key `SalesDocument = AccountingDocument`
  is still carried over from the original spec sheet only, NOT independently verified against this
  view's real key structure - confirm in ADT before activation.
- `_BPGroup` association join CORRECTED - confirmed directly from the person's ADT "Define Join
  Conditions" screen that `YY1_AR_BP_Group` (technical name `AR_BP_Grouping`, built on
  `I_BusinessPartnerCustomer`) joins on both `Customer` and `BusinessPartner`, both equal to
  `Item.Customer` (person confirmed Business Partner = Customer in their S/4HANA configuration).
  The earlier version had a circular join condition (joining on `BusinessPartnerGrouping`, a field
  that is itself sourced FROM this association) - now fixed to join on `Customer`/`BusinessPartner`
  instead, which are confirmed real keys on the associated view.


## Fourth pass - renamed to match org naming convention (module = FI)

The person shared their org's ABAP/CDS naming convention document. All objects renamed to fit
`Y<Prefix>_<Module>_<Name>` (or the service/service-binding specific pattern):

| Old name | New name |
|---|---|
| `YI_AROPITEM` | `YI_FI_AROPITEM` |
| `YI_ARCLEARINGAGG` | `YI_FI_ARCLRAGG` |
| `YI_ARAGING` | `YI_FI_ARAGING` |
| `YI_ARSALESPARTNER` | `YI_FI_ARSLSPTNR` |
| `YC_ARAGING` | `YC_FI_ARAGING` |
| `YC_ARAGING` (ddlx) | `YC_FI_ARAGING` (unchanged pattern - metadata extension name matches CDS name per convention) |
| `YC_ARAGING_SD` | `YUI_FI_ARAGING_SRV` (ServiceType=UI, no OData protocol suffix added yet - confirm O2/O4 with the person before service binding) |
| `YI_INVOICESTATUS_VH` | `YI_FI_INVSTATUS_VH` |
| `YI_AGINGCATEGORY_VH` | `YI_FI_AGINGCAT_VH` |
| `YCL_INVOICESTATUS_VH` | `YCL_FI_INVSTATUS_VH` |
| `YCL_AGINGCATEGORY_VH` | `YCL_FI_AGINGCAT_VH` |

Note: SQL view names (`@AbapCatalog.sqlViewName`) were left untouched - they follow a separate,
shorter convention and were not part of the renamed DDL entity names.

A real bug was caught and fixed during this rename: the `@ObjectModel.query.implementedBy`
annotation in both value-help custom entities was updated to the new class name, but the ABAP
class body itself was not automatically updated by the rename - this was manually corrected
(`ycl_invoicestatus_vh` -> `ycl_fi_invstatus_vh`, same pattern for aging category) to keep the
annotation and the actual class name in sync. This is the kind of mismatch that would only surface
as an activation error, not caught by casual review.

**Open item from this pass:** the naming convention doc's "Service Binding" row shows a required
`_<OData Protocol>` suffix (O2 or O4) that was not added, since the actual protocol choice (OData
V2 vs V4) has not been decided/confirmed. Confirm before creating the real service binding.

**Also flagged:** the convention document includes rows for Behavior Definition, Behavior Pool,
Handler Class, and Saver Class - all RAP transactional-BO patterns. This AR Aging report is
read-only/analytical, so none of these apply unless there's a transactional requirement (e.g.
manual status override) that hasn't been mentioned. Confirm this report stays read-only.

**Still unresolved (unrelated to this rename):** the `main` branch has 5 commits by a different
author ("HN") made after this repo's second push, touching the same core files. Those commits
have not been reviewed, merged, or compared against this work. This rename was applied only to
the `jayasai-dev-extensibility` branch.

## Fifth pass - real field names confirmed from ADT screenshot for YI_FI_ARCLRAGG

The person shared a photo of their actual ADT editor showing `I_OplAcctgDocItemClrgHist`'s real
field list (2026-07-03). This caught a real bug that would have failed at activation:

- The clearing history view's key fields that point back to the ORIGINAL invoice item are
  `ClearedCompanyCode`, `ClearedFiscalYear`, `ClearedAccountingDocument`,
  `ClearedAccountingDocumentItem` - NOT `CompanyCode`/`FiscalYear`/`AccountingDocument`/
  `AccountingDocumentItem` as the earlier draft assumed. The `Clearing*` prefixed fields
  (`ClearingCompanyCode`, `ClearingFiscalYear`, etc.) describe the CLEARING DOCUMENT itself,
  a different thing entirely.
- `YI_FI_ARCLRAGG` now groups by the correct `Cleared*` fields.
- Both `_ClearingHistory` and `_ClearingAgg` associations in `YI_FI_AROPITEM` updated to join on
  these corrected field names.
- `AmountInCompanyCodeCurrency` (used in the SUM) was already correct in the earlier draft - no
  change needed there.
- `@AccessControl.authorizationCheck: #NOT_REQUIRED` confirmed matching the person's real object
  (was `#CHECK` in the earlier draft - corrected to match).

NOTE (per userPreferences on this account): field names above are read from a photo of the
person's ADT screen, not independently verified by me against SAP documentation or a live system.
Small-text misreadings are possible - the person should visually confirm each field name against
their own screen before activating, especially before relying on this for a production transport.

## Sixth pass - major correction to Sales Partner Function (YI_FI_ARSLSPTNR)

The person shared a real ADT screenshot of `I_CustSalesPartnerFunc`'s actual key structure, which
revealed the earlier draft was not just missing verified field names but structurally WRONG:

- **Earlier (wrong) assumption:** the view was keyed by `SalesDocument`, joined to
  `AccountingDocument`, aggregated with `MIN(PartnerFunction) GROUP BY SalesDocument`.
- **Real structure (confirmed by screenshot):** keys are `Customer`, `SalesOrganization`,
  `DistributionChannel`, `Division`, `PartnerCounter`, `PartnerFunction` - this is Sales Area
  partner-function MASTER DATA (Customer x Sales Area x Partner Function), not document-level data
  at all. No `SalesDocument` field exists on this view.
- Confirmed by grep that `YI_FI_AROPITEM` has no Sales Area fields (`SalesOrganization`,
  `DistributionChannel`, `Division` do not exist on `I_OperationalAcctgDocCube`/Item) - consistent
  with FI-direct postings not carrying SD-specific Sales Area data.

**Fix applied, per the person's explicit instruction:** join on `Customer` only, ignoring Sales
Area (since it's unavailable at the FI-document level), and deterministically pick one
`PartnerFunction` per customer via `MIN()`.

**Known limitation of this fix, flagged honestly:** `MIN(PartnerFunction)` picks the
alphabetically-lowest partner function CODE, not necessarily the row with the lowest
`PartnerCounter` (SAP's own literal "first assigned" sequence). A true counter-based "first" would
need a correlated subquery or window function - not attempted, to avoid unverified activation risk
on a fourth structural change to this object. If exact counter-based ordering is required later,
this needs a follow-up fix.

**Business caveat, carried over from the original spec sheet:** Sales Name may be genuinely NULL
for FI-direct documents never linked to an SD sales order - this join does not manufacture data
that was never captured, and that's expected/correct behavior, not a bug.

## Seventh pass - recreated YY1_AR_BP_Group as a clean ADT/DDL object

Per the person's request, `YY1_AR_BP_Group` (originally built in the key-user Custom CDS View app)
has been recreated as `YI_FI_ARBPGROUP`, a proper ADT/DDL developer-extensibility object, so BP
Group logic lives in the same git-managed stack as everything else rather than depending on a
separate key-user object.

**Important limitation, flagged honestly:** this recreation is built ONLY from the 4 fields
confirmed via the person's ADT screenshot of the key-user view's Elements tab (`Customer`,
`BusinessPartner`, `BusinessPartnerGrouping` via `_BusinessPartner` association). The key-user
view's complete field list was never seen, so `YI_FI_ARBPGROUP` is not guaranteed to be a full
replica - it only covers what's needed for the current `BPGroupCode` use case in this report.

`YI_FI_AROPITEM`'s `_BPGroup` association now points to `YI_FI_ARBPGROUP` instead of
`YY1_AR_BP_Group`. The join condition itself is unchanged (both `Customer` and `BusinessPartner`
join to `Item.Customer`, per the person's earlier confirmation).

**Open item:** `YI_FI_ARBPGROUP` has not been activated yet - it needs to be activated before
`YI_FI_AROPITEM` will resolve correctly, since the association now points to it instead of the
(already-existing, already-published) key-user object.

## Eighth pass - removed unused _ClearingHistory association

`YI_FI_AROPITEM` had two clearing-related associations: `_ClearingAgg` (to our custom
`YI_FI_ARCLRAGG`, actively used for PaidAmount) and `_ClearingHistory` (a separate direct
association straight to the standard `I_OplAcctgDocItemClrgHist`, used only for one
commented-out field, `OriginalReferenceDocument`). Per the person's request, `_ClearingHistory`
has been removed to keep the file clean, since it wasn't feeding anything active into the report.
If `OriginalReferenceDocument` or another raw field from the standard clearing view is needed
later, this association would need to be re-added.

## Ninth pass - added missing selection fields (filters)

Compared the full original spec-sheet filter list against what was actually annotated with
`@UI.selectionField` in `YC_FI_ARAGING` - found 6 present, ~10 missing. Added:

- **BPGroupCode** - selection field + dropdown, now pointing at our recreated `YI_FI_ARBPGROUP`.
  NOT verified to activate cleanly - that object still has open field-name questions.
- **CompanyBranch, CustomerBranch, PaymentTermsCode** - selection fields added, NO dropdown (no
  verified value-help target exists for these).
- **GLAccount** - selection field + dropdown via `I_GLAccountInChartOfAccounts` - NOT verified
  released for Developer Extensibility in this system (we already hit one "not released" error on
  a different standard view, so this is a real risk, not just a formality).
- **JournalEntry** - selection field, no dropdown (document number, filterable as exact match/text).
- **SalesName** - selection field, no dropdown (derived from our own deterministic MIN-based view,
  not a stable master-data value help target).
- **AgingCategoryBilling** - was missing its selection field entirely; Invoice basis had one, Billing
  basis didn't. Now both match.

**Deliberately NOT added:** any filter on WBS/Project fields - `I_WBSElementBasicData` is confirmed
NOT released for Developer Extensibility (see earlier conversation), so adding a filter here would
be half-working UX at best. Left unfiltered until the WBS access question is resolved (see open
items: alternative released view via `I_EnterpriseProject`/`I_EnterpriseProjectElement`, per SAP
KBA 3587487 - not yet confirmed applicable to this scenario).

**Still not addressed:** date-range filtering (Invoice Date, Posting Date, Baseline Date, Actual
Billing Date, Key Date, Payment Date) - these exist as displayed fields but weren't given selection
field treatment in this pass, since date-range filters in Fiori Elements typically need different
UI treatment (range operators) than simple value-help dropdowns, and this wasn't explicitly
requested. Flag for a follow-up pass if date filtering is required.

## Tenth pass - restricted dropdowns to Invoice Status and Aging Category only

Per explicit instruction, removed `@Consumption.valueHelpDefinition` from `BPGroupCode`,
`GLAccount`, and `CustomerCode` - all three still remain as plain `@UI.selectionField` filters
(filterable via free text/exact match), just without a dropdown. Only `InvoiceStatus`,
`AgingCategoryInvoice`, and `AgingCategoryBilling` now have value help dropdowns - all three point
at our own custom, controlled objects (`YI_FI_INVSTATUS_VH`, `YI_FI_AGINGCAT_VH`), avoiding any
dependency on standard views whose Developer Extensibility release state we haven't verified
(relevant after the `I_WBSElementBasicData` "not released" error encountered earlier).

## abapGit pull setup - eleventh pass

Successfully validated the abapGit pull pattern on an isolated single-object test
(`abapgit-single-object-test` branch, `YI_FI_ARCLRAGG`). Two things were required, confirmed via
real ADT import log errors, not guessed:

1. **Lowercase filenames** - abapGit requires all filenames lowercase (`yi_fi_arclragg.ddls.asddls`,
   not `YI_FI_ARCLRAGG.ddls.asddls`). This was documented in abapGit's own docs, but missed on the
   first attempt - confirmed as the actual blocker via the real "File not found: yi_fi_arclragg.ddls.xml"
   error message.
2. **Per-object metadata XML** (`.ddls.xml`), plus root-level `.abapgit.xml`.

**Applied to this branch:** all 8 DDLS objects now have lowercase source files + metadata XML,
following the confirmed-working pattern. All non-DDLS source files (2 CLAS, 1 DDLX, 1 SRVD) have
been renamed lowercase too, but **do NOT yet have metadata XML** - I do not have verified example
schemas for those three object types (only fragments of abapGit's internal deserializer code, not
complete confirmed examples). Pulling right now would likely fail the same "file not found" way for
those 4 objects specifically.

**Recommended next step:** test pull with just the 8 DDLS objects first (the CLAS/DDLX/SRVD source
files can be temporarily excluded or ignored via abapGit's ignore-list), since those are now
following a validated pattern. Then tackle DDLX/CLAS/SRVD metadata format via the same
isolated-single-object-test approach that worked for DDLS, rather than guessing at the schema.

## Twelfth pass - CLAS metadata XML added

Found a genuinely well-verified schema this time - confirmed consistently across abapGit's own
official documentation AND a real class file from a well-known abapGit contributor's public repo
(`larshp/ABAP-Swagger`), both showing the identical `<VSEOCLASS>` structure. Higher confidence than
the DDLS schema guess, since two independent real sources agree exactly.

Added `ycl_fi_invstatus_vh.clas.xml` and `ycl_fi_agingcat_vh.clas.xml`, both lowercase, following
this confirmed structure (CLSNAME, LANGU, DESCRIPT, STATE=1, CLSCCINCL=X, FIXPT=X, UNICODE=X).

**Still missing:** DDLX (metadata extension) and SRVD (service definition) metadata XML - no
verified example found for either yet. These two object types remain the last gap before the full
repo is abapGit-pullable.

## Thirteenth pass - fixed CURR arithmetic error (confirmed via official SAP KBA)

Real activation error: "Data type CURR is not supported at this position, see long text" in
`YI_FI_ARAGING`. Found and confirmed via official SAP KBA 3392907 (S/4HANA Cloud Public Edition) -
exact match to our situation. Root cause: an element of type CURR requires a decimal shift/cast
before being used in expressions like CASE or COALESCE; a bare literal `0` mixed with a CURR field
in these contexts is not type-compatible and must be explicitly cast.

**Fixed 19 occurrences total:**
- 5 in `YI_FI_ARAGING`: every `coalesce( Item._ClearingAgg.PaidAmount, 0 )` changed to
  `coalesce( Item._ClearingAgg.PaidAmount, cast( 0 as abap.curr( 23, 2 ) ) )`.
- 14 in `YC_FI_ARAGING`: every aging bucket `CASE WHEN ... THEN RemainingAmount ELSE 0 END` changed
  to `... ELSE cast( 0 as abap.curr( 23, 2 ) ) END`.

Precision `(23, 2)` used based on the confirmed field type shown in the person's own earlier
screenshot of `InvoiceAmtInCoCodeCrcy CURR(23,2)` / `AmountInCompanyCodeCurrency CURR(23,2)` - not
guessed, but also not independently re-verified at the point of this fix; worth a quick sanity
check if activation still complains about precision specifically.
