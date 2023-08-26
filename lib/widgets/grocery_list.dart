import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Text(
          textAlign: TextAlign.center,
          '${_error!} TODO; add reload button.',
          style: const TextStyle(
            backgroundColor: Colors.white12,
            color: Colors.redAccent,
          ),
        ),
      );
    } else if (_groceryItems.isEmpty) {
      content = const Center(child: Text('No items added'));
    } else {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, i) => Dismissible(
          key: ValueKey(_groceryItems[i].id),
          onDismissed: (_) => _removeItem(_groceryItems[i]),
          background: Container(
            color: Theme.of(context).colorScheme.error.withOpacity(0.75),
          ),
          child: ListTile(
            title: Text(_groceryItems[i].name),
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                color: _groceryItems[i].category.color,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ),
            trailing: Text(_groceryItems[i].quantity.toString()),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: content,
    );
  }

  void _addItem() async {
    GroceryItem? newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    final Uri url = Uri.https(
      'shopping-list-app-765f0-default-rtdb.europe-west1.firebasedatabase.app',
      'shopping-list/${item.id}.json',
    );

    int index = 0;
    setState(() {
      index = _groceryItems.indexOf(item);
      _groceryItems.remove(item);
    });
    http.Response res = await http.delete(url);
    try {
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw HttpException("${res.statusCode} ${res.body}");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete the item; ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ));
      }
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  Future<List<GroceryItem>> _fetchItems() async {
    final Uri url = Uri.https(
      'shopping-list-app-765f0-default-rtdb.europe-west1.firebasedatabase.app',
      'shopping-list.json',
    );
    http.Response res = await http.get(url);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException("${res.statusCode} ${res.body}");
    }

    final List<GroceryItem> parsedItems = [];
    if (res.body.isEmpty || res.body == "null") {
      return parsedItems;
    }
    final Map<String, dynamic> result = json.decode(res.body);
    for (final MapEntry<String, dynamic> item in result.entries) {
      parsedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: categories.values
              .firstWhere((el) => el.name == item.value['category'])));
    }
    return parsedItems;
  }

  void _loadItems() async {
    List<GroceryItem> items = [];
    String? error;
    try {
      items = await _fetchItems();
    } catch (e) {
      if (!context.mounted) return;

      error = 'Error fetching list items; ${e.toString()}';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        duration: const Duration(seconds: 2),
      ));
    } finally {
      setState(() {
        _groceryItems = items;
        _isLoading = false;
        _error = error;
      });
    }
  }
}
