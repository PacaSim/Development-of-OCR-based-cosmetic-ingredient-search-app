import 'package:mysql_client/mysql_client.dart';
import 'package:http/http.dart' as http;

Future<void> dbConnector() async {
  print("Connecting to mysql server...");

  // MySQL 접속 설정
  final conn = await MySQLConnection.createConnection(host: "", port: , userName: "", password: "", databaseName: "");
  await conn.connect();
  print("Connected");
  await conn.close();
}
