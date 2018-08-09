//
//  ServiceHttps.swift
//
//  Created by Mahipal on 07/05/18.
//  Copyright © 2018 Mahipal Singh. All rights reserved.
//

import UIKit
import SystemConfiguration



/**
 PIHttpClient is an instace class used to call API (web service) for application
 */

/**********************
 PHLog : Replacing Print and NSlog from entier project
 Command will be commented when project would go for live
 **********************/
public struct PHLog {
    static func log(value: Any) {
        print("Pharmao LOGS :: \(value)")
    }
}

class HeaderParams {
    
    func httpHeader()->[String:String] {
        let headers = [
            "Content-Type": "application/json",
            "Authorization": GlobalData.authorization,
            ]
        return headers
    }
    
    func httpStripeHeader(key:String)->[String:String]{
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": "Bearer \(key)",
        ]
        return headers
    }
}

enum RequestMethod {
    case POST
    case GET
    case PUT
    case DELETE
}

class ServiceHttps: NSObject,URLSessionDelegate {
    
    func webServiceRequest(strURl:String,parameters:NSDictionary?,method:RequestMethod,header:[String:String]?,isRawForm:Bool,uploadData:Data?,fileParameter:String?,completion: @escaping  (_ success: Bool, _ errorMessage : Error? , _ object: AnyObject? )-> ()) {
        var params = NSDictionary()
        if parameters != nil  {
            params = parameters!
        }
        
        let req = HttpMethodRequest().httpRequestGenerate(strURL: strURl, method: method, params: params, isRawData: isRawForm, imageData: uploadData, imageFileparameter: fileParameter)
        
        if header != nil {
            req.allHTTPHeaderFields = header
        }
          PHLog.log(value: strURl as AnyObject)
        HttpMethodRequest().callRequestONLY(REquest: req) { (_ success,_ error,_ obj) in
            completion(success,error, obj)
        }
    }
}

//MARK: - CALL ONLY REQUEST (REST OF PARAMS ARE IN VIEWCONTROLLER)
/**
 MARK: GENERATE REQUEST AND CALL SEPRATE WHEN NET AVAILABLE
 -- methods will call only under PIHttps class.
 */
class HttpMethodRequest: PHHttpClient {
    func httpRequestGenerate(strURL:String,method:RequestMethod,params:NSDictionary,isRawData:Bool,imageData:Data?,imageFileparameter:String?)->NSMutableURLRequest {
        let encodeURL = strURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let request = NSMutableURLRequest(url: NSURL(string:encodeURL!)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        
        if method == .GET || method == .DELETE{
            request.httpMethod = method == .GET ? "GET" : "DELETE"
            return request
        }
        
        if method == .POST || method == .PUT {
            request.httpMethod = method == .POST ? "POST" : "PUT"
            if isRawData { //Raw never support image data, we need to upload through base64 encoded data string.
                do {
                    let body = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                    request.httpBody = body as Data
                    return request
                }
                catch{
                    PHLog.log(value: "Error while generating Json")
                }
            }else {
                
                if imageData != nil { //Support Image Data
                    let boundary = "Boundary-\(NSUUID().uuidString)"
                    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                    let body = NSMutableData()
                    for (key, value) in params {
                        body.appendString(string: "--\(boundary)\r\n")
                        body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                        body.appendString(string: "\(value)\r\n")
                    }
                    
                    if let _ = imageData {
                        let filename = "\(Date().timeIntervalSince1970*1000).png"
                        let mimetype = "image/png"
                        body.appendString(string: "--\(boundary)\r\n")
                        body.appendString(string: "Content-Disposition: form-data; name=\"\(imageFileparameter!)\"; filename=\"\(filename)\"\r\n")
                        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
                        body.append(imageData!)
                        body.appendString(string: "\r\n")
                        body.appendString(string: "--\(boundary)--\r\n")
                    }
                    request.httpBody = body as Data
                }else {
                    
                    let body = NSMutableData()
                    for (offset: index, element: (key: key, value: value)) in params.enumerated() {
                        var parmsStr = (key as! String)
                        if index > 0 {
                            parmsStr = "&\(parmsStr)"
                        }
                        parmsStr = parmsStr+"="+(value as! String)
                        body.append(parmsStr.data(using: String.Encoding.utf8)!)
                    }
                    request.httpBody = body as Data
                }
            }
            return request
        }else {
            return request
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, urlCredential)
    }
    
    func callRequestONLY(REquest:NSMutableURLRequest, completion: @escaping (_ success: Bool, _ error: Error?, _ object: AnyObject?) -> ()) {
        
        let urlconfig = URLSessionConfiguration.default
        //       urlconfig.httpMaximumConnectionsPerHost = 100
        urlconfig.requestCachePolicy = .reloadIgnoringCacheData
        urlconfig.timeoutIntervalForRequest = 480
        let session = URLSession(configuration: urlconfig, delegate:self , delegateQueue:nil)
        
        let task = session.dataTask(with: REquest as URLRequest) {
            (data, response, error) -> Void in
            //            PHLog.log(value: response as AnyObject)
            if error != nil {
                if error?.localizedDescription == "cancelled" {
                    completion(false, error , error?.localizedDescription as AnyObject?)
                    return
                }
                PHLog.log(value: error?.localizedDescription as AnyObject)
                //TODO: NIWrapper.nativeAlertView(title: "Error", body: error?.localizedDescription ?? "")
                completion(false, error , error?.localizedDescription as AnyObject?)
                return
            }
            
            if data == nil {
                PHLog.log(value: "url Request: \(String(describing: REquest.url))" as AnyObject)
                //TODO: NIWrapper.nativeAlertView(title: "Error", body: response.debugDescription )
                completion(false,error, response.debugDescription as AnyObject?)
                return
            } else {
                let str = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                PHLog.log(value: str as AnyObject)
                let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                
                if let responsejson = json {
                   
                    if responsejson is Dictionary<String,AnyObject> {
                        let object = responsejson as! Dictionary<String,AnyObject>
                        if object["code"] != nil {
                            let statusResult =  object["code"] as! String //stat
                            if statusResult == "401" {
                               //Logout User
                                 completion(true, error , responsejson as AnyObject?)
                            }else {
                                 completion(true, error , responsejson as AnyObject?)
                            }
                        }else{
                             completion(true, error , responsejson as AnyObject?)
                        }
                     }else {
                         completion(true, error , responsejson as AnyObject?)
                    }
                     return
                } else {
                    completion(false, error , str as AnyObject?)
                    return
                }
            }
        }
        task.resume()
    }
}


