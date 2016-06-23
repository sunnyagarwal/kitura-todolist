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

import Foundation

import TodoListAPI

/**
 Because bridging is not complete in Linux, we must use Any objects for dictionaries
 instead of AnyObject. The main branch SwiftyJSON takes as input AnyObject, however
 our patched version for Linux accepts Any.
 */
#if os(OSX)
    typealias JSONDictionary = [String: AnyObject]
#else
    typealias JSONDictionary = [String: Any]
#endif

protocol DictionaryConvertible {
    func toDictionary() -> JSONDictionary
}

extension TodoItem : DictionaryConvertible {

    var url: String {

        return config.url + "/" + config.firstPathSegment + "/" + id
    }

    func toDictionary() -> JSONDictionary {
        var result = JSONDictionary()
        result["id"] = self.id
        result["user"] = self.user
        result["order"] = self.order
        result["title"] = self.title
        result["completed"] = self.completed
        result["url"] = self.url

        return result
    }

}

extension Array where Element : DictionaryConvertible {

    func toDictionary() -> [JSONDictionary] {

        return self.map { $0.toDictionary() }

    }

}
