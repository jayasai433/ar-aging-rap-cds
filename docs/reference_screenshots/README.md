# Reference Screenshots

Original source images shared during this build, preserved here so field/logic decisions can be
re-verified against the actual evidence instead of relying on transcribed notes later in the
conversation. (This should have been done from the start - added retroactively per feedback.)

## Original spec sheet (Excel)
- `01_spec_filters_1.jpg`, `02_spec_filters_2.jpg` - filter/selection screen fields
- `03_spec_fields_A.jpg` through `07_spec_fields_E.jpg` - full field mapping, source CDS view
  technical names, and calculation logic notes (aging buckets, DSO, dates)

## ADT field verification
- `08_adt_datasources.jpg` - the person's real published Custom CDS View, Data Sources tab
- `09_adt_elements_1.jpg`, `10_adt_elements_2.jpg` - real Elements list (confirmed field names:
  NetDueDate, NetPaymentDays, YY1_ActualBillingDate_JEI, etc.)
- `11_adt_bpgroup_join.jpg` - YY1_AR_BP_Group's real join condition (Customer/BusinessPartner ->
  Item.Customer)
- `12_adt_bpgroup_elements.jpg` - YY1_AR_BP_Group's element list (built on
  I_BusinessPartnerCustomer)

## Naming convention
- `13_naming_convention_1.jpg`, `14_naming_convention_2.jpg` - org's ABAP/CDS naming convention
  document (source of the YI_FI_*/YC_FI_* renaming pass)

## YI_FI_ARCLRAGG development
- `15_arclragg_source_fields.jpg`, `16_arclragg_source_fields_2.jpg` - real field list of
  I_OplAcctgDocItemClrgHist (Cleared* vs Clearing* fields - source of the major key-field
  correction)
- `17_currency_error.jpg` - the PAIDAMOUNT missing-CUKY-reference activation error and its fix

## YI_FI_AROPITEM development
- `18_aropitem_customer_error.jpg` - the $projection.Customer "obscured by alias" error
- `19_aropitem_wbs_error.jpg`, `20_wbs_error_detail.jpg` - the I_WBSElementBasicData
  "not released for Developer Extensibility" error (still unresolved - see main README)

## Environment/authorization
- `21_customizing_client_auth_error.jpg` - "No authorization to view data" error specific to the
  Customizing client (100), not reproducible in Dev client (080) - landscape issue, not a code bug

---

**Note on completeness:** these are the images shared in this conversation up to the point this
index was created. If more screenshots are shared later, they should be added here too, following
the same numbering/naming pattern, to keep this an accurate running record.
