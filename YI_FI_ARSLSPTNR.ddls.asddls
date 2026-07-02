@AbapCatalog.sqlViewName: 'YIARSALESPTNR'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'AR Aging - Sales Partner Function (Deterministic, Interface)'
@VDM.viewType: #BASIC
define view entity YI_FI_ARSLSPTNR
  as select from I_CustSalesPartnerFunc as Partner
  // NOTE: SalesDocument as the join key to AccountingDocument is carried over
  // from the original spec sheet only - NOT independently verified against
  // this view's real key structure. Confirm in ADT before activation; the
  // real key fields may differ (e.g. could require SalesDocumentItem too).

{
  key Partner.SalesDocument,

      // Deterministic pick: MIN() guarantees the same result on every run,
      // rather than depending on undefined SQL row order. This avoids the
      // fan-out risk from joining without the full key set (multiple partner
      // functions per document), per your instruction to take "whichever
      // comes first" - MIN() is the safe, repeatable way to define "first."
      min( Partner.PartnerFunction ) as PartnerFunction

}
group by
  Partner.SalesDocument
