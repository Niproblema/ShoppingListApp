import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/category.dart';
import 'package:shopping_list_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() {
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();

  String _enteredName = '';
  int _enteredQuantity = 1;
  Category _enteredCategory = categories[Categories.vegetables]!;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(label: Text('Name')),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1) {
                    return 'Name should have at least two characters.';
                  }
                  if (value.trim().length > 50) {
                    return 'Value too long.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredName = value!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: _enteredQuantity.toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'No quanitity provided.';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid non-numeric value provided';
                        }
                        if (int.tryParse(value)! <= 0) {
                          return 'Quantity should be greater than 0';
                        }
                        return null;
                      },
                      onSaved: (val) {
                        _enteredQuantity = int.parse(val!);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _enteredCategory,
                      onChanged: (cat) {
                        setState(() {
                          _enteredCategory = cat!;
                        });
                      },
                      items: [
                        for (final Category category in categories.values)
                          DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black12),
                                    color: category.color,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(4)),
                                  ),
                                ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(category.name)
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Add item'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSending = true;
      });

      final GroceryItem newItem;

      try {
        final Uri url = Uri.https(
          'shopping-list-app-765f0-default-rtdb.europe-west1.firebasedatabase.app',
          'shopping-list.json',
        );
        http.Response res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'name': _enteredName,
            'quantity': _enteredQuantity,
            'category': _enteredCategory.name,
          }),
        );

        if (!context.mounted) return;

        // Check response
        if (res.statusCode < 200 || res.statusCode >= 300) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Error pushing new item to server; ${res.body.toString()}'),
            duration: const Duration(seconds: 2),
          ));
          return;
        }

        // Parse response
        final Map<String, dynamic> resData = json.decode(res.body);
        newItem = GroceryItem(
          id: resData['name'],
          name: _enteredName,
          quantity: _enteredQuantity,
          category: _enteredCategory,
        );
      } finally {
        setState(() {
          _isSending = false;
        });
      }

      Navigator.of(context).pop(newItem);
    }
  }
}
