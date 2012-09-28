public with sharing class XeroInvoiceService {
    public string message {get; private set;}
    public integer statusCode {get; private set;}
    public string status {get; private set;}
    public string responseBody {get; private set;}
    public boolean success {get; private set;}
    //public Xero_Service__c service;
     
    public XeroInvoiceModel FetchInvoice(string InvoiceNumber) {
        List<XeroInvoiceModel> invoices = this.FetchInvoices(InvoiceNumber, null, null, null);
        if(invoices.size()>0) {
            return invoices[0];
        }
        return null;
    }
    
    public static HttpRequest CreateRequest(string optFilter, datetime optModifiedSinceGMT, string optWhereFilter, string optOrderBy) {
        Xero_App_Config__c XeroAppConfig = Xero_App_Config__c.getOrgDefaults();
        
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        string url = XeroAppConfig.API_Endpoint_URL__c+'invoices';
        
        string separator = '?';
        if(optFilter!=null) {
            url += '/'+optFilter;
        }
        else if(optWhereFilter!=null) {
            url += '?where='+EncodingUtil.urlEncode(optWhereFilter, 'UTF-8');
            separator = '&';
        }
        
        if(optModifiedSinceGMT!=null) {
            req.setHeader('If-Modified-Since', optModifiedSinceGMT.format('EEE, dd MMM yyyy HH:mm:ss GMT'));
        }
        
        if(optOrderBy!=null) {
            url += separator+'order='+optFilter;
        }
        
        req.setEndpoint(url);
        system.debug('our Request ::'+req);
        return req;
    }
    
    public void FetchResponse(HttpRequest req) {
        Http h = new Http();
        system.debug(LoggingLevel.DEBUG,'our request :'+req);
        HttpResponse res = h.send(req);

        status = res.getStatus();
        statusCode = res.getStatusCode();
        responseBody = res.getBody();
    }
    
    public List<XeroInvoiceModel> FetchInvoices(string optFilter, datetime optModifiedSinceGMT, string optWhereFilter, string optOrderBy) {
        
        HttpRequest req = XeroInvoiceService.CreateRequest(optFilter, optModifiedSinceGMT, optWhereFilter, optOrderBy);
        this.SignRequest(req);
        this.FetchResponse(req);
                
        if(this.statusCode!=200) {
            success = false;
            return new List<XeroInvoiceModel>();            
        }
        
        List<XeroInvoiceModel> invoices = XeroInvoiceModel.parse(this.responseBody);
        return invoices;
    }
    
    //private static Xero_Service__c FetchPrivateApplicationSettings() {
    //    List<Xero_Service__c> lst = [Select x.Request_Token_URL__c, x.PKCS_Private_Key__c, x.Name, 
    //            x.Id, x.Consumer_Secret__c, x.Consumer_Key__c, x.Authorisation_URL__c, 
    //            x.Application_Type__c, x.Access_Token_URL__c, x.API_Endpoint_URL__c 
    //            From Xero_Service__c x
    //            Where Name= 'Test'];
    //    if(lst.size()>0) {
    //        return lst[0];
    //    }       
    //    return null;
    //}
    
    private void SignRequest(HttpRequest req) {
        //service = FetchPrivateApplicationSettings();
        //if(service==null) {
        //throw new CustomException('Xero Private Application settings not found');
        //}
        
        OAuthRequest oa = new OAuthRequest();
     //   oa.setService(service);
       // oa.signRSA(req);
        oa.signRSANew(req);
    }
    
    
}