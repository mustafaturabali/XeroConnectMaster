public class XeroTestController {

	private Xero_Saved_URL__c selectedSavedURLObj;
	private Xero_Service__c serviceRecord;
    public String body { get; set; }
    public String method { get; set; }
    public String postParam { get; set; }
    public String url { get; set; }

    public String message { get; set; }
    
    public List<SelectOption> methodList { 
    	get {
    		if(methodList==null) {
    			methodList = new List<SelectOption>();
    			methodList.add(new SelectOption('GET','GET'));    			
    			methodList.add(new SelectOption('POST','POST'));
    			methodList.add(new SelectOption('PUT','PUT'));
    		}
    		return methodList;
    	}
    	set;
    }
    private Map<String,Xero_Service__c> xeroServices {
    	get {
    		if(xeroServices==null) {
    			xeroServices = new Map<String,Xero_Service__c>(); 
    			for(Xero_Service__c o : 
    					[SELECT Name, Application_Type__c, Consumer_Key__c, Consumer_Secret__c, PKCS_Private_Key__c,
    					 (SELECT id, URL__c, Body__c, Is_Form_URL_Encoded__c, Method__c FROM Xero_Saved_URLs__r) 
    					 FROM Xero_Service__c]) {
    				xeroServices.put(o.Name,o);
    			}
    		}
    		return xeroServices;
    	}
    	set;
    }

    public String selectedService { 
    	get {
    		if(selectedService==null && xeroServices.size()>0) {
    			selectedService = xeroServices.values()[0].name;
    			serviceRecord = xeroServices.values()[0];
    		}
    		return selectedService;
    	}
    	set; 
    }

    public List<SelectOption> services {
        get {
            services = new List<SelectOption>();
	        for(Xero_Service__c obj : xeroServices.values()) {
                services.add(new SelectOption(obj.name,obj.name));
            }
            return services;
        }
        set;
    }
    
    public String selectedSavedURL { 
    	get {
    		if(selectedSavedURLObj==null && xeroServices.get(selectedService).Xero_Saved_URLs__r.size()>0) {
    			selectedSavedURLObj = xeroServices.get(selectedService).Xero_Saved_URLs__r[0];
    		}
    		return selectedSavedURLObj!=null ? selectedSavedURLObj.id : null;
    	} 
    	set {
			for(Xero_Saved_URL__c u : xeroServices.get(selectedService).Xero_Saved_URLs__r) {
				if(u.id == value) {
					selectedSavedURLObj = u;
				}
			}
    	} 
    }

    public List<SelectOption> savedURLs {
    	get {
    		List<SelectOption> l = new List<SelectOption>();
    		if(selectedService!=null) {
    			for(Xero_Saved_URL__c u : xeroServices.get(selectedService).Xero_Saved_URLs__r) {
					l.add(new SelectOption(u.id,u.URL__c));
				}
    		}
    		return l;
    	}
    }

    public PageReference execute() {
        System.debug('Method: '+method+', Service: '+selectedService+'. URL: '+url);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(url);
        if(method=='POST' || method=='PUT') {
        	if(postParam!=null & postParam!='') {
	        	req.setBody(postParam);
				req.setHeader('Content-Type','application/x-www-form-urlencoded');
			} else {
				req.setBody(body);
			}
        }
        OAuth oa = new OAuth();
        system.debug('Service application type: '+serviceRecord.Application_Type__c);
        if(xeroServices.get(selectedService).Application_Type__c=='Private') {
        	system.debug('Service application type is private');	
        	oa.setService(xeroServices.get(selectedService));
        	oa.signRSA(req);
        } else {
	        if(!oa.setService(selectedService)) {
	        	System.debug(oa.message);
	        	message=oa.message;
	        	return null;
	        }
	        oa.sign(req);
        }
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        message = '';
        return null;
    }

	public PageReference loadURL() {
		url = selectedSavedURLObj.URL__c;
		method = selectedSavedURLObj.Method__c;
		if(selectedSavedURLObj.Is_Form_URL_Encoded__c) {
			postParam = selectedSavedURLObj.Body__c;
		} else {
			body = selectedSavedURLObj.Body__c;
		}
		return null;
	}
}