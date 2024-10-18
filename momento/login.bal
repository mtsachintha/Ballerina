import ballerina/http;
import ballerinax/mongodb;

// MongoDB connection configuration
mongodb:ConnectionConfig mongoConfigLogin = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

// Create MongoDB client
mongodb:Client mongoDbLogin = check new (mongoConfigLogin);

// Define the service
service /login on new http:Listener(8082) {

    // Resource to handle POST requests for user login
    resource function post .(http:Caller caller, http:Request req) returns error? {
        // Get the JSON payload from the request
        json payload = check req.getJsonPayload();

        // Extract username and password from the payload
        string username = (check payload.username).toString();
        string password = (check payload.password).toString();

        // Retrieve the "collectorApp" database and "users" collection
        mongodb:Database usersDb = check mongoDbLogin->getDatabase("momento");
        mongodb:Collection usersCollection = check usersDb->getCollection("users");

json filter = { "username": username };
        // Check if the user exists
UserDocument|mongodb:DatabaseError|mongodb:ApplicationError|error|() userResult = usersCollection->findOne(<map<json>>filter);

        if userResult is UserDocument {
            // User exists, check the password
            string storedHashedPassword = userResult.password;
            string hashedPasswordInput = hashPassword(password);

            if (storedHashedPassword == hashedPasswordInput) {
                // Successful login
                http:Response response = new;
                response.statusCode = 200;  // 200 OK
                response.setPayload({ "message": "Login successful" });
                check caller->respond(response);
            } else {
                // Invalid password
                http:Response response = new;
                response.statusCode = 401;  // 401 Unauthorized
                response.setPayload({ "error": "Invalid username or password" });
                check caller->respond(response);
            }
        } else {
            // User not found
            http:Response response = new;
            response.statusCode = 404;  // 404 Not Found
            response.setPayload({ "error": "User not found" });
            check caller->respond(response);
        }
    }
}
