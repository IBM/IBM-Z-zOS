/* ** Beginning of Copyright and License **									 */
/*																			 */
/* Copyright 2018 IBM Corp.              									 */                             
/*                                                   						 */                 
/* Licensed under the Apache License, Version 2.0 (the "License"); 			 */    
/* you may not use this file except in compliance with the License. 		 */ 
/* You may obtain a copy of the License at                          		 */
/*                                                                    		 */
/* http://www.apache.org/licenses/LICENSE-2.0                   			 */     
/*                                                                   		 */
/* Unless required by applicable law or agreed to in writing, software		 */
/* distributed under the License is distributed on an "AS IS" BASIS,  		 */
/* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  */
/* See the License for the specific language governing permissions and 		 */
/* limitations under the License.                    						 */
/*																			 */
/* ** End of Copyright and License **  										 */

package com.ibm.zosmf.restclient.basic;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.Charset;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.HashMap;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.KeyManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSession;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class RestConnection {
	private HttpsURLConnection huconn = null;
	
	/**
	 * SSL configuration
	 */
	private static final String SSLCONTEXT_ALGORITHM_TLS_V1 = "TLSv1";
	private SSLContext sslCtx = null;
	
	/**
	 * properties used for request
	 */
	private String url= null;
	private String httpMethod = "GET"; // by default
	// TODO: HashMap can't handle the param with same name
	private HashMap<String, String> paramMap = new HashMap<String, String>();
	private HashMap<String, String> headerMap = new HashMap<String, String>();
	private String bodyStr = null;
	// TODO: used for pass binary data
	private byte[] bodyByte;
	private static int TIMEOUT = 20 * 1000;
	
	/**
	 * properties used for response 
	 */
	private int statusCode = 0;
	private boolean successful = false; // true if statusCode is 2XX
	private InputStream resIs = null;
	private InputStream resEs = null;
	private String resStr = null;
	
	/**
	 * messages 
	 */
	private static String MSG_HEADER_INVALID_IGNORE = "header is invalid, ignore header: %s.";
	private static String MSG_SUC_IS_NULL = "status code is %s, but resIs is null.";
	private static String MSG_FAIL_ES_NULL = "status code is %s, but resEs is null.";
	
	/**
	 * change below method to change the way to log messages. Simply print to system.out for now
	 * @param msg
	 */
	protected void logMessage(String msg) {
		System.out.println(msg);
	}
	
	public void setUrl(String url) {
		this.url = url;
	}
	
	public void addHeader(String header, String value) {
		if (header != null && !header.isEmpty()) {
			headerMap.put(header, value);
		} else {
			logMessage(String.format(MSG_HEADER_INVALID_IGNORE, header));
		}
	}
	
	public void removeHeader(String header, String value) {
		// TODO: 
	}
	
	public void setBody(String body) {
		this.bodyStr = body;
	}
	
	public void setBody(byte[] body) {
		// TODO: set binary data as body
	}
	
	private void handleSSL() throws NoSuchAlgorithmException, KeyManagementException {
		sslCtx = SSLContext.getInstance(SSLCONTEXT_ALGORITHM_TLS_V1);
		sslCtx.init(new KeyManager[0], new TrustManager[] {new DefaultTrustManager()}, new SecureRandom());		
		SSLContext.setDefault(sslCtx);
	}
	
	/**
	 * put param info into url
	 */
	private void handleParam() {
		// TODO: put param info into url
	}
	
	private void handleCookie() {
		// TODO: add cookie to header
	}
	
	private void handleHeader() {
		for (String header : headerMap.keySet()) {
			String value = headerMap.get(header);
			huconn.setRequestProperty(header, value);
			logMessage(header +": "+ value);
		}
	}

	private void handleBody() {
		OutputStream out = null;
		if (bodyStr != null && !bodyStr.isEmpty()) {
			try {
				out = new DataOutputStream(huconn.getOutputStream());
				out.write(bodyStr.getBytes());
				out.flush();
				out.close();
			} catch (IOException e) {
				// TODO: should use try-with-resource to refactor this part
				e.printStackTrace();
			} finally {
				if (out != null) {
					try {
						out.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
			}
			logMessage("Request Body: "+ bodyStr);
		}
	}

	private void prepareConnection() throws KeyManagementException, NoSuchAlgorithmException, MalformedURLException, IOException {
		handleSSL();
		handleParam();
		handleCookie();
		huconn = (HttpsURLConnection) new URL(url).openConnection();
		huconn.setRequestMethod(httpMethod);
		logMessage(httpMethod +" "+ url);
		handleHeader();
		
		// HostnameVerifier need to be set before IO
		huconn.setHostnameVerifier(new HostnameVerifier(){
			public boolean verify(String arg0, SSLSession arg1) {
				return true;
			}
		});

		huconn.setDoInput(true);
		huconn.setDoOutput(true);
        handleBody();		
		
		huconn.setConnectTimeout(TIMEOUT);
		huconn.setReadTimeout(TIMEOUT);
	}
	
	private int connect() throws IOException {
		statusCode = huconn.getResponseCode();
		logMessage("Status: "+ statusCode);
		successful = statusCode / 100 == 2;
		if (successful) { // successful
			resIs = huconn.getInputStream();
		} else { // error condition
			resEs = huconn.getErrorStream();
		}
		return statusCode;
	}
	
	/**
	 * convert response body stream to string,
	 * @return response body as string
	 */
	public String getResponseAsString(Charset charset) {
		// TODO: use given charset to decode InputStream
		if (resStr == null) {
			if (successful) { // decode resIs
				if (resIs != null) {
					BufferedReader br = null;
					StringBuffer sb = new StringBuffer();
					String line = null;
					try {
						br = new BufferedReader(new InputStreamReader(resIs, "utf-8"));
						while ((line = br.readLine()) != null) {
							sb.append(line);
						}
					} catch (UnsupportedEncodingException e) {
						e.printStackTrace();
					} catch (IOException e) {
						e.printStackTrace();
					}
					resStr = sb.toString();
				} else {
					logMessage(String.format(MSG_SUC_IS_NULL, statusCode));
				}
			} else { // decode resEs
				if (resEs != null) {
					BufferedReader br = null;
					StringBuffer sb = new StringBuffer();
					String line = null;
					try {
						br = new BufferedReader(new InputStreamReader(resEs, "utf-8"));
						while ((line = br.readLine()) != null) {
							sb.append(line);
						}
					} catch (UnsupportedEncodingException e) {
						e.printStackTrace();
					} catch (IOException e) {
						e.printStackTrace();
					}
					resStr = sb.toString();
				} else {
					logMessage(String.format(MSG_FAIL_ES_NULL, statusCode));
				}
			}
		} 
		logMessage("Response:\n"+ resStr);
		logMessage("=============================================");
		return resStr;
	}
	
	public String getResponseAsJson() {
		// TODO: need other tool to handle json, such as jackson
		return null;
	}
	
//	public byte[] getResponseAsBytes() {
//		return null;
//	}
	
	/**
	 * send GET request and return the status code to invoker
	 * @return status code
	 */
	public int GET() {
		this.httpMethod = "GET";
		try { // TODO: too many exception, maybe self customized exception is needed to include all situation
			prepareConnection();
			connect();
		} catch (KeyManagementException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NoSuchAlgorithmException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (MalformedURLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return statusCode;
	}
	
	public int PUT() {
		this.httpMethod = "PUT";
		try { // TODO: too many exception, maybe self customized exception is needed to include all situation
			prepareConnection();
			connect();
		} catch (KeyManagementException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (NoSuchAlgorithmException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (MalformedURLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return statusCode;
	}
	
	private static class DefaultTrustManager implements X509TrustManager{

		public void checkClientTrusted(X509Certificate[] arg0, String arg1)
				throws CertificateException {
			// TODO:
		}

		public void checkServerTrusted(X509Certificate[] arg0, String arg1)
				throws CertificateException {
			// TODO:
		}

		public X509Certificate[] getAcceptedIssuers() {
			return null;
		}
	}
}
