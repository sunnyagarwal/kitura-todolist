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

import Kitura
import KituraNet

import LoggerAPI
import SwiftyJSON

import TodoListAPI

import Credentials
import CredentialsFacebookToken

final class TodoListController {

    let todos: TodoListAPI
    let router = Router()

    let credentials = Credentials()
    let fbCredentialsPlugin = CredentialsFacebookToken()

    init(backend: TodoListAPI) {
        self.todos = backend

        credentials.register(plugin: fbCredentialsPlugin)

        _setupRoutes()

    }

    private func _setupRoutes() {

        let id = "\(config.firstPathSegment)/:id"

        router.all("/*", middleware: BodyParser())
        router.all("/*", middleware: AllRemoteOriginMiddleware())
        router.all("/*", middleware: credentials)
        //router.post("/", middleware: credentials)
        router.get("/", middleware: credentials)
        router.get("/", handler: self.get)
        router.get(id, handler: getByID)
        router.options("/*", handler: getOptions)
        //router.post("/", middleware: credentials)
        router.post("/", handler: addItem )
        router.post(id, handler: postByID)
        router.patch(id, handler: updateItemByID)
        router.delete(id, handler: deleteByID)
        router.delete("/", handler: deleteAll)
    }


    private func get(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        guard let profile = request.userProfile else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain facebook user profile")
            return
        }

        let userId = profile.id
        todos.get(withUserID: userId) {
            todos, error in
            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                let json = JSON(todos.toDictionary())
                try response.status(HTTPStatusCode.OK).send(json: json).end()
            } catch {

            }
        }

    }

    private func getByID(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        guard let id = request.params["id"] else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain ID")
            return
        }

        guard let profile = request.userProfile else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain facebook user profile")
            return
        }

        let user = profile.id

        todos.get(withUserID: user, withDocumentID: id) {
            item, error in

            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                if let item = item {
                    let result = JSON(item.toDictionary())

                    try response.status(HTTPStatusCode.OK).send(json: result).end()

                } else {
                    Log.warning("Could not find the item")
                    response.status(HTTPStatusCode.badRequest)
                    return
                }
            } catch {

            }

        }

    }

    private func getOptions(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        response.headers["Access-Control-Allow-Headers"] = "accept, content-type"
        response.headers["Access-Control-Allow-Methods"] = "GET,HEAD,POST,DELETE,OPTIONS,PUT,PATCH"

        response.status(HTTPStatusCode.OK)

        next()

    }

    private func addItem(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        guard let body = request.body else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("No body found in request")
            return
        }

        guard case let .json(json) = body else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Body is invalid JSON")
            return
        }

        guard let profile = request.userProfile else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain facebok user profile")
            return
        }

        let title = json["title"].stringValue
        let order = json["order"].intValue
        let completed = json["completed"].boolValue

        Log.info("Received \(title)")


        todos.add(userID: profile.id, title: title, order: order, completed: completed) {
            newItem, error in
            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }

                let result = JSON(newItem.toDictionary())

                do {
                    try response.status(HTTPStatusCode.OK).send(json: result).end()
                } catch {
                    Log.error("Error sending response")
                }
            } catch {
                Log.error("")

            }

        }

    }

    private func postByID(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        guard let id = request.params["id"] else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("id parameter not found in request")
            return
        }

        guard let body = request.body else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("No body found in request")
            return
        }

        guard case let .json(json) = body else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Body is invalid JSON")
            return
        }
        
        guard let profile = request.userProfile else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain facebok user profile")
            return
        }

        let user = profile.id
        let title = json["title"].stringValue
        let order = json["order"].intValue
        let completed = json["completed"].boolValue

        todos.update(documentID: id, userID: user, title: title, order: order, completed: completed) {
            newItem, error in

            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                let result = JSON(newItem!.toDictionary())

                response.status(HTTPStatusCode.OK).send(json: result)
            } catch {

            }

        }

    }

    private func updateItemByID(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        guard let id = request.params["id"] else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("id parameter not found in request")
            return
        }

        guard let body = request.body else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("No body found in request")
            return
        }

        guard case let .json(json) = body else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Body is invalid JSON")
            return
        }

        let user = json["user"].stringValue
        let title = json["title"].stringValue
        let order = json["order"].intValue
        let completed = json["completed"].boolValue

        todos.update(documentID: id, userID: user, title: title, order: order, completed: completed) {
            newItem, error in

            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }

                if let newItem = newItem {

                    let result = JSON(newItem.toDictionary())

                    do {
                        try response.status(HTTPStatusCode.OK).send(json: result).end()
                    } catch {
                        Log.error("Error sending response")
                    }
                }
            } catch {

            }


        }
    }

    private func deleteByID(request: RouterRequest, response: RouterResponse, next: () -> Void) {

        Log.info("Requesting a delete")

        guard let id = request.params["id"] else {
            Log.warning("Could not parse ID")
            response.status(HTTPStatusCode.badRequest)
            return
        }

        guard let profile = request.userProfile else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain facebok user profile")
            return
        }

        todos.delete(withUserID: profile.id, withDocumentID: id) {
            error in

            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                try response.status(HTTPStatusCode.OK).end()
            } catch {
                Log.error("Could not produce response")
            }

        }

    }

    private func deleteAll(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        Log.info("Requested clearing the entire list")
        guard let profile = request.userProfile else {
            response.status(HTTPStatusCode.badRequest)
            Log.error("Request does not contain facebok user profile")
            return
        }
        todos.clear(withUserID: profile.id) {
            error in
            do {
                guard error == nil else {
                    try response.status(HTTPStatusCode.badRequest).end()
                    Log.error(error.debugDescription)
                    return
                }
                try response.status(HTTPStatusCode.OK).end()
            } catch {
                Log.error("Could not produce response")
            }
        }

    }


}
