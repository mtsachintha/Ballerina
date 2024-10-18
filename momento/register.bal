import ballerina/http;
import ballerinax/mongodb;
import ballerina/crypto;
import ballerina/io;

// Define the user record type
type UserDocument record {
    string username;
    string password;
};

// MongoDB connection configuration
mongodb:ConnectionConfig mongoConfigReg = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

// Create MongoDB client
mongodb:Client mongoDbReg = check new (mongoConfigReg);

// Define the service
service /register on new http:Listener(8081) {

    // Resource to handle POST requests for user registration
    resource function post .(http:Caller caller, http:Request req) returns error? {
        // Get the JSON payload from the request
        json payload = check req.getJsonPayload();

        // Create a User record from the payload
        UserDocument newUser = {
            username: (check payload.username).toString(),
            password: (check payload.password).toString()
        };

        // Retrieve the "collectorApp" database and "users" collection
        mongodb:Database usersDb = check mongoDb->getDatabase("momento");
        mongodb:Collection usersCollection = check usersDb->getCollection("users");

        // Check if username already exists
json filter = { "username": newUser.username };
io:println("Checking for existing user with filter: ", filter);

// Query the collection for the existing user
// Specify that we expect a UserDocument or error
UserDocument|mongodb:DatabaseError|mongodb:ApplicationError|error|() existingUserResult = usersCollection->findOne(<map<json>>filter);

if existingUserResult is UserDocument {

    // User already exists
    io:println("Found existing user: ", existingUserResult);
    http:Response response = new;
    response.statusCode = 409;  // 409 Conflict
    response.setPayload({ "error": "Username already taken" });
    check caller->respond(response);
    return;
}

        // Hash the password before storing it in the database
        string hashedPassword = hashPassword(newUser.password);

        // Create the user document
        
        // Create the user document using the defined record type
        UserDocument userDocument = {
            username: newUser.username,
            password: hashedPassword
        };

        // Insert the new user into the MongoDB collection
        var result = usersCollection->insertOne(userDocument);

        if result is error {
            http:Response response = new;
            response.statusCode = 500;  // 500 Internal Server Error
            response.setPayload({ "error": "Failed to register user" });
            check caller->respond(response);
        } else {
            http:Response response = new;
            response.statusCode = 201;  // 201 Created
            response.setPayload({ "message": "User registered successfully" });
            check caller->respond(response);
        }
    }
}

// Utility function to hash the password using SHA-256
function hashPassword(string password) returns string {
    byte[] passwordBytes = password.toBytes();
    byte[] hashedPassword = crypto:hashSha256(passwordBytes);
    return hashedPassword.toBase16();
}
