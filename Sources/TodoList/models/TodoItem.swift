/**
* Copyright IBM Corporation 2016
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
**/

struct TodoItem {

    /// ID
    var id: String = ""

    // Order
    var order: Int = 0

    /// Text to display
    var title: String = ""

    /// Whether completed or not
    var completed: Bool = false

    /// Full path URL to the resource
    /// ex. http://localhost:8090/todos/508
    ///
    var url: String {
        if let url = config.url {
            return url + "/" + config.firstPathSegment + "/" + id
        } else {
            return ""
        }
    }
    
    ///
    /// Transform the structure to a Dictionary
    ///
    /// Returns: a Dictionary populated with fields.
    ///
    func serialize() -> JSONDictionary {
         var result = JSONDictionary()
        
#if os(Linux)
        result["id"] = id as Any
        result["order"] = order as Any
        result["title"] = title as Any
        result["completed"] = completed as Any
        result["url"] = url as Any
#else
        result["id"] = id as AnyObject
        result["order"] = order as AnyObject
        result["title"] = title as AnyObject
        result["completed"] = completed as AnyObject
        result["url"] = url as AnyObject
#endif
        
        return result
    }

}
