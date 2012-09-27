public  class XeroAppConfigController {
	public Xero_App_Config__c xeroApp {get;set;}
	public XeroAppConfigController()
	{
		xeroApp = Xero_App_Config__c.getOrgDefaults();
	}
	public void updateConfig()
	{
	//	try
		//{
			update xeroApp;
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info,'Updated Successfully '));
		//}
		//catch(DmlException e)
		//{
		//	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Fatal,'No source id defined in URL '));
		//}
	}

}