public class XeroPrivateAuthTest {
	
	public static void testinvoices() {
		//create request object
		string method = 'GET';
		string URL = 'https://api.xero.com/api.xro/2.0/invoices';

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(url);
		
		//set parameters
		string nonce = String.valueOf(Crypto.getRandomLong());
		string timestamp = String.valueOf(DateTime.now().getTime()/1000);
		string consumerKey = 'RZOMQSM8H9Q1EGBU9NC2W3GWEDPLHF';
		string consumerSecret = '';//'6ZYJBBC0VGAFCVQLF8UU4W6XFDTURP';
		string callbackUrl = EncodingUtil.urlEncode('https://na14.salesforce.com/'+Page.CompleteAuth.getUrl(),'UTF-8');

		Map<String,String> parameters = new Map<String,String>();
		
		parameters.put('oauth_consumer_key',consumerKey);
		parameters.put('oauth_nonce',nonce);
		parameters.put('oauth_signature_method','RSA-SHA1');
		parameters.put('oauth_timestamp',timestamp);
		parameters.put('oauth_token',consumerKey);
		//parameters.put('oauth_callback',callbackUrl);
		parameters.put('oauth_version','1.0');
		
		String algorithmName = 'RSA-SHA1';
		System.debug('algorithmName = ' + algorithmName);
		
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
						'oWQ/51DGlv5ryS5L';
		
		//sign headers
		String s = createBaseString(parameters, req);
		System.debug('Signature base string: '+s);
		
		Blob privateKey = EncodingUtil.base64Decode(RSAkey);
		Blob input = Blob.valueOf(s);
		Blob sig = Crypto.sign(algorithmName, input, privateKey);
		
		string signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
		System.debug('Signature: '+signature);
		
		String header = 'OAuth ';
		for (String key : parameters.keySet()) {
			header = header + key + '="'+parameters.get(key)+'", ';
		}
		header = header + 'oauth_signature="'+signature+'"';
		System.debug('Authorization: '+header);
		
		req.setHeader('Authorization',header);
		//make request
		System.debug('Sending request...');
        HttpResponse res = h.send(req);
        string body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        System.debug('Received response body ('+body+')');
	} 
	
	private static Map<String,String> getUrlParams(String value) {

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
	
	private static String createBaseString(Map<String,String> oauthParams, HttpRequest req) {
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
	
	/*
	public static void getinvoices() {
		string consumerKey = '';
		string consumerSecret = '';
		
		
		string oauth_nonce = String.valueOf(Crypto.getRandomLong());
		string oauth_timestamp = String.valueOf(DateTime.now().getTime()/1000);
		string signatureBase = "GET" + "&" +
		EncodingUtil.urlEncode("https://api.xero.com/api.xro/2.0/Organisation", "UTF-8") + "&" +
		EncodingUtil.urlEncode("oauth_consumer_key=" + consumerKey + "&oauth_nonce="+oauth_nonce+"&oauth_signature_method=RSA-SHA1&oauth_timestamp="+oauth_timestamp+"&oauth_token=" + consumerKey + "&oauth_version=1.0", "UTF-8");
		String rsa = 'MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBALGrDHJEvwS6HjYe'+'\n'+
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
		
		string hashAlg = "sha1";
		var hSig = rsa.signString(signatureBase, hashAlg);
		var data = new Array();
		for (var i = 0; i < hSig.length; i += 2) {
		data.push(parseInt("0x" + hSig.substr(i, 2)));
		}
		
		Blob privateKey = EncodingUtil.base64Decode(rsa);
		Blob input = Blob.valueOf(s);
		Blob sig = Crypto.sign('RSA-SHA1', input, privateKey);
		
		signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
		
		
		var oauth_signature = Base64.encode(data);  
		var authHeader = "OAuth oauth_token=\"" + consumerKey + "\",oauth_nonce=\"" + oauth_nonce + "\",oauth_consumer_key=\"" + consumerKey + "\",oauth_signature_method=\"RSA-SHA1\",oauth_timestamp=\"" + oauth_timestamp + "\",oauth_version=\"1.0\",oauth_signature=\"" + EncodingUtil.urlEncode(oauth_signature, "UTF-8") + "\"";
		var headers = { "User-Agent": + UserProperties.getProperty("userAgent") , "Authorization": authHeader };
		var options = { "headers": headers };
		Logger.log(signatureBase);
		Logger.log(oauth_signature);
		Logger.log(authHeader);
		var response = UrlFetchApp.fetch("https://api.xero.com/api.xro/2.0/Organisation", options);
		var responseXml = response.getContentText();
		Logger.log(responseXml);
	}
	
	public static void test() {
		string method = 'GET';
		string URL = 'https://api.xero.com/api.xro/2.0/invoices';

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(url);
        
		string nonce = String.valueOf(Crypto.getRandomLong());
		string timestamp = String.valueOf(DateTime.now().getTime()/1000);
		string consumerKey = 'RZOMQSM8H9Q1EGBU9NC2W3GWEDPLHF';
		string consumerSecret = '';//'6ZYJBBC0VGAFCVQLF8UU4W6XFDTURP';
		string callbackUrl = EncodingUtil.urlEncode('https://na14.salesforce.com/'+Page.CompleteAuth.getUrl(),'UTF-8');

		Map<String,String> parameters = new Map<String,String>();
	
		parameters.put('oauth_consumer_key',consumerKey);
		parameters.put('oauth_signature_method','RSA-SHA1');
		parameters.put('oauth_timestamp',timestamp);
		parameters.put('oauth_nonce',nonce);
		parameters.put('oauth_callback',callbackUrl);

		
		String algorithmName = 'RSA-SHA1';
		System.debug('algorithmName = ' + algorithmName);
		
		//String RSAkey = 'MIICdQIBADANBgkqhkiG9w0BAQEFAASCAl8wggJbAgEAAoGBAL23b7hIDfnhUgLCR3DdCSjpdci/NxnwJ9NGaCq+VNbPP8ZbIIfzMUUqN4dlmsjMUiGvkxkj+7t1Pd4oCOq9+AQgJiR+MKU6WmCN4D0FcDri8mINy7D6Zh4vflRWpffysxeL7hyCGJeMFHCGW/2U1fHmRe7Z7QhHULLQXdNuM5pXAgMBAAECgYBiW0zPdIPSbe+vwHt7Vw0dqdPHzOLLTsfG8DSnHGAtser1cl8uPHXpztZVGuchfVSDZFxV52LmMAVwPL9KvExtKjpHEyZ9F1IvylX0tF/eRKm8D1hH0vVsHxRtw/51nD8jYlBmJRxPyHU0dEJMHZEjCUhF6wS5VDFycxOshVNfmQJBAOmvz+TMBeFis3ZnLFAyyC3ONss83xuLvuX2E7L1cOikiqYe5rzpkab7lZz+9VLAxmNVV+OP32cjiiX0jumXsHMCQQDP1NN0WWL9cZdX2YOjCjVlMU3Am480EQMJ2K8+KQ1vPVmZbwk+uCq9in+wEqgDapGvDVE4gxX1CJqmu8IrxymNAkAp1iz9BD3FRRtmBkCbtwu5j6KlricvUkyB9RU/w8tMCzE7XmrmxVYrM/1sFwUqpJKf9AaBGh/f4i/4bZksXtjbAkB0i4V0lnejZmKXOfvOnvfoYiiW3OUGLpAEooVLF1xYSBAJsbF+gWo+Vf9armuXVtiRUKd+SEw013laDKpLQGk1AkBkcMs2jjOmUP/3ktiVCfGPoetZG5d7k4wc9gjSCcSG436kYOCrvS877YqwU2Ksk2Z0t4VF9A0tHdDRpApOktcf';//'MIIC3jCCAkegAwIBAgIJAND6C6O7ckfoMA0GCSqGSIb3DQEBBQUAMFQxCzAJBgNVBAYTAlVLMQ8wDQYDVQQHEwZMb25kb24xEDAOBgNVBAMTB011c3RhZmExIjAgBgkqhkiG9w0BCQEWE210QGJleW9uZHZpc2lvbi5uZXQwHhcNMTIwNzE2MTQxNjAyWhcNMTMwNzE2MTQxNjAyWjBUMQswCQYDVQQGEwJVSzEPMA0GA1UEBxMGTG9uZG9uMRAwDgYDVQQDEwdNdXN0YWZhMSIwIAYJKoZIhvcNAQkBFhNtdEBiZXlvbmR2aXNpb24ubmV0MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDLtdDZptUbmqEV7i2b94vxEiVgOc8k3TBjgPixMIEwKRPEDF2lGwAyzv9ODMuLykptxblQJdmv2opR9qbaVpz94zHliSi6rT2Z04nfxXopAGb+jSPx5UCmTqr7JyInRznfr9elHJ3rDVAwQVJUAHQRbm9U6Z0/2vahwW1U1W8YKwIDAQABo4G3MIG0MB0GA1UdDgQWBBRkU2K1gtMzaG7la0Xlvc0vLF5KJTCBhAYDVR0jBH0we4AUZFNitYLTM2hu5WtF5b3NLyxeSiWhWKRWMFQxCzAJBgNVBAYTAlVLMQ8wDQYDVQQHEwZMb25kb24xEDAOBgNVBAMTB011c3RhZmExIjAgBgkqhkiG9w0BCQEWE210QGJleW9uZHZpc2lvbi5uZXSCCQDQ+guju3JH6DAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4GBAI9RljAWMGREgXtS0ETYate2m8jHjiLc2ABfvmGiwAq9G16al7vp+hEMRuW23vApen13p1W0xUJ8DMRlU/bw132pDLW6SxkvB6pFecAsk/0nnwp3RUwvn4zKwFfKKqgsrTZwBNVe9iE9qNIFG+Wn1AV4ohJSfdN7bCJ3ZP5lcST8';
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
						'oWQ/51DGlv5ryS5L';
		System.debug('RSAkey = ' + RSAkey);
		
		Map<String,String> p = parameters.clone();
		if(req.getMethod().equalsIgnoreCase('post') && req.getBody()!=null && 
		   req.getHeader('Content-Type')=='application/x-www-form-urlencoded') {
			string value = req.getBody();
		   	Map<String,String> res = new Map<String,String>();
			if(value==null || value=='') {
				
			}
			else {
			for(String ssss : value.split('&')) {
				System.debug('getUrlParams: '+ssss);
				List<String> kv = ssss.split('=');
				if(kv.size()>1) {
					System.debug('getUrlParams:  -> '+kv[0]+','+kv[1]);
					res.put(kv[0],kv[1]);
				}
			}
		  }
			p.putAll(res);
		}
		String host = req.getEndpoint();
		Integer n = host.indexOf('?');
		List<String> keys = new List<String>();
		keys.addAll(p.keySet());
		keys.sort();
		String sss = keys.get(0)+'='+p.get(keys.get(0));
		for(Integer i=1;i<keys.size();i++) {
			sss = sss + '&' + keys.get(i)+'='+p.get(keys.get(i));
		}

		// According to OAuth spec, host string should be lowercased, but Google and LinkedIn
		// both expect that case is preserved.
		string ss = req.getMethod().toUpperCase()+ '&' + EncodingUtil.urlEncode(host, 'UTF-8') + '&' + EncodingUtil.urlEncode(sss, 'UTF-8');
		System.debug('Signature base string: '+ss);
		
		Blob privateKey = EncodingUtil.base64Decode(RSAkey);
		//Blob privateKey = Blob.valueof(RSAKey);
		Blob input = Blob.valueOf(ss);
		Blob sig = Crypto.sign(algorithmName, input, privateKey);
		
		string signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
		System.debug('Signature: '+signature);
		
		String header = 'OAuth ';
		for (String key : parameters.keySet()) {
			header = header + key + '="'+parameters.get(key)+'", ';
		}
		header = header + 'oauth_signature="'+signature+'"';
		System.debug('Authorization: '+header);
		
		req.setHeader('Authorization',header);

        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        string body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        string message = '';
	}*/
}