import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:flutter_network_logger/flutter_network_logger.dart';

class NetworkLoggerExample extends StatefulWidget {
  const NetworkLoggerExample({super.key});

  @override
  State<NetworkLoggerExample> createState() => _NetworkLoggerExampleState();
}

class _NetworkLoggerExampleState extends State<NetworkLoggerExample> {
  late Dio dio;
  late HttpClient httpClient;
  late GraphQLClient graphQLClient;

  @override
  void initState() {
    dio = Dio();
    httpClient = HttpClient();
    graphQLClient = GraphQLClient(
      link: HttpLink('https://graphqlzero.almansi.me/api'),
      cache: GraphQLCache(),
    );
    super.initState();
  }

  @override
  void dispose() {
    dio.close();
    httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                // dio example
                final response = await dio.get(
                  'https://jsonplaceholder.typicode.com/posts/1',
                );
                log(response.data.toString());
              },
              child: const Text('Dio'),
            ),
            ElevatedButton(
              onPressed: () async {
                // http client example
                final request = await httpClient.getUrl(
                  Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
                );
                final response = await request.close();
                log(response.toString());
              },
              child: const Text('HttpClient'),
            ),
            ElevatedButton(
              onPressed: () async {
                // graphql example
                final QueryResult result = await graphQLClient.query(
                  QueryOptions(
                    document: gql('''
                    query GetPost {
                      post(id: 1) {
                        id
                        title
                      }
                    }
                  '''),
                  ),
                );
                log(result.data.toString());
              },
              child: const Text('GraphQL'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NetworkLoggerScreen.show(context);
        },
        child: const Icon(Icons.wifi),
      ),
    );
  }
}
