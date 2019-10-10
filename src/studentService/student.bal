import ballerina/config;
import ballerina/http;
import ballerina/io;
import ballerina/jsonutils;
import ballerinax/java.jdbc;

jdbc:Client stdMgtDB = createDbConn();

type Student record {
    int std_id;
    string name;
    int age;
    string address;
};

listener http:Listener studentMgtServiceListener = new (config:getAsInt("student.listener.port"));

@http:ServiceConfig {
    basePath: "/students"
}

service studentMgtService on studentMgtServiceListener {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/"
    }
    resource function getStudent(http:Caller caller, http:Request req) {
        io:println("\nThe select operation - Select students from db");
        io:println(config:getAsString("student.jdbc.username"));
        var selectStudents = stdMgtDB->select("SELECT * FROM student", Student);
        http:Response response = new;
        if (selectStudents is table<Student>) {
            json jsonConversionRet = jsonutils:fromTable(selectStudents);
            response.setJsonPayload(jsonConversionRet);
            response.statusCode = 200;
        } else {
            response.setPayload("Error occured in get students");
            response.statusCode = 500;
        }
        checkpanic caller->respond(response);
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/addStudent",
        body: "std",
        consumes: ["application/json"]
    }

    resource function addStudent(http:Caller caller, http:Request req, Student std) {
        io:println("\nThe Create table operation - Create students table if not exists");
        io:println("\nThe Insert operation - Insert students to db");

        int sId = std.std_id;
        var sName = std.name;
        int sAge = std.age;
        var sAddress = std.address;

        var addStudents = stdMgtDB->update("INSERT INTO student(std_id, name, age, address) VALUES (?, ?, ?, ?)", sId, sName, sAge, sAddress);

        handleUpdate(addStudents, caller, "Add Student", true);
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/deleteStudent/{std_id}"
    }

    resource function deleteStudent(http:Caller caller, http:Request req, string std_id) {
        io:println("\nThe Delete operation - Delete student with std_id " + std_id);
        var deleteStudents = stdMgtDB->update("DELETE FROM student WHERE std_id = ?", std_id);
        handleUpdate(deleteStudents, caller, "Delete Student", true);
    }

}

function handleUpdate(jdbc:UpdateResult | error returned, http:Caller caller, string message, boolean isRespond) {

    if (returned is jdbc:UpdateResult) {
        io:println(message, " status: ", returned.updatedRowCount);
        if (isRespond) {
            sendResponse(caller, message + " Successful", 200);
        }
    } else {
        error err = returned;
        io:println(message, " failed: ", <string>err.detail()["message"]);
        if (isRespond) {
            sendResponse(caller, "Unable to " + message, 500);
        }
    }
}

function sendResponse(http:Caller caller, string payloadMsg, int statusCode) {
    http:Response response = new;
    response.setPayload(payloadMsg);
    response.statusCode = statusCode;
    checkpanic caller->respond(response);
}






