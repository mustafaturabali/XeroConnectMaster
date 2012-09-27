public with sharing class XeroInvoiceModel {	
	public datetime InvoiceDate {get; private set;}
	public datetime DueDate {get; private set;}
	public string Status {get; private set;}
	public string LineAmountTypes {get; private set;}
	public decimal SubTotal {get; private set;}
	public decimal TotalTax {get; private set;}
	public decimal Total {get; private set;}
	public datetime UpdatedDateUTC {get; private set;}
	public string CurrencyCode {get; private set;}
	public string Type {get; private set;}
	public string InvoiceID {get; private set;}
	public string InvoiceNumber {get; private set;}
	public decimal AmountDue {get; private set;}
	public decimal AmountPaid {get; private set;}
	public boolean SentToContact {get; private set;}
	public decimal CurrencyRate {get; private set;}
	public boolean HasAttachments {get; private set;}
	public string ContactID {get; set;}
	public string ContactName {get; set;}
	
	public string InvoiceDateString {
		get {
			return InvoiceDate!=null?InvoiceDate.Date().format():'';
		}
	}
	
	public string DueDateString {
		get {
			return DueDate!=null?DueDate.Date().format():'';
		}
	}
	
	public static set<string> ContactIds {get; private set;}
	
	public void loadFromXml(dom.XmlNode invoiceNode) {
		for(dom.XmlNode node : invoiceNode.getChildElements()) {
		  	if(node.getName()=='Date') {
		    	this.InvoiceDate = datetime.valueOfGmt(node.getText().replace('T',' '));
		   	}
		   	else if(node.getName()=='DueDate') {
		    	this.DueDate = datetime.valueOfGmt(node.getText().replace('T',' '));
		   	}
		   	else if(node.getName()=='Status') {
		    	this.Status = node.getText();
		   	}
		   	else if(node.getName()=='LineAmountTypes') {
		    	this.LineAmountTypes = node.getText();
		   	}
		   	else if(node.getName()=='SubTotal') {
		    	this.SubTotal = decimal.valueOf(node.getText());
		   	}
		   	else if(node.getName()=='TotalTax') {
		    	this.TotalTax = decimal.valueOf(node.getText());
		   	}
		   	else if(node.getName()=='Total') {
		    	this.Total = decimal.valueOf(node.getText());
		   	}
		   	else if(node.getName()=='UpdatedDateUTC') {
		    	this.UpdatedDateUTC = datetime.valueOfGmt(node.getText().replace('T',' '));
		   	}
		   	else if(node.getName()=='CurrencyCode') {
		    	this.CurrencyCode = node.getText();
		   	}
		   	else if(node.getName()=='Type') {
		    	this.Type = node.getText();
		   	}
		   	else if(node.getName()=='InvoiceID') {
		    	this.InvoiceID = node.getText();
		   	}
		   	else if(node.getName()=='InvoiceNumber') {
		    	this.InvoiceNumber = node.getText();
		   	}
		   	else if(node.getName()=='AmountDue') {
		    	this.AmountDue = decimal.valueof(node.getText());
		   	}
		   	else if(node.getName()=='AmountPaid') {
		    	this.AmountPaid = decimal.valueof(node.getText());
		   	}
		   	else if(node.getName()=='SentToContact') {
		    	this.SentToContact = boolean.valueof(node.getText());
		   	}
		   	else if(node.getName()=='CurrencyRate') {
		    	this.CurrencyRate = decimal.valueof(node.getText());
		   	}
		   	else if(node.getName()=='HasAttachments') {
		    	this.HasAttachments = boolean.valueof(node.getText());
		   	}
		   	else if(node.getName()=='Contact')
		   	{
		   		for(dom.XmlNode contactElement : node.getChildElements())
		   		{
		   			if(contactElement.getName()=='Name')
		   			{
		   				this.ContactName = contactElement.getText();
		   			}
		   			else if(contactElement.getName()=='ContactID')
		   			{
		   				this.ContactID = contactElement.getText();
		   			}
		   		}
		   	}
		}	
	}
	
	private static Dom.Xmlnode GetInvoicesRoot(string xml) {
		dom.Document doc = new dom.Document();
		doc.load(xml);		
		dom.Xmlnode invoicesRoot;
		for(dom.XmlNode node : doc.getRootElement().getChildElements()) {
			system.debug('node name: '+node.getName());
			if(node.getName()=='Invoices') {
				invoicesRoot = node;
				break;
			}
		}
		return invoicesRoot;
	}
	
	public static List<XeroInvoiceModel> Parse(string xml) {
		dom.Xmlnode invoicesRoot = GetInvoicesRoot(xml);
		List<XeroInvoiceModel> invoices = new List<XeroInvoiceModel>();
		if(invoicesRoot != null) {
			ContactIds = new set<string>();
			for(dom.XmlNode node : invoicesRoot.getChildElements()) {
				system.debug('node name: '+node.getName());
				if(node.getName()=='Invoice') {
					XeroInvoiceModel iv = new XeroInvoiceModel();
					iv.loadFromXml(node);
					invoices.add(iv);
					contactIds.add(iv.ContactId);
				}
			}
		}
		
		return invoices;
	}
	
	public static Map<string, List<XeroInvoiceModel>> ParseInvoicesByContactIds(string xml) {
		dom.Xmlnode invoicesRoot = GetInvoicesRoot(xml);
		Map<string, List<XeroInvoiceModel>> invoices = new Map<string, List<XeroInvoiceModel>>();
		if(invoicesRoot != null) {
			for(dom.XmlNode node : invoicesRoot.getChildElements()) {
				system.debug('node name: '+node.getName());
				if(node.getName()=='Invoice') {
					XeroInvoiceModel iv = new XeroInvoiceModel();
					iv.loadFromXml(node);
					//invoices.add(iv);
					if(invoices.containskey(iv.ContactId)) {
						invoices.get(iv.ContactId).add(iv);
					}
					else {
						invoices.put(iv.ContactId, new List<XeroInvoiceModel>{iv});
					}
				}
			}
		}
		
		return invoices;
	}
	
	private static testmethod void Test_XeroInvoiceModel() {
		string testXml = '<Response xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Id>e62e5bef-0deb-47eb-819c-255a82511b73</Id><Status>OK</Status><ProviderName>Mustafa Xero Connect</ProviderName><DateTimeUTC>2012-07-20T09:56:21.067186Z</DateTimeUTC><Invoices><Invoice><Contact><ContactID>dec56ceb-65e9-43b3-ac98-7fe09eb37e31</ContactID><ContactStatus>ACTIVE</ContactStatus><Name>PowerDirect</Name><BankAccountDetails>30-20-10 102030405</BankAccountDetails><AccountsPayableTaxType>RRINPUT</AccountsPayableTaxType><Addresses><Address><AddressType>STREET</AddressType></Address><Address><AddressType>POBOX</AddressType><AddressLine1>P O Box 8900</AddressLine1><AddressLine2>Central Mailing Centre</AddressLine2><City>Oaktown</City><PostalCode>OK12 8TN</PostalCode></Address></Addresses><Phones><Phone><PhoneType>MOBILE</PhoneType></Phone><Phone><PhoneType>DDI</PhoneType></Phone><Phone><PhoneType>FAX</PhoneType><PhoneNumber>887613</PhoneNumber><PhoneAreaCode>800</PhoneAreaCode></Phone><Phone><PhoneType>DEFAULT</PhoneType><PhoneNumber>887612</PhoneNumber><PhoneAreaCode>800</PhoneAreaCode></Phone></Phones><UpdatedDateUTC>2012-07-07T00:07:36.883</UpdatedDateUTC><IsSupplier>true</IsSupplier><IsCustomer>false</IsCustomer></Contact><Date>2012-07-06T00:00:00</Date><DueDate>2012-07-16T00:00:00</DueDate><Status>AUTHORISED</Status><LineAmountTypes>Inclusive</LineAmountTypes><LineItems><LineItem><Description>Monthly electricity</Description><UnitAmount>108.60</UnitAmount><TaxType>RRINPUT</TaxType><TaxAmount>5.17</TaxAmount><LineAmount>108.60</LineAmount><AccountCode>445</AccountCode><Quantity>1.0000</Quantity></LineItem></LineItems><SubTotal>103.43</SubTotal><TotalTax>5.17</TotalTax><Total>108.60</Total><UpdatedDateUTC>2011-04-04T00:19:05.573</UpdatedDateUTC><CurrencyCode>GBP</CurrencyCode><Type>ACCPAY</Type><InvoiceID>2175c381-d323-4e20-8c94-7680ea7f85d3</InvoiceID><InvoiceNumber>RPT445-1</InvoiceNumber><AmountDue>108.60</AmountDue><AmountPaid>0.00</AmountPaid><SentToContact>false</SentToContact><CurrencyRate>1.000000</CurrencyRate><HasAttachments>false</HasAttachments></Invoice><Invoice><Contact><ContactID>dec56ceb-65e9-43b3-ac98-7fe09eb37e31</ContactID><ContactStatus>ACTIVE</ContactStatus><Name>PowerDirect</Name><BankAccountDetails>30-20-10 102030405</BankAccountDetails><AccountsPayableTaxType>RRINPUT</AccountsPayableTaxType><Addresses><Address><AddressType>STREET</AddressType></Address><Address><AddressType>POBOX</AddressType><AddressLine1>P O Box 8900</AddressLine1><AddressLine2>Central Mailing Centre</AddressLine2><City>Oaktown</City><PostalCode>OK12 8TN</PostalCode></Address></Addresses><Phones><Phone><PhoneType>MOBILE</PhoneType></Phone><Phone><PhoneType>DDI</PhoneType></Phone><Phone><PhoneType>FAX</PhoneType><PhoneNumber>887613</PhoneNumber><PhoneAreaCode>800</PhoneAreaCode></Phone><Phone><PhoneType>DEFAULT</PhoneType><PhoneNumber>887612</PhoneNumber><PhoneAreaCode>800</PhoneAreaCode></Phone></Phones><UpdatedDateUTC>2012-07-07T00:07:36.883</UpdatedDateUTC><IsSupplier>true</IsSupplier><IsCustomer>false</IsCustomer></Contact><Date>2012-07-06T00:00:00</Date><DueDate>2012-07-16T00:00:00</DueDate><Status>AUTHORISED</Status><LineAmountTypes>Inclusive</LineAmountTypes><LineItems><LineItem><Description>Monthly electricity</Description><UnitAmount>108.60</UnitAmount><TaxType>RRINPUT</TaxType><TaxAmount>5.17</TaxAmount><LineAmount>108.60</LineAmount><AccountCode>445</AccountCode><Quantity>1.0000</Quantity></LineItem></LineItems><SubTotal>103.43</SubTotal><TotalTax>5.17</TotalTax><Total>108.60</Total><UpdatedDateUTC>2011-04-04T00:19:05.573</UpdatedDateUTC><CurrencyCode>GBP</CurrencyCode><Type>ACCPAY</Type><InvoiceID>2175c381-d323-4e20-8c94-7680ea7f85d3</InvoiceID><InvoiceNumber>RPT445-1</InvoiceNumber><AmountDue>108.60</AmountDue><AmountPaid>0.00</AmountPaid><SentToContact>false</SentToContact><CurrencyRate>1.000000</CurrencyRate><HasAttachments>false</HasAttachments></Invoice><Invoice><Contact><ContactID>dec56ceb-65e9-43b3-ac98-7fe09eb37e31</ContactID><ContactStatus>ACTIVE</ContactStatus><Name>PowerDirect</Name><BankAccountDetails>30-20-10 102030405</BankAccountDetails><AccountsPayableTaxType>RRINPUT</AccountsPayableTaxType><Addresses><Address><AddressType>STREET</AddressType></Address><Address><AddressType>POBOX</AddressType><AddressLine1>P O Box 8900</AddressLine1><AddressLine2>Central Mailing Centre</AddressLine2><City>Oaktown</City><PostalCode>OK12 8TN</PostalCode></Address></Addresses><Phones><Phone><PhoneType>MOBILE</PhoneType></Phone><Phone><PhoneType>DDI</PhoneType></Phone><Phone><PhoneType>FAX</PhoneType><PhoneNumber>887613</PhoneNumber><PhoneAreaCode>800</PhoneAreaCode></Phone><Phone><PhoneType>DEFAULT</PhoneType><PhoneNumber>887612</PhoneNumber><PhoneAreaCode>800</PhoneAreaCode></Phone></Phones><UpdatedDateUTC>2012-07-07T00:07:36.883</UpdatedDateUTC><IsSupplier>true</IsSupplier><IsCustomer>false</IsCustomer></Contact><Date>2012-07-06T00:00:00</Date><DueDate>2012-07-16T00:00:00</DueDate><Status>AUTHORISED</Status><LineAmountTypes>Inclusive</LineAmountTypes><LineItems><LineItem><Description>Monthly electricity</Description><UnitAmount>108.60</UnitAmount><TaxType>RRINPUT</TaxType><TaxAmount>5.17</TaxAmount><LineAmount>108.60</LineAmount><AccountCode>445</AccountCode><Quantity>1.0000</Quantity></LineItem></LineItems><SubTotal>103.43</SubTotal><TotalTax>5.17</TotalTax><Total>108.60</Total><UpdatedDateUTC>2011-04-04T00:19:05.573</UpdatedDateUTC><CurrencyCode>GBP</CurrencyCode><Type>ACCPAY</Type><InvoiceID>2175c381-d323-4e20-8c94-7680ea7f85d3</InvoiceID><InvoiceNumber>RPT445-1</InvoiceNumber><AmountDue>108.60</AmountDue><AmountPaid>0.00</AmountPaid><SentToContact>false</SentToContact><CurrencyRate>1.000000</CurrencyRate><HasAttachments>false</HasAttachments></Invoice></Invoices></Response>';
		List<XeroInvoiceModel> invoices = XeroInvoiceModel.parse(testXml);
	}	
}