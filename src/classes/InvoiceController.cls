public class InvoiceController {
	//private Id opportunityId;
	public List<Invoice__c> invoiceRecords {get; set;}
	public string OpportunityName {get;set;}
	public Id OpportunityId {get;set;}
	private string redirectTo;
	public List<XeroInvoiceModel> xeroInvoices {get; set;}
	public List<XeroInvoiceModelWrapper> xeroInvoicesEditable {get; set;}
	
	public InvoiceController(Apexpages.standardcontroller cont) {
		Id InvoiceId = cont.getId();
		this.opportunityId = apexPages.currentPage().getParameters().get('id');
		invoiceRecords = [select Id, Opportunity__c, Name, Total__c, Xero_Invoice_Id__c, Xero_Invoice_Number__c from Invoice__c where id=:invoiceId];
		redirectTo = apexpages.currentPage().getParameters().get('retURL');
		if(redirectTo==null) {
			redirectTo = '/'+invoiceId;
		}
	}
	
	public InvoiceController() {
		redirectTo = apexpages.currentPage().getParameters().get('retURL');		
		this.opportunityId = apexPages.currentPage().getParameters().get('id');
	}
	
	public InvoiceController(Apexpages.standardSetController cont) {
		invoiceRecords = [select Id, Opportunity__c, Name, Total__c, Xero_Invoice_Id__c, Xero_Invoice_Number__c from Invoice__c where id in : cont.getSelected()];
		redirectTo = apexpages.currentPage().getParameters().get('retURL');		
	} 
	
	public XeroInvoiceModel FetchInvoiceDetails(string invoiceNumber) {
		XeroInvoiceService obj = new XeroInvoiceService();
		XeroInvoiceModel invoice = obj.FetchInvoice(invoiceNumber);
		return invoice;
	}
	
	public pagereference UpdateInvoiceDetails() {
		if(invoiceRecords.size()>0) {
			integer cnt = 0;
			for(Invoice__c invoiceRecord : invoiceRecords) {
				if(invoiceRecord.Id!=null) {
					XeroInvoiceModel invoice = this.FetchInvoiceDetails(invoiceRecord.Xero_Invoice_Number__c);
					if(invoice!=null) {
						invoiceRecord.Total__c = invoice.Total;
						invoiceRecord.Xero_Invoice_Id__c = invoice.InvoiceID;
						invoiceRecord.Amount_Due__c = invoice.AmountDue;
						invoiceRecord.Amount_Paid__c = invoice.AmountPaid;
						invoiceRecord.Currency_Code__c = invoice.CurrencyCode;
						invoiceRecord.Invoice_Date__c = invoice.InvoiceDate;
						invoiceRecord.Due_Date__c = invoice.DueDate;
						invoiceRecord.Status__c = invoice.Status;
						invoiceRecord.Sub_Total__c = invoice.SubTotal;
						invoiceRecord.Total_Tax__c = invoice.TotalTax;
						invoiceRecord.Xero_Client_ID__c = invoice.ContactID;
						invoiceRecord.Xero_Invoice_Number__c = invoice.InvoiceNumber;
						cnt++;
					}
					else {
						Apexpages.addMessage(new apexpages.message(apexpages.severity.info, 'No Invoice record found in Xero for Invoice Number: '+invoiceRecord.Xero_Invoice_Number__c));
						//return null;
					}
				}	
				if(cnt==10) {
					break;
				}
			}	
			update invoiceRecords;
			
			if(redirectTo==null) {
				redirectTo = '/'+invoiceRecords[0].Opportunity__c;
			}
			return new pagereference(redirectTo);
		}
		else {
			Apexpages.addMessage(new apexpages.message(apexpages.severity.info, 'No Invoice record selected for update'));
		}
		return null;
	}
	
	public void showNewXeroInvoices(){
		XeroInvoiceService obj = new XeroInvoiceService();
		xeroInvoicesEditable = new List<XeroInvoiceModelWrapper>();
		List<XeroInvoiceModel> xeroInvoicesUnFiltered = obj.FetchInvoices(null, null, null, null);
		if(obj.success==false) {
			apexpages.addMessage(new apexpages.Message(apexpages.severity.error, obj.message));
			return;		
		}
		else if(xeroInvoicesUnFiltered.size()==0) {
			apexpages.addMessage(new apexpages.Message(apexpages.severity.info, 'No invoices found in Xero'));
			return;
		} 
		
		Map<string, XeroInvoiceModel> invoiceMap = new Map<string, XeroInvoiceModel>();
		for(XeroInvoiceModel invoice : xeroInvoicesUnFiltered) {
			invoiceMap.put(invoice.InvoiceId, invoice);	
		}
		
		for(Invoice__c i : [Select i.Xero_Invoice_Number__c, i.Xero_Invoice_Id__c, i.Total__c, i.Total_Tax__c, i.Sub_Total__c, i.Status__c, i.Opportunity__c, i.Name, i.Invoice_Date__c, i.Id, i.Due_Date__c, i.Currency_Code__c, i.Amount_Paid__c, i.Amount_Due__c From Invoice__c i Where Xero_Invoice_Id__c in : invoiceMap.keyset()]) {
			invoiceMap.remove(i.Xero_Invoice_Id__c);
		}
		//system.debug('Size :'+invoiceMap.values());
		xeroInvoices = invoiceMap.values();
	//	system.debug('Size :'+xeroInvoices.size());
			
			for(XeroInvoiceModel inv:xeroInvoices)
			{
				XeroInvoiceModelWrapper rec = new XeroInvoiceModelWrapper(inv);
				xeroInvoicesEditable.add(rec);
			}
		
		
		
	}
		public pagereference SaveSelectedInvoices() {
		Savepoint sp = database.setSavePoint();
		List<Invoice__c> lstInvoices = new List<Invoice__c>();
		
		try {
			for(XeroInvoiceModelWrapper inv : xeroInvoicesEditable) {
				if(inv.IsSelected) {
					Invoice__c invoiceRecord = CreateInvoiceRecordFromXero(inv.InvoiceModel);
					invoiceRecord.Opportunity__c = this.OpportunityId;
					lstInvoices.add(invoiceRecord);
				}
			}
			//system.debug('Opportunity :'+this.lstInvoices.size());
			system.debug('Opportunity :'+this.OpportunityId);	
			if(lstInvoices.size()>0) {
				insert lstInvoices;
			}
			return new pagereference('/'+this.opportunityId);
		}
		
		catch(Exception ex) {
			database.rollback(sp);
			return null;
		}
	}
	
	public static Invoice__c CreateInvoiceRecordFromXero(XeroInvoiceModel invoice) {
		Invoice__c invoiceRecord = new Invoice__c();		
		invoiceRecord.Total__c = invoice.Total;
		invoiceRecord.Xero_Invoice_Id__c = invoice.InvoiceID;
		invoiceRecord.Amount_Due__c = invoice.AmountDue;
		invoiceRecord.Amount_Paid__c = invoice.AmountPaid;
		invoiceRecord.Currency_Code__c = invoice.CurrencyCode;
		invoiceRecord.Invoice_Date__c = invoice.InvoiceDate;
		invoiceRecord.Due_Date__c = invoice.DueDate;
		invoiceRecord.Status__c = invoice.Status;
		invoiceRecord.Sub_Total__c = invoice.SubTotal;
		invoiceRecord.Total_Tax__c = invoice.TotalTax;
		invoiceRecord.Xero_Client_ID__c = invoice.ContactID;
		invoiceRecord.Xero_Invoice_Number__c = invoice.InvoiceNumber;
		return invoiceRecord;
	}
}