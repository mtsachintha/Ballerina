import ballerina/http;
import ballerinax/mongodb;

type Item record {
    string title;
    string genre;
    string desc;
    string seller;
    string thumb;
    string img;
    int price;
    string location;
};

// MongoDB connection configuration
mongodb:ConnectionConfig mongoConfig = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

// Create MongoDB client
mongodb:Client mongoDb = check new (mongoConfig);

// Define the service
service /collectibles on new http:Listener(8080) {

    // Resource to handle GET requests
    resource function get .() returns Item[]|error {
        // Retrieve the "momento" database and "items" collection
        mongodb:Database itemsDb = check mongoDb->getDatabase("momento");
        mongodb:Collection itemsCollection = check itemsDb->getCollection("items");

        // Find all movies in the collection
        stream<record {| anydata...; |}, error?> itemStream = check itemsCollection->find();

        Item[] itemList = [];

        // Iterate over the stream and map records to Movie type
        error? forEach = itemStream.forEach(function (record {| anydata...; |} listItem) {
            Item item = mapToItem(listItem);
            itemList.push(item);
        });
        if forEach is error {
            return forEach;
        }

        // Return the movie list as a JSON response
        return itemList;
    }
}

// Function to map the BSON record to Movie type
function mapToItem(record {| anydata...; |} listItem) returns Item {
    return {
        title: <string> listItem["title"],
        genre: <string> listItem["genre"],
        desc: <string> listItem["desc"],
        seller: <string> listItem["seller"],
        thumb: <string> listItem["thumb"],
        img: <string> listItem["img"],
        price: <int> listItem["price"],
        location: <string> listItem["location"]
    };
}
