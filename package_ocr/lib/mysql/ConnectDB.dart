import 'package:mysql_client/mysql_client.dart';
import 'package:http/http.dart' as http;

Future<void> dbConnector() async {
  print("Connecting to mysql server...");

  // MySQL 접속 설정
  final conn = await MySQLConnection.createConnection(host: "localhost", port: 3306, userName: "root", password: "wnsgus745", databaseName: "materials");
  await conn.connect();
  print("Connected");
  await conn.close();
}