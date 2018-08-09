# WebServicesMethod
ServiceHttps is Wrapper class for URLSession with following Methods
1.  PUT
2.  POST
3.  DELETE
4.  GET

Methods will accept Raw Data and Form data 

# How to Use
  1.  Drag ServiceHttps file in Project.
  2. Now for any request , Example
```
var params = ["password" : 12346,
               "login_type": "Mahipal singh",
               "state": true]
    

  ServiceHttps().webServiceRequest(strURl: API_URL, parameters: params, method: .POST, header: HeaderParams().httpHeader(), isRawForm: true, uploadData: nil, fileParameter: nil) { (_ success, _ error, _ result) in
             if success {
                if result is Dictionary<String,AnyObject> {
                    let object = result as!  Dictionary<String,AnyObject>
                     let statusResult = object["code"]
                      if statusResult == "200" {
                         completion(nil,statusResult,true)
                      } else {
                        
                        completion(object["error"] as! String,statusResult,false)
                    }
                }
            } else {
                completion(error?.localizedDescription ?? "SERVER_NOT_RESPONDING",nil,false)
            }
        }
```
