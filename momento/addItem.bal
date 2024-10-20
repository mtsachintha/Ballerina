import ballerina/http;
import ballerinax/mongodb;

type ProductDocument record {
    string title;
    string genre;
    string desc;
    string seller;
    string thumb;
    string img;
    int price;
    string location;
};

mongodb:ConnectionConfig mongoConfigAdd = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

mongodb:Client mongoDbAdd = check new (mongoConfigAdd);

service /products on new http:Listener(8084) {

    resource function post .(http:Caller caller, http:Request req) returns error? {
        json payload = check req.getJsonPayload();

        ProductDocument newProduct = {
            title: (check payload.title).toString(),
            genre: (check payload.genre).toString(),
            desc: (check payload.desc).toString(),
            seller: (check payload.seller).toString(),
            thumb: (check payload.thumb).toString(),
            img: (check payload.img).toString(),
            price: check payload.price,
            location: (check payload.location).toString()
        };

        mongodb:Database productDb = check mongoDb->getDatabase("momento");
        mongodb:Collection productCollection = check productDb->getCollection("items");

        var result = productCollection->insertOne(newProduct);

        if result is error {
            http:Response response = new;
            response.statusCode = 500;
            response.setPayload({ "error": "Failed to add product" });
            check caller->respond(response);
        } else {
            http:Response response = new;
            response.statusCode = 201;
            response.setPayload({ "message": "Product added successfully" });
            check caller->respond(response);
        }
    }
}
