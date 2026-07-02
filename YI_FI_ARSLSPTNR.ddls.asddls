@AbapCatalog.sqlViewName: 'YIARSLSPTNR'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - Sales Partner Function (Deterministic)'
@VDM.viewType: #BASIC
define view entity YI_FI_ARSLSPTNR
  as select from I_CustSalesPartnerFunc as Partner
  // MAJOR CORRECTION (2026-07-03): earlier draft assumed this view was keyed by
  // SalesDocument and joined to AccountingDocument - WRONG. Real keys, confirmed
  // by the person's ADT screenshot: Customer, SalesOrganization,
  // DistributionChannel, Division, PartnerCounter, PartnerFunction. This is
  // Sales Area partner-function MASTER DATA (Customer x Sales Area x Partner
  // Function), not document-level data.
  //
  // YI_FI_AROPITEM has NO Sales Area fields (SalesOrganization/
  // DistributionChannel/Division do not exist on I_OperationalAcctgDocCube/Item -
  // confirmed by grep against the current file, consistent with FI-direct
  // postings not carrying SD-specific Sales Area data).
  //
  // PRAGMATIC SIMPLIFICATION, per the person's explicit instruction: join on
  // Customer ONLY (ignoring Sales Area, since it is unavailable at this level),
  // and deterministically pick one PartnerFunction per customer using MIN().
  // NOTE: MIN(PartnerFunction) picks the alphabetically-lowest function CODE,
  // NOT necessarily the row with the lowest PartnerCounter (i.e. not
  // necessarily the literal "first assigned" partner in SAP's own sequence).
  // A true "lowest PartnerCounter, then read its function" would need a
  // correlated subquery or window function - not attempted here to avoid
  // unverified activation risk. If exact counter-based "first" is required,
  // flag this back for a follow-up fix.
  //
  // Business caveat carried over from the original spec sheet: Sales Name/
  // Partner Function may be genuinely NULL for FI-direct documents that were
  // never linked to an SD sales order - this join will not manufacture data
  // that was never captured.

{
  key Partner.Customer,

      min( Partner.PartnerFunction ) as PartnerFunction

}
group by
  Partner.Customer
