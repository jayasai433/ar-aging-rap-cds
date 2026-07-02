@AbapCatalog.sqlViewName: 'YIARBPGROUP'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'AR Aging - BP Grouping (Interface)'
@VDM.viewType: #BASIC
define view entity YI_FI_ARBPGROUP
  as select from I_BusinessPartnerCustomer as BPCust
  // Recreation of the key-user Custom CDS View 'YY1_AR_BP_Group' as a proper
  // ADT/DDL developer-extensibility object, per the person's request to keep
  // this in the same managed stack as the other YI_FI_* objects.
  //
  // IMPORTANT LIMITATION: this is built ONLY from the 4 fields confirmed via
  // the person's ADT screenshot of the key-user view's Elements tab (Customer,
  // BusinessPartner, BusinessPartnerGrouping, _BusinessPartner association).
  // I never saw that view's complete field list, so this is not guaranteed to
  // be a full replica - only the fields needed for our current BP Group use
  // case (BPGroupCode) are included.

  association [0..1] to I_BusinessPartner as _BusinessPartner
    on $projection.BusinessPartner = _BusinessPartner.BusinessPartner

{
  key BPCust.Customer,
  key BPCust.BusinessPartner,

      _BusinessPartner.BusinessPartnerGrouping as BusinessPartnerGrouping,

      _BusinessPartner
}
