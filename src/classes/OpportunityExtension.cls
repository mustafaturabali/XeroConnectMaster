public with sharing class OpportunityExtension {
	public Id opportunityId;
	private Opportunity thisOpportunity;
	public List<XeroInvoiceModel> xeroInvoices {get; set;}
	public XeroInvoiceModelWrapper XeroSearchedInvoice {get; set;}	
	public List<XeroInvoiceModelWrapper> XeroInvoicesEditable {get; set;}
	public List<XeroInvoiceModelWrapper> XeroInvoiceSearchResults {get; set;}
	public string XeroInvoiceNumber {get; set;} 	
	private XeroInvoiceService invoiceService;
	public boolean InvoiceFound {get; set;}
	
	public OpportunityExtension(Apexpages.standardController cont) {
		opportunityId = cont.getId();
		if(opportunityId!=null) {
			List<Opportunity> lstOpp = [select id, name, accountid, account.Name from Opportunity where Id=: opportunityId];
			if(lstOpp.size()>0) {
				thisOpportunity = lstOpp[0];
			}
		}	
		invoiceService = new XeroInvoiceService();
	}
	public OpportunityExtension()
	{
		opportunityId = apexPages.currentPage().getParameters().get('id');
	}
	
	public void FetchInvoicesToAddFromXero() {
		system.debug('In invoice method :');
		List<XeroInvoiceModel> invoices = invoiceService.FetchInvoices(null, null, null, null);
		
		xeroInvoicesEditable = new List<XeroInvoiceModelWrapper>();
		
		Map<string, Set<Id>> xeroSFAccountIdMap = new Map<string, Set<Id>>();
		Map<string, Invoice__c> existingInvoices = new Map<string, Invoice__c>();
		
		for(Invoice__c i : [select Id, Name, Xero_Invoice_Id__c, Xero_Invoice_Number__c, Xero_Client_ID__c, Opportunity__r.AccountId 
							from Invoice__c 
							where Xero_Client_ID__c in : XeroInvoiceModel.ContactIds]) {
			if(xeroSFAccountIdMap.containskey(i.Xero_Client_ID__c)) {
				xeroSFAccountIdMap.get(i.Xero_Client_ID__c).add(i.Opportunity__r.AccountId);	
			}
			else {
				xeroSFAccountIdMap.put(i.Xero_Client_ID__c, new Set<Id>{i.Opportunity__r.AccountId});
			}
			
			existingInvoices.put(i.Xero_Invoice_Id__c, i);	
			system.debug('existing invoices :'+existingInvoices.size());			
		}
		
		
		/*loop all xero invoices
		for() {
			a) if invoice updated date within a week, add
			b) if invoice.contactName == opportunity.account.name, add
			c) if invoice.clientId found in SF invoices and current opportunity.account.name matches the found invoice.opportunity.account.name, add
		}
		*/
		
		for(XeroInvoiceModel inv : invoices) {
			if(!existingInvoices.containskey(inv.InvoiceId)) {				
				boolean isRecent = false;
				boolean isSimilarAccountName = false;
				boolean isOtherMatchingInvoices = false;
				if(inv.UpdatedDateUTC>=datetime.now().addDays(-1)) {
					isRecent = true;
				}
				if(inv.ContactName==thisOpportunity.Account.Name) {
					isSimilarAccountName = true;
				}
				if(xeroSFAccountIdMap.get(inv.ContactId)!=null && xeroSFAccountIdMap.get(inv.ContactId).contains(thisOpportunity.AccountId)) {
					isOtherMatchingInvoices = true;
				}
				
				if(isRecent || isSimilarAccountName || isOtherMatchingInvoices) {
					XeroInvoiceModelWrapper rec = new XeroInvoiceModelWrapper(inv);
					rec.IsRecent = isRecent;
					rec.IsSimilarAccountName = isSimilarAccountName;
					rec.IsOtherMatchingInvoices = isOtherMatchingInvoices;		
					
					xeroInvoicesEditable.add(rec);
				}
			}
		}
	}
		public void showNewXeroInvoices(){
		XeroInvoiceService obj = new XeroInvoiceService();
		xeroInvoicesEditable = new List<XeroInvoiceModelWrapper>();
		List<XeroInvoiceModel> xeroInvoicesUnFiltered = obj.FetchInvoices(null, null, null, 'DueDate');
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
	
	public void FindInvoiceByNumber() {
		XeroInvoiceSearchResults = new list<XeroInvoiceModelWrapper>();
		XeroInvoiceNumber = XeroInvoiceNumber==null?'':XeroInvoiceNumber.trim();
		if(XeroInvoiceNumber!='') {
			List<Invoice__c> invoiceList = [select Id, Xero_Invoice_Number__c, Opportunity__r.Name from Invoice__c where Xero_Invoice_Id__c =: XeroInvoiceNumber];
			if(invoiceList.size()>0) {
				Apexpages.addMessage(new Apexpages.message(Apexpages.severity.info, 'Invoice already exists in SF for supplied Invoice ID. See Invoice Number# '+invoiceList[0].Xero_Invoice_Number__c+' under Opportunity "'+invoiceList[0].Opportunity__r.Name+'"'));
				return;
			}
			XeroInvoiceModel invoice = invoiceService.FetchInvoice(XeroInvoiceNumber);
			if(invoice!=null) {
				XeroSearchedInvoice = new XeroInvoiceModelWrapper(invoice);
				XeroInvoiceSearchResults.add(XeroSearchedInvoice);
				InvoiceFound = true;
			} 
			else {
				Apexpages.addMessage(new Apexpages.message(Apexpages.severity.info, 'Invoice #'+XeroInvoiceNumber+' not found in Xero Invoice records'));
			}
		}
		else {
			Apexpages.addMessage(new Apexpages.message(Apexpages.severity.Error, 'Please provide a valid Xero Invoice Number'));	
		}
	}
	
	public pagereference SaveSearchedInvoice() {
		if(XeroSearchedInvoice!=null && XeroSearchedInvoice.IsSelected==true) {
			try {
				Invoice__c invoiceRecord = InvoiceController.CreateInvoiceRecordFromXero(XeroSearchedInvoice.InvoiceModel);
				invoiceRecord.Opportunity__c = this.opportunityId;
				insert invoiceRecord;
				InvoiceFound = false;
				XeroSearchedInvoice = null; 
				return new pagereference('/'+this.opportunityId);
			}
			catch(Exception ex) {
				Apexpages.addMessages(ex);
			}	
		}
		else {
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.error, 'No Search Result selected for saving'));
		}
		return null;
	}
	
	public pagereference SaveSelectedInvoices() {
		Savepoint sp = database.setSavePoint();
		List<Invoice__c> lstInvoices = new List<Invoice__c>();
		
		try {
			for(XeroInvoiceModelWrapper inv : xeroInvoicesEditable) {
				if(inv.IsSelected) {
					Invoice__c invoiceRecord = InvoiceController.CreateInvoiceRecordFromXero(inv.InvoiceModel);
					invoiceRecord.Opportunity__c = this.opportunityId;
					lstInvoices.add(invoiceRecord);
				}
			}	
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
	
	public pagereference GotoNewInvoicePage() {
		Apexpages.standardController con = new Apexpages.Standardcontroller(new Invoice__c());
		return con.edit();
	}
	
	public pagereference GotoAddNewInvoicesPage() {
		return new Pagereference('/apex/InvoicesAddFromXero?id='+opportunityId);
	}
	
	public pagereference GotoRecommendedInvoicesPage() {
		return new Pagereference('/apex/InvoicesAddFromXeroNew?id='+opportunityId);
	}
}