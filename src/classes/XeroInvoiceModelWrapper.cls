public class XeroInvoiceModelWrapper {
	public XeroInvoiceModel InvoiceModel {get; set;}
	public boolean IsRecent {get; set;}
	public boolean IsSimilarAccountName {get; set;}
	public boolean IsOtherMatchingInvoices {get; set;}
	public boolean IsSelected {get; set;}
	
	public XeroInvoiceModelWrapper(XeroInvoiceModel inv) {
		this.InvoiceModel = inv;
	} 
}