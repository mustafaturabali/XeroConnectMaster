public class OAuthRequest {

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
    
    public OAuthRequest() {
        XeroAppConfig  = Xero_App_Config__c.getOrgDefaults();
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
    
    public void sign(HttpRequest req) {
        
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