import ballerina/http;
import ballerinax/mongodb;
import ballerina/crypto;
import ballerina/io;

type UserDocument record {
    string username;
    string password;
};

mongodb:ConnectionConfig mongoConfigReg = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

mongodb:Client mongoDbReg = check new (mongoConfigReg);

service /register on new http:Listener(8081) {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        UserDocument newUser = {
            username: (check payload.username).toString(),
            password: (check payload.password).toString()
        };

        mongodb:Database usersDb = check mongoDb->getDatabase("momento");
        mongodb:Collection usersCollection = check usersDb->getCollection("users");

json filter = { "username": newUser.username };
io:println("Checking for existing user with filter: ", filter);

UserDocument|mongodb:DatabaseError|mongodb:ApplicationError|error|() existingUserResult = usersCollection->findOne(<map<json>>filter);

if existingUserResult is UserDocument {

    io:println("Found existing user: ", existingUserResult);
    http:Response response = new;
    response.statusCode = 409;  // 409 Conflict
    response.setPayload({ "error": "Username already taken" });
    check caller->respond(response);
    return;
}

        string hashedPassword = hashPassword(newUser.password);

        
        UserDocument userDocument = {
            username: newUser.username,
            password: hashedPassword
        };

        var result = usersCollection->insertOne(userDocument);

        if result is error {
            http:Response response = new;
            response.statusCode = 500;  
            response.setPayload({ "error": "Failed to register user" });
            check caller->respond(response);
        } else {
            http:Response response = new;
            response.statusCode = 201;  
            response.setPayload({ "message": "User registered successfully" });
            check caller->respond(response);
        }
    }
}

function hashPassword(string password) returns string {
    byte[] passwordBytes = password.toBytes();
    byte[] hashedPassword = crypto:hashSha256(passwordBytes);
    return hashedPassword.toBase16();
}
