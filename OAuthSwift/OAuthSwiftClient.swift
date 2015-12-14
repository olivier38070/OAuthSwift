//
//  OAuthSwiftClient.swift
//  OAuthSwift
//
//  Created by Dongri Jin on 6/21/14.
//  Copyright (c) 2014 Dongri Jin. All rights reserved.
//

import Foundation
import Accounts

var dataEncoding: NSStringEncoding = NSUTF8StringEncoding

public class OAuthSwiftClient {
    
    struct OAuth {
        static let version = "1.0"
        static let signatureMethod = "HMAC-SHA1"
    }
    
    private(set) public var credential: OAuthSwiftCredential
    
    public init(consumerKey: String, consumerSecret: String) {
        self.credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
    }
    
    public init(consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.credential = OAuthSwiftCredential(oauth_token: accessToken, oauth_token_secret: accessTokenSecret)
        self.credential.consumer_key = consumerKey
        self.credential.consumer_secret = consumerSecret
    }
    
    public func get(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "GET", parameters: parameters, success: success, failure: failure)
    }
    
    public func post(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "POST", parameters: parameters, success: success, failure: failure)
    }

    public func put(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "PUT", parameters: parameters, success: success, failure: failure)
    }

    public func delete(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "DELETE", parameters: parameters, success: success, failure: failure)
    }

    public func patch(urlString: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.request(urlString, method: "PATCH", parameters: parameters, success: success, failure: failure)
    }

    func request(url: String, method: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {

        if let url = NSURL(string: url) {
        
            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            if self.credential.oauth2 {
                request.headers = ["Authorization": "Bearer \(self.credential.oauth_token)"]
            } else {
                request.headers = ["Authorization": OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: self.credential)]
            }
            
            request.successHandler = success
            request.failureHandler = failure
            request.dataEncoding = dataEncoding
            request.encodeParameters = true
            request.start()
        }

    }
    
    public func postImage(urlString: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        self.multiPartRequest(urlString, method: "POST", parameters: parameters, image: image, success: success, failure: failure)
    }
    
    // smugmug doc : https://api.smugmug.com/api/v2/doc/reference/upload.html
    
    // upload an image to a smugmug album
    public func uploadImage(urlString: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        let url: String = urlString
        let method: String = "POST"
        
        if let url = NSURL(string: url) {
            
            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            if self.credential.oauth2 {
                request.headers = ["Authorization": "Bearer \(self.credential.oauth_token)"]
            } else {
                //let str = ["Authorization": self.encodeParameters(method, url: url, parameters: parameters, credential: self.credential)]
                //request.headers == str
                //                var str = ["Authorization": OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: self.credential)]
                var str2 = ["Authorization": self.encodeParameters(method, url: url, parameters: parameters, credential: self.credential)]
                request.headers =  str2
            }
            request.successHandler = success
            request.failureHandler = failure
            request.dataEncoding = dataEncoding
            request.encodeParameters = true
            
            request.HTTPBody = image // "\(image)".dataUsingEncoding(NSUTF8StringEncoding)
            request.contentType = "image/jpeg" //type
            request.start()
            
        }
        
    }
    
    
    func multiPartRequest(url: String, method: String, parameters: Dictionary<String, AnyObject>, image: NSData, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        
        
        if let url = NSURL(string: url) {
        
            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            if self.credential.oauth2 {
                request.headers = ["Authorization": "Bearer \(self.credential.oauth_token)"]
            } else {
                request.headers = ["Authorization": OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: self.credential)]
            }
            request.successHandler = success
            request.failureHandler = failure
            request.dataEncoding = dataEncoding
            request.encodeParameters = true
            
            
            var parmaImage = [String: AnyObject]()
            parmaImage["media"] = image
            let boundary = "AS-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiPartBodyFromParams(parmaImage, boundary: boundary)
            
            request.HTTPBody = body
            request.contentTypeMultipart = type
            request.start()
        }
        
    }
    
    public func multiPartBodyFromParams(parameters: [String: AnyObject], boundary: String) -> NSData {
        let data = NSMutableData()
        
        let prefixData = "--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        let seperData = "\r\n".dataUsingEncoding(NSUTF8StringEncoding)
        
        for (key, value) in parameters {
            var sectionData: NSData?
            var sectionType: String?
            var sectionFilename = ""
            
            if key == "media" {
                let multiData = value as! NSData
                sectionData = multiData
                sectionType = "image/jpeg"
                sectionFilename = " filename=\"file\""
            } else {
                sectionData = "\(value)".dataUsingEncoding(NSUTF8StringEncoding)
            }
            
            data.appendData(prefixData!)
            
            let sectionDisposition = "Content-Disposition: form-data; name=\"media\";\(sectionFilename)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
            data.appendData(sectionDisposition!)
            
            if let type = sectionType {
                let contentType = "Content-Type: \(type)\r\n".dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(contentType!)
            }
            
            // append data
            data.appendData(seperData!)
            data.appendData(sectionData!)
            data.appendData(seperData!)
        }
        
        data.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return data
    }

    public func postMultiPartRequest(url: String, method: String, parameters: Dictionary<String, AnyObject>, success: OAuthSwiftHTTPRequest.SuccessHandler?, failure: OAuthSwiftHTTPRequest.FailureHandler?) {
        if let url = NSURL(string: url) {
            let request = OAuthSwiftHTTPRequest(URL: url, method: method, parameters: parameters)
            request.successHandler = success
            request.failureHandler = failure
            request.dataEncoding = dataEncoding
            request.encodeParameters = true

            let boundary = "POST-boundary-\(arc4random())-\(arc4random())"
            let type = "multipart/form-data; boundary=\(boundary)"
            let body = self.multiDataFromObject(parameters, boundary: boundary)

            request.HTTPBody = body
            request.contentTypeMultipart = type
            request.start()
        }
    }

    func multiDataFromObject(object: [String:AnyObject], boundary: String) -> NSData? {
        let data = NSMutableData()

        let prefixString = "--\(boundary)\r\n"
        let prefixData = prefixString.dataUsingEncoding(NSUTF8StringEncoding)!

        let seperatorString = "\r\n"
        let seperatorData = seperatorString.dataUsingEncoding(NSUTF8StringEncoding)!

        for (key, value) in object {

            var valueData: NSData?
            let valueType: String = ""
            let filenameClause = ""

            let stringValue = "\(value)"
            valueData = stringValue.dataUsingEncoding(NSUTF8StringEncoding)!

            if valueData == nil {
                continue
            }
            data.appendData(prefixData)
            let contentDispositionString = "Content-Disposition: form-data; name=\"\(key)\";\(filenameClause)\r\n"
            let contentDispositionData = contentDispositionString.dataUsingEncoding(NSUTF8StringEncoding)
            data.appendData(contentDispositionData!)
            if let type: String = valueType {
                let contentTypeString = "Content-Type: \(type)\r\n"
                let contentTypeData = contentTypeString.dataUsingEncoding(NSUTF8StringEncoding)
                data.appendData(contentTypeData!)
            }
            data.appendData(seperatorData)
            data.appendData(valueData!)
            data.appendData(seperatorData)
        }

        let endingString = "--\(boundary)--\r\n"
        let endingData = endingString.dataUsingEncoding(NSUTF8StringEncoding)!
        data.appendData(endingData)

        return data
    }

    public class func authorizationHeaderForMethod(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        var authorizationParameters = Dictionary<String, AnyObject>()
        authorizationParameters["oauth_version"] = OAuth.version
        authorizationParameters["oauth_signature_method"] =  OAuth.signatureMethod
        authorizationParameters["oauth_consumer_key"] = credential.consumer_key
        authorizationParameters["oauth_timestamp"] = String(Int64(NSDate().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = (NSUUID().UUIDString as NSString).substringToIndex(8)
        
        if (credential.oauth_token != ""){
            authorizationParameters["oauth_token"] = credential.oauth_token
        }
        
        for (key, value) in parameters {
            if key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        
        let combinedParameters = authorizationParameters.join(parameters)
        
        let finalParameters = combinedParameters
        
        authorizationParameters["oauth_signature"] = self.signatureForMethod(method, url: url, parameters: finalParameters, credential: credential)
        
        var parameterComponents = authorizationParameters.urlEncodedQueryStringWithEncoding(dataEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        var headerComponents = [String]()
        for component in parameterComponents {
            let subcomponent = component.componentsSeparatedByString("=") as [String]
            if subcomponent.count == 2 {
                headerComponents.append("\(subcomponent[0])=\"\(subcomponent[1])\"")
            }
        }
        
        return "OAuth " + headerComponents.joinWithSeparator(", ")
    }
    
    public class func signatureForMethod(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        var tokenSecret: NSString = ""
        tokenSecret = credential.oauth_token_secret.urlEncodedStringWithEncoding(dataEncoding)
        
        let encodedConsumerSecret = credential.consumer_secret.urlEncodedStringWithEncoding(dataEncoding)
        
        let signingKey = "\(encodedConsumerSecret)&\(tokenSecret)"
        
        var parameterComponents = parameters.urlEncodedQueryStringWithEncoding(dataEncoding).componentsSeparatedByString("&") as [String]
        parameterComponents.sortInPlace { $0 < $1 }
        
        let parameterString = parameterComponents.joinWithSeparator("&")
        let encodedParameterString = parameterString.urlEncodedStringWithEncoding(dataEncoding)
        
        let encodedURL = url.absoluteString.urlEncodedStringWithEncoding(dataEncoding)
        
        let signatureBaseString = "\(method)&\(encodedURL)&\(encodedParameterString)"
        
        let key = signingKey.dataUsingEncoding(NSUTF8StringEncoding)!
        let msg = signatureBaseString.dataUsingEncoding(NSUTF8StringEncoding)!
        let sha1 = HMAC.sha1(key: key, message: msg)!
        return sha1.base64EncodedStringWithOptions([])
    }
    
    
    // convert a Dictionary, in array of string, with escaped string
    func getEscapedArrayParam(parameters: Dictionary<String, AnyObject>) -> [String] {
        // escape all oauth parameter
        var encodedParam = [String]()
        for(k, v) in parameters {
            let str = k + "=" + (v as! String)
            let escapedStr = str.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
            encodedParam.append(escapedStr!)
        }
        // sort the result
        encodedParam.sortInPlace{ $0 < $1 }
        return encodedParam
    }
    
    // do almost like stringByAddingPercentEncodingWithAllowedCharacters, but take in account more character to be changed in %xyz
    //!*'();:@&=+$,/?%#[]
    func escapeString(str: String) -> String {
        let encoding: NSStringEncoding = NSUTF8StringEncoding
        // !*'();:@&=+$,/?%#[]
        let charactersToBeEscaped = ":/?&=;+!@#$()',*" as CFStringRef
        let charactersToLeaveUnescaped = "[]." as CFStringRef
        let raw: NSString = str
        let result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, raw, charactersToLeaveUnescaped, charactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding))
        return result as String
    }
    
    public func encodeParameters(method: String, url: NSURL, parameters: Dictionary<String, AnyObject>, credential: OAuthSwiftCredential) -> String {
        
        // algorithm used : https://dev.twitter.com/oauth/overview/creating-signatures
        // will add the oauth_signature parameter
        
        //define the oauth parameters
        var authorizationParameters = Dictionary<String, AnyObject>()
        authorizationParameters["oauth_version"] = OAuth.version
        authorizationParameters["oauth_consumer_key"] = credential.consumer_key
        authorizationParameters["oauth_timestamp"] = String(Int64(NSDate().timeIntervalSince1970))
        authorizationParameters["oauth_nonce"] = (NSUUID().UUIDString as NSString).substringToIndex(8)
        authorizationParameters["oauth_signature_method"] =  OAuth.signatureMethod
        // add token is it exist
        if (credential.oauth_token != ""){
            authorizationParameters["oauth_token"] = credential.oauth_token
        }
        // add additionnal oauth (optionnal) parameters if not already existing
        // example, oauth_callback, defined when requesting the token
        for (key, value) in parameters {
            if key.hasPrefix("oauth_") {
                authorizationParameters.updateValue(value, forKey: key)
            }
        }
        
        // escape all oauth parameter
        let encodedParam = getEscapedArrayParam(authorizationParameters)
        // convert it into a string, each param separated by &
        var outputStr:String = ""
        for v in encodedParam {
            outputStr += v + "&"
        }
        // remove last "&"
        outputStr.removeAtIndex(outputStr.endIndex.predecessor())
        // percent encode the oauth sorted, appened, parameters
        let percentOutput = self.escapeString(outputStr)
        
        // build the signature base string
        let urlPercented = self.escapeString(String(url)) //  String(url).stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())
        var signBaseString:String = method + "&" + urlPercented
        signBaseString += "&" + percentOutput
        
        // build the signin key
        let signingKey = self.escapeString( credential.consumer_secret) + "&" + self.escapeString(credential.oauth_token_secret)
        
        // Build the signature
        let sha1 = HMAC.sha1(key: signingKey.dataUsingEncoding(NSUTF8StringEncoding)!, message: signBaseString.dataUsingEncoding(NSUTF8StringEncoding)!)!
        let oauth_signature = sha1.base64EncodedStringWithOptions([])
        authorizationParameters.updateValue(self.escapeString( oauth_signature) , forKey: "oauth_signature")
        
        // add the signature to the parameters
        //encodedParam.append("oauth_signature=" + oauth_signature )
        //encodedParam.sortInPlace{ $0 < $1 } // not sure it is useful r not
        
        // create an array, with escape before =
        let newrev = authorizationParameters.sort(){ $0.0 < $1.0 }
        
        var headerComponents = [String]()
        for (key, value) in newrev {
            headerComponents.append("\(key)=\"\(value)\"")
        }
        
        
        let finalUrl:String =  "OAuth " + headerComponents.joinWithSeparator(",") // headerComponents.joinWithSeparator(", ")
        return finalUrl
    }
    
    
}
