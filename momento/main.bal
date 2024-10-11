import ballerina/http;
import ballerinax/mongodb;

type Movie record {
    string title;
    int year;
    string genre;
    string director;
};

// MongoDB connection configuration
mongodb:ConnectionConfig mongoConfig = {
    connection: "mongodb+srv://group3:ykaNaGSKI1GQMyDG@cluster0.xi4xt0y.mongodb.net/"
};

// Create MongoDB client
mongodb:Client mongoDb = check new (mongoConfig);

// Define the service
service /movies on new http:Listener(8080) {

    // Resource to handle GET requests
    resource function get .() returns Movie[]|error {
        // Retrieve the "momento" database and "items" collection
        mongodb:Database moviesDb = check mongoDb->getDatabase("momento");
        mongodb:Collection moviesCollection = check moviesDb->getCollection("items");

        // Find all movies in the collection
        stream<record {| anydata...; |}, error?> movieStream = check moviesCollection->find();

        Movie[] movieList = [];

        // Iterate over the stream and map records to Movie type
        error? forEach = movieStream.forEach(function (record {| anydata...; |} movieItem) {
            Movie movie = mapToMovie(movieItem);
            movieList.push(movie);
        });
        if forEach is error {
            return forEach;
        }

        // Return the movie list as a JSON response
        return movieList;
    }
}

// Function to map the BSON record to Movie type
function mapToMovie(record {| anydata...; |} movieItem) returns Movie {
    return {
        title: <string> movieItem["title"],
        year: <int> movieItem["year"],
        genre: <string> movieItem["genre"],
        director: <string> movieItem["director"]
    };
}
