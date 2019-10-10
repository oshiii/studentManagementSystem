import ballerina/config;
import ballerina/io;
import ballerinax/java.jdbc;

# The `createDbConn` function is attached to the `studentMgtDb` object.
#
# + return - This is the description of the return value of
#            the `createDbConn` function.
public function createDbConn() returns jdbc:Client {
    jdbc:Client studentMgtDb = new ({
        url: "jdbc:mysql://" + config:getAsString("student.jdbc.dbHost") + ":" + config:getAsString("student.jdbc.dbPort") + "/" + config:getAsString("student.jdbc.db"),
        username: config:getAsString("student.jdbc.username"),
        password: config:getAsString("student.jdbc.password"),
        poolOptions: {maximumPoolSize: 5},
        dbOptions: {useSSL: false}
    });
    createTable(studentMgtDb);
    return studentMgtDb;
}

function createTable(jdbc:Client studentMgtDb) {
    io:println("The update operation - Creating a table");
    var createTable = studentMgtDb->update("CREATE TABLE IF NOT EXISTS student (std_id INT(11) NOT NULL AUTO_INCREMENT, name VARCHAR(100) NOT NULL, age INT(11) NOT NULL, address VARCHAR(200) NOT NULL, PRIMARY KEY (std_id))");
    handleDbResponse(createTable, "Create student table");
}

function handleDbResponse(jdbc:UpdateResult | jdbc:Error returned, string message) {
    if (returned is jdbc:UpdateResult) {
        io:println(message, " status: ", returned.updatedRowCount);
    } else {
        io:println(message, " failed: ", <string>returned.detail()["message"]);
}

}
