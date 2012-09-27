public with sharing class SalesforceXeroInvoiceWrapper {
	public Opportunity masterOpportunity {get; set;}
	public XeroInvoiceModel xeroInvoice {get; set;}
	
	public SalesforceXeroInvoiceWrapper(XeroInvoiceModel invoice, Id OpportunityId) {
		xeroInvoice = invoice;
		masterOpportunity = new Opportunity(Id = opportunityId);
	}
}