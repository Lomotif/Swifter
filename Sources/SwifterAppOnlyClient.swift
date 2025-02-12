//
//  AppOnlyClient.swift
//  Swifter
//
//  Copyright (c) 2014 Matt Donnelly.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

internal class AppOnlyClient: SwifterClientProtocol  {
    
    var consumerKey: String
    var consumerSecret: String
    
    var credential: Credential?
    
    let dataEncoding: String.Encoding = .utf8
    
    init(consumerKey: String, consumerSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
    }
    
    func get(_ path: String,
             baseURL: TwitterURL,
             parameters: [String: Any],
             uploadProgress: HTTPRequest.UploadProgressHandler?,
             downloadProgress: HTTPRequest.DownloadProgressHandler?,
             success: HTTPRequest.SuccessHandler?,
             failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        let request = HTTPRequest(url: url!, method: .GET, parameters: parameters)
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        
        if let bearerToken = self.credential?.accessToken?.key {
            request.headers = ["Authorization": "Bearer \(bearerToken)"];
        }
        
        request.start()
        return request
    }
    
    func post(_ path: String,
              baseURL: TwitterURL,
              parameters: [String: Any],
              uploadProgress: HTTPRequest.UploadProgressHandler?,
              downloadProgress: HTTPRequest.DownloadProgressHandler?,
              success: HTTPRequest.SuccessHandler?,
              failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        let request = HTTPRequest(url: url!, method: .POST, parameters: parameters)
        request.downloadProgressHandler = downloadProgress
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        
        if let bearerToken = self.credential?.accessToken?.key {
            request.headers = ["Authorization": "Bearer \(bearerToken)"];
        } else {
            let basicCredentials = AppOnlyClient.base64EncodedCredentials(withKey: self.consumerKey, secret: self.consumerSecret)
            request.headers = ["Authorization": "Basic \(basicCredentials)"];
            request.encodeParameters = true
        }
        
        request.start()
        return request
    }
    
    func delete(_ path: String,
                baseURL: TwitterURL,
                parameters: [String: Any],
                success: HTTPRequest.SuccessHandler?,
                failure: HTTPRequest.FailureHandler?) -> HTTPRequest {
        let url = URL(string: path, relativeTo: baseURL.url)
        
        let request = HTTPRequest(url: url!, method: .DELETE, parameters: parameters)
        request.successHandler = success
        request.failureHandler = failure
        request.dataEncoding = self.dataEncoding
        
        if let bearerToken = self.credential?.accessToken?.key {
            request.headers = ["Authorization": "Bearer \(bearerToken)"];
        }
        
        request.start()
        return request
    }
    
    func signedRequest(path: String,
                       baseURL: TwitterURL,
                       method: HTTPMethodType,
                       parameters: [String : Any],
                       encodeParameters: Bool,
                       isMediaUpload: Bool) -> URLRequest {
        let url = URL(string: path, relativeTo: baseURL.url)!
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let bearerToken = self.credential?.accessToken?.key {
            request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        
        let nonOAuthParameters = parameters.filter { key, _ in !key.hasPrefix("oauth_") }
        if !nonOAuthParameters.isEmpty {
            let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(dataEncoding.rawValue))!
            if method == .GET || method == .HEAD || method == .DELETE {
                let queryString = nonOAuthParameters.urlEncodedQueryString(using: self.dataEncoding)
                request.url = url.append(queryString: queryString)
                request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
            } else {
                var queryString = ""
                if encodeParameters {
                    queryString = nonOAuthParameters.urlEncodedQueryString(using: self.dataEncoding)
                    request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
                } else {
                    queryString = nonOAuthParameters.queryString
                }

                if let data = queryString.data(using: self.dataEncoding) {
                    request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
                    request.httpBody = data
                }
            }
        }
        
        return request
    }
    
    class func base64EncodedCredentials(withKey key: String, secret: String) -> String {
        let encodedKey = key.urlEncodedString()
        let encodedSecret = secret.urlEncodedString()
        let bearerTokenCredentials = "\(encodedKey):\(encodedSecret)"
        guard let data = bearerTokenCredentials.data(using: .utf8) else {
            return ""
        }
        return data.base64EncodedString(options: [])
    }
    
}
