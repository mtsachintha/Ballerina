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

mongodb:ConnectionConfig mongoConfig = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

mongodb:Client mongoDb = check new (mongoConfig);

service /collectibles on new http:Listener(8080) {

    resource function get .() returns Item[]|error {
        mongodb:Database itemsDb = check mongoDb->getDatabase("momento");
        mongodb:Collection itemsCollection = check itemsDb->getCollection("items");

        stream<record {| anydata...; |}, error?> itemStream = check itemsCollection->find();

        Item[] itemList = [];

        error? forEach = itemStream.forEach(function (record {| anydata...; |} listItem) {
            Item item = mapToItem(listItem);
            itemList.push(item);
        });
        if forEach is error {
            return forEach;
        }

        return itemList;
    }
}

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
