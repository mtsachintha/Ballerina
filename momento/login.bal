import ballerina/http;
import ballerinax/mongodb;

mongodb:ConnectionConfig mongoConfigLogin = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

mongodb:Client mongoDbLogin = check new (mongoConfigLogin);

service /login on new http:Listener(8082) {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        string username = (check payload.username).toString();
        string password = (check payload.password).toString();

        mongodb:Database usersDb = check mongoDbLogin->getDatabase("momento");
        mongodb:Collection usersCollection = check usersDb->getCollection("users");

json filter = { "username": username };
UserDocument|mongodb:DatabaseError|mongodb:ApplicationError|error|() userResult = usersCollection->findOne(<map<json>>filter);

        if userResult is UserDocument {
            string storedHashedPassword = userResult.password;
            string hashedPasswordInput = hashPassword(password);

            if (storedHashedPassword == hashedPasswordInput) {
                http:Response response = new;
                response.statusCode = 200;  
                response.setPayload({ "message": "Login successful" });
                check caller->respond(response);
            } else {
                http:Response response = new;
                response.statusCode = 401;
                response.setPayload({ "error": "Invalid username or password" });
                check caller->respond(response);
            }
        } else {
            http:Response response = new;
            response.statusCode = 404;
            response.setPayload({ "error": "User not found" });
            check caller->respond(response);
        }
    }
}
