public class OAuth {

    private Xero_Service__c service;
    private Xero_App_Config__c XeroAppConfig;
    private String token;
    private String tokenSecret;
    private Boolean isAccess = false;
    private String verifier;
    
    
    private final string RSAkey = 'MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBALGrDHJEvwS6HjYe'+'\n'+
                        'QSDIIR30clUX8BFElRRp/8AtfMq6HeSDyhKaUES3+GprXp3AvxV4iHeKoHdOjUZY'+'\n'+
                        'A3AdoLNrSDOD1HXMNXIJXWCukDPu+/hO/DJ73Cr4R1N4RTN1/kx0ZKYEv0Fc+Uzd'+'\n'+
                        '0WrmaImuUYUMj2F9UUmhxWSfCbwjAgMBAAECgYBQdAF92S2ayWEW5ppdauK8Os5v'+'\n'+
                        'RBi86Q6NIPbkInUJJECXEyq1Q9WnWJuQLTC6ROcCpQM/BrJldFe7C+36nh//fhni'+'\n'+
                        'yClcTpgOWxMSjdbJabq/zMudqEl5P5oF21y5nRQYzTC2ehOeYJUl8xYCQeUP9uU4'+'\n'+
                        'z/M/aTYQvX7RQYcB0QJBANoCm1i5ndG6sEcbnbmP4764CKsGfkJSc3D3RvSR8UQX'+'\n'+
                        'sDSuN13/R9UUHW7sd8IyjuPAYgniGci5feVIo1gPBWkCQQDQoMqspuuuW9UUlOvh'+'\n'+
                        'arK2b5+PBTf5Q1BVI+v/u0FZ65jqq8gfzPhzaX+EUnt/K+WWorPGJXCoogbmCyiZ'+'\n'+
                        'WUerAkEAwbhNSALwHNwyJY2BktEsQ12OvkIv0UkosXnZQBuq8qHF/pnMMydTMiEE'+'\n'+
                        'ontXU2XPmMtrknKqDLXfC+2G0AnQ+QJBALBw7DesS/KAE+t+LyfLVy1XpfgND9Ot'+'\n'+
                        'jEkVQkhbk996ky8U7QGIFi91b7T3FR7ufxMwsx3HGEpmDbOMiF941FUCQQDVHCRq'+'\n'+
                        '9m7OmZrXM9TKeO6q1xJp/Nuc6aY6wUw6mCMN49R2YLPOPec+8VuRcsA1d0nb6oIh'+'\n'+
                        'oWQ/51DGlv5ryS5L';
                        
    private String nonce;
    private String timestamp;
    private String signature;
    private String consumerKey;
    private String consumerSecret;
    
    private final string applicationType ='Private';
    private string PKCSKey;

    private Map<String,String> parameters = new Map<String,String>();
    
    public String message { get; set; }

    public String callbackUrl { get; set; }
    
    public void setConsumerKey(String value) { consumerKey = value; }
    public void setConsumerSecret(String value) { consumerSecret = value; }
    
    public OAuth() {
    	XeroAppConfig  = Xero_App_Config__c.getOrgDefaults();
    }

    /**
     * Looks up service name and starts a new authorisation process
     * returns the authorisation URL that the user should be redirected to
     * If null is returned, the request failed. The message property will contain
     * the reason.
     */ 
    public String newAuthorisation(String serviceName) {

        service = [SELECT Request_Token_URL__c, Access_Token_URL__c, Consumer_Key__c, 
                          Consumer_Secret__c, Authorisation_URL__c, Application_Type__c, PKCS_Private_Key__c,
                          (select Token__c, Secret__c, IsAccess__c FROM Xero_Tokens__r WHERE Owner__c=:UserInfo.getUserId() ) 
                          FROM Xero_Service__c WHERE Name = :serviceName];
        
        if(service==null) {
            System.debug('Couldn\'t find Oauth Service '+serviceName);
            message = 'Service '+serviceName+' was not found in the local configuration';
            return null;
        }

        if(callbackUrl==null) { 
            if(ApexPages.currentPage()==null || ApexPages.currentPage().getHeaders().get('Host')==null) {
                message = 'No callback page was set and it couldn\'t be generated from Apex context';
                System.debug(message);
                return null;
            }
    
            callbackUrl = EncodingUtil.urlEncode('https://'+ApexPages.currentPage().getHeaders().get('Host')+
                                                 Page.CompleteAuth.getUrl(),'UTF-8');
        }
                
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(service.Request_Token_URL__c);
        System.debug('Request body set to: '+req.getBody());
        consumerKey = service.Consumer_Key__c;
        System.debug('Customer Key = ' + consumerKey);
        consumerSecret = service.Consumer_Secret__c;
        System.debug('Customer Secret = ' + consumerSecret);
        if(service.Application_Type__c=='Private')
            signRSA(req);
        else 
            sign(req);  
        HttpResponse res = null;
        if(serviceName=='test1234') {
            // testing
            res = new HttpResponse();
        } else {
            res = h.send(req);
        }
        System.debug('Response from request token request: ('+res.getStatusCode()+')'+res.getBody());
        if(res.getStatusCode()>299) {
            message = 'Failed getting a request token. HTTP Code = '+res.getStatusCode()+
                      '. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
            return null;
        }
        String resParams = serviceName == 'test1234' ? 
            'oauth_token=token&oauth_token_secret=token_secret' : res.getBody();
        Map<String,String> rp = getUrlParams(resParams);
        Xero_Token__c t = new Xero_Token__c();
        t.Owner__c = UserInfo.getUserId();
        t.Xero_Service__c = service.id;
        t.Token__c = rp.get('oauth_token');
        t.Secret__c = rp.get('oauth_token_secret');
        t.IsAccess__c = false;

        delete service.Xero_Tokens__r;

        insert t;
        
        System.debug('Got request token: '+t.Token__c+'('+rp.get('oauth_token')+')');
        
        if(service.Authorisation_URL__c.contains('?')) {
            return service.Authorisation_URL__c+'&oauth_token='+EncodingUtil.urlDecode(t.Token__c,'UTF-8')+'&oauth_consumer_key='+service.Consumer_Key__c;
        } else {
            return service.Authorisation_URL__c+'?oauth_token='+EncodingUtil.urlDecode(t.Token__c,'UTF-8')+'&oauth_consumer_key='+service.Consumer_Key__c;
        }
    }
    
    public boolean completeAuthorisation(String token, String verifier) {
        System.debug('Completing authorisation for request token '+token+' with verifier '+verifier);
        Xero_Token__c t = null;
        try {
            t =
            [SELECT Xero_Service__r.Name, Xero_Service__r.Access_Token_URL__c, Xero_Service__r.Consumer_Key__c, 
             Xero_Service__r.Consumer_Secret__c, Token__c, Secret__c, IsAccess__c FROM Xero_Token__c 
             WHERE Owner__c=:UserInfo.getUserId() AND Token__c = :EncodingUtil.urlEncode(token,'UTF-8') AND IsAccess__c = false];
        } catch(System.QueryException e) {
            message = 'Unknown request token: '+token+'. Restart authorisation process';
            System.debug(message);
            return false;
            
        }

        service = t.Xero_Service__r;
        
        consumerKey = service.Consumer_Key__c;
        consumerSecret = service.Consumer_Secret__c;
        this.token = t.Token__c;
        tokenSecret = t.Secret__c;
        if(verifier!=null) {
            this.verifier = EncodingUtil.urlEncode(verifier,'UTF-8');
        }
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(service.Access_Token_URL__c);
        req.setBody('');
        sign(req);
        HttpResponse res = null;
        if(service.name=='test1234') {
            res = new HttpResponse();
        } else {
            res = h.send(req);
            System.debug('Response from request token request: ('+res.getStatusCode()+')'+res.getBody());
        }
        if(res.getStatusCode()>299) {
            message = 'Failed getting an access token. HTTP Code = '+res.getStatusCode()+'. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
            return false;
        }

        String resParams = service.name == 'test1234' ? 
            'oauth_token=token&oauth_token_secret=token_secret' : res.getBody();

        Map<String,String> rp = new Map<String,String>();
        for(String s : resParams.split('&')) {
            List<String> kv = s.split('=');
            rp.put(kv[0],kv[1]);
            System.debug('Access token response param: '+kv[0]+'='+kv[1]);
        }
        
        t.Token__c = rp.get('oauth_token');
        t.Secret__c = rp.get('oauth_token_secret');
        t.IsAccess__c = true;
        
        update t;
        
        return true;
    }
    
    public List<User> getUsersOfService(String serviceName) {
        List<Xero_Token__c> l =
            [SELECT Xero_Service__r.Name, IsAccess__c, Owner__r.Name FROM Xero_Token__c 
             WHERE Xero_Service__r.Name= :serviceName AND IsAccess__c = true];
             
        List<User> result = new List<User>();
        for(Xero_Token__c t : l) {
            result.add(t.Owner__r);
        }
        return result;
    }

    public boolean setService(String serviceName) {
        return setService(serviceName,UserInfo.getUserId());
    }

    public boolean setService(String serviceName, ID userId) {
        Xero_Token__c t = null;
        try {
            t =
            [SELECT Xero_Service__r.Name, Xero_Service__r.Consumer_Key__c, Xero_Service__r.Consumer_Secret__c, Xero_Service__r.Application_Type__c, 
             Token__c, Secret__c, IsAccess__c FROM Xero_Token__c 
             WHERE Xero_Service__r.Name= :serviceName AND Owner__c=:userId AND IsAccess__c = true];
        } catch(System.QueryException e) {
            message = 'User '+UserInfo.getUserName()+' did not authorise access to '+serviceName+'. Redirect user to authorisation page. ['+e+']';
            System.debug(message);
            return false;
        }
        service = t.Xero_Service__r;
        
        System.debug('Preparing OAuth request to service '+service.name);
        
        consumerKey = service.Consumer_Key__c;
        consumerSecret = service.Consumer_Secret__c;
        this.token = t.Token__c;
        tokenSecret = t.Secret__c;      
        return true;
    }
    
    public boolean setService(Xero_Service__c s) {
        system.debug('setting service for private application in oAuth class');
        this.service = s;
        system.debug('Service :'+service);
        consumerKey = service.Consumer_Key__c;
        consumerSecret = service.Consumer_Secret__c;
        system.debug('setting token to consumer key for private application in oAuth class');
        this.token = s.Consumer_key__c;
        return true;
    }
        
    private void refreshParameters() {
        parameters.clear();
        parameters.put('oauth_consumer_key',consumerKey);
        if(token!=null) {
            parameters.put('oauth_token',token);
        }
        if(verifier!=null) {
            parameters.put('oauth_verifier',verifier);
        }
        if(applicationType =='Private')//service.Application_Type__c replaced with constant variable ApplicationType
        {
            parameters.put('oauth_signature_method','RSA-SHA1');
        }
        else
        { 
            parameters.put('oauth_signature_method','HMAC-SHA1');
            parameters.put('oauth_callback',callbackUrl);
        }
        parameters.put('oauth_timestamp',timestamp);
        parameters.put('oauth_nonce',nonce);
        system.debug('parameters value: '+parameters);
    }

    private Map<String,String> getUrlParams(String value) {

        Map<String,String> res = new Map<String,String>();
        if(value==null || value=='') {
            return res;
        }
        for(String s : value.split('&')) {
            System.debug('getUrlParams: '+s);
            List<String> kv = s.split('=');
            if(kv.size()>1) {
                System.debug('getUrlParams:  -> '+kv[0]+','+kv[1]);
                res.put(kv[0],kv[1]);
            }
        }
        return res;
    }

    private String createBaseString(Map<String,String> oauthParams, HttpRequest req) {
        Map<String,String> p = oauthParams.clone();
        if(req.getMethod().equalsIgnoreCase('post') && req.getBody()!=null && 
           req.getHeader('Content-Type')=='application/x-www-form-urlencoded') {
            p.putAll(getUrlParams(req.getBody()));
        }
        String host = req.getEndpoint();
        Integer n = host.indexOf('?');
        if(n>-1) {
            p.putAll(getUrlParams(host.substring(n+1)));
            host = host.substring(0,n);
        }
        List<String> keys = new List<String>();
        keys.addAll(p.keySet());
        keys.sort();
        String s = keys.get(0)+'='+p.get(keys.get(0));
        for(Integer i=1;i<keys.size();i++) {
            s = s + '&' + keys.get(i)+'='+p.get(keys.get(i));
        }

        // According to OAuth spec, host string should be lowercased, but Google and LinkedIn
        // both expect that case is preserved.
        return req.getMethod().toUpperCase()+ '&' + 
            EncodingUtil.urlEncode(host, 'UTF-8') + '&' +
            EncodingUtil.urlEncode(s, 'UTF-8');
    }
    
    public void sign(HttpRequest req) {
        /*
        nonce = String.valueOf(Crypto.getRandomLong());
        timestamp = String.valueOf(DateTime.now().getTime()/1000);
        
        refreshParameters();
        
        String algorithmName = 'RSA-SHA1';
        System.debug('algorithmName = ' + algorithmName);
        
        String RSAkey = 'MIICdQIBADANBgkqhkiG9w0BAQEFAASCAl8wggJbAgEAAoGBAL23b7hIDfnhUgLCR3DdCSjpdci/NxnwJ9NGaCq+VNbPP8ZbIIfzMUUqN4dlmsjMUiGvkxkj+7t1Pd4oCOq9+AQgJiR+MKU6WmCN4D0FcDri8mINy7D6Zh4vflRWpffysxeL7hyCGJeMFHCGW/2U1fHmRe7Z7QhHULLQXdNuM5pXAgMBAAECgYBiW0zPdIPSbe+vwHt7Vw0dqdPHzOLLTsfG8DSnHGAtser1cl8uPHXpztZVGuchfVSDZFxV52LmMAVwPL9KvExtKjpHEyZ9F1IvylX0tF/eRKm8D1hH0vVsHxRtw/51nD8jYlBmJRxPyHU0dEJMHZEjCUhF6wS5VDFycxOshVNfmQJBAOmvz+TMBeFis3ZnLFAyyC3ONss83xuLvuX2E7L1cOikiqYe5rzpkab7lZz+9VLAxmNVV+OP32cjiiX0jumXsHMCQQDP1NN0WWL9cZdX2YOjCjVlMU3Am480EQMJ2K8+KQ1vPVmZbwk+uCq9in+wEqgDapGvDVE4gxX1CJqmu8IrxymNAkAp1iz9BD3FRRtmBkCbtwu5j6KlricvUkyB9RU/w8tMCzE7XmrmxVYrM/1sFwUqpJKf9AaBGh/f4i/4bZksXtjbAkB0i4V0lnejZmKXOfvOnvfoYiiW3OUGLpAEooVLF1xYSBAJsbF+gWo+Vf9armuXVtiRUKd+SEw013laDKpLQGk1AkBkcMs2jjOmUP/3ktiVCfGPoetZG5d7k4wc9gjSCcSG436kYOCrvS877YqwU2Ksk2Z0t4VF9A0tHdDRpApOktcf';
        System.debug('RSAkey = ' + RSAkey);
        
        String s = createBaseString(parameters, req);
        System.debug('Signature base string: '+s);
        
        Blob privateKey = EncodingUtil.base64Decode(RSAkey);
        Blob input = Blob.valueOf(s);
        Blob sig = Crypto.sign(algorithmName, input, privateKey);
        
        signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        System.debug('Signature: '+signature);
        
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header + key + '="'+parameters.get(key)+'", ';
        }
        header = header + 'oauth_signature="'+signature+'"';
        System.debug('Authorization: '+header);
        
        req.setHeader('Authorization',header);
        */
        
        nonce = String.valueOf(Crypto.getRandomLong());
        timestamp = String.valueOf(DateTime.now().getTime()/1000);

        refreshParameters();
        
        String s = createBaseString(parameters, req);
        
        System.debug('Signature base string: '+s);
        
        Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(s), 
                       Blob.valueOf(consumerSecret+'&'+
                                    (tokenSecret!=null ? tokenSecret : '')));
        signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        System.debug('Signature: '+signature);
        
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header + key + '="'+parameters.get(key)+'", ';
        }
        header = header + 'oauth_signature="'+signature+'"';
        System.debug('Authorization: '+header);
        req.setHeader('Authorization',header);
        
    }   
    
    public void signRSA(HttpRequest req) {
        system.debug('calling signRSA method');
        nonce = String.valueOf(Crypto.getRandomLong());
        timestamp = String.valueOf(DateTime.now().getTime()/1000);
        system.debug('calling refreshParameters method');
        refreshParameters();
        
        String algorithmName = 'RSA-SHA1';
        System.debug('algorithmName = ' + algorithmName);
        
        /*
        String RSAkey = 'MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBALGrDHJEvwS6HjYe'+'\n'+
                        'QSDIIR30clUX8BFElRRp/8AtfMq6HeSDyhKaUES3+GprXp3AvxV4iHeKoHdOjUZY'+'\n'+
                        'A3AdoLNrSDOD1HXMNXIJXWCukDPu+/hO/DJ73Cr4R1N4RTN1/kx0ZKYEv0Fc+Uzd'+'\n'+
                        '0WrmaImuUYUMj2F9UUmhxWSfCbwjAgMBAAECgYBQdAF92S2ayWEW5ppdauK8Os5v'+'\n'+
                        'RBi86Q6NIPbkInUJJECXEyq1Q9WnWJuQLTC6ROcCpQM/BrJldFe7C+36nh//fhni'+'\n'+
                        'yClcTpgOWxMSjdbJabq/zMudqEl5P5oF21y5nRQYzTC2ehOeYJUl8xYCQeUP9uU4'+'\n'+
                        'z/M/aTYQvX7RQYcB0QJBANoCm1i5ndG6sEcbnbmP4764CKsGfkJSc3D3RvSR8UQX'+'\n'+
                        'sDSuN13/R9UUHW7sd8IyjuPAYgniGci5feVIo1gPBWkCQQDQoMqspuuuW9UUlOvh'+'\n'+
                        'arK2b5+PBTf5Q1BVI+v/u0FZ65jqq8gfzPhzaX+EUnt/K+WWorPGJXCoogbmCyiZ'+'\n'+
                        'WUerAkEAwbhNSALwHNwyJY2BktEsQ12OvkIv0UkosXnZQBuq8qHF/pnMMydTMiEE'+'\n'+
                        'ontXU2XPmMtrknKqDLXfC+2G0AnQ+QJBALBw7DesS/KAE+t+LyfLVy1XpfgND9Ot'+'\n'+
                        'jEkVQkhbk996ky8U7QGIFi91b7T3FR7ufxMwsx3HGEpmDbOMiF941FUCQQDVHCRq'+'\n'+
                        '9m7OmZrXM9TKeO6q1xJp/Nuc6aY6wUw6mCMN49R2YLPOPec+8VuRcsA1d0nb6oIh'+'\n'+
                        'oWQ/51DGlv5ryS5L';*/
        //string RSAkey = service.PKCS_Private_Key__c;              
        System.debug('RSAkey = ' + RSAkey);
        system.debug('consumerKey :'+consumerKey);
        String s = createBaseString(parameters, req);
        System.debug('Signature base string: '+s);
        system.debug('consumerKey :'+consumerSecret);
        
        Blob privateKey = EncodingUtil.base64Decode(RSAkey);
        Blob input = Blob.valueOf(s);
        Blob sig = Crypto.sign(algorithmName, input, privateKey);
        
        signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        System.debug('Signature: '+signature);
        
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header + key + '="'+parameters.get(key)+'", ';
        }
        header = header + 'oauth_signature="'+signature+'"';
        System.debug('Authorization: '+header);
        
        req.setHeader('Authorization',header);
    }
        public void signRSANew(HttpRequest req) {
        consumerKey = XeroAppConfig.Consumer_Key__c;
        system.debug('consumerKey :'+consumerKey);
        consumerSecret = XeroAppConfig.Consumer_Secret__c;
        this.token = XeroAppConfig.Consumer_Key__c;
        system.debug('consumerKey :'+consumerSecret);
        system.debug('calling signRSA method');
        nonce = String.valueOf(Crypto.getRandomLong());
        timestamp = String.valueOf(DateTime.now().getTime()/1000);
        system.debug('calling refreshParameters method');
        refreshParameters();
        
        String algorithmName = 'RSA-SHA1';
        System.debug('algorithmName = ' + algorithmName);
        
        
        
        //string RSAkey = service.PKCS_Private_Key__c;              
        //System.debug('RSAkey = ' + RSAkey);
        
        String s = createBaseString(parameters, req);
        System.debug('Signature base string: '+s);
        
        Blob privateKey = EncodingUtil.base64Decode(RSAkey);
        Blob input = Blob.valueOf(s);
        Blob sig = Crypto.sign(algorithmName, input, privateKey);
        
        signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        System.debug('Signature: '+signature);
        
        String header = 'OAuth ';
        for (String key : parameters.keySet()) {
            header = header + key + '="'+parameters.get(key)+'", ';
        }
        header = header + 'oauth_signature="'+signature+'"';
        System.debug('Authorization: '+header);
        
        req.setHeader('Authorization',header);
    }
}