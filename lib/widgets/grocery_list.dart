import 'package:flutter/material.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_groceryItems.isEmpty) {
      content = const Center(child: Text('No items added'));
    } else {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, i) => Dismissible(
          key: ValueKey(_groceryItems[i].id),
          onDismissed: (_) {
            setState(() {
              _groceryItems.removeAt(i);
            });
          },
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
}
