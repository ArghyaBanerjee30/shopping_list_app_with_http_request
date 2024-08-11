import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/model/grocery_item.dart';
import 'package:shopping_list_app/widget/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  void _loadItems() async {
    final url = Uri.https('flutter-prep-6ae72-default-rtdb.firebaseio.com', 'grocery-list.json');
    final response = await http.get(url);

    if(response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to fetch data. Please try again later!';
      });
    }

    if(response.body == 'null') {
      setState(() { 
        _isLoading = false;
      });
      return;
    }
    
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> tempGroceryItem = [];

    for(final item in listData.entries) {
      final tempCategory = categories.entries.firstWhere((element) => element.value.title == item.value['category']).value;
      tempGroceryItem.add(
        GroceryItem(
          id: item.key, 
          name: item.value['item_name'], 
          quantity: item.value['quantity'], 
          category: tempCategory,
        )
      );
    }

    setState(() {
      _groceryItem = tempGroceryItem;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(builder: (ctx) => const NewItem())
    );

    if(newItem == null) {
      return;
    } else {
      setState(() {
        _groceryItem.add(newItem);
      });
    }
  }

  void removeItem(GroceryItem item, final index) async {
    setState(() {
      _groceryItem.remove(item);
    });

    final url = Uri.https('flutter-prep-6ae72-default-rtdb.firebaseio.com', 'grocery-list/${item.id}.json');
    final response = await http.delete(url);

    if(response.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index, item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete ${item.name}. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet'),);

    if(_isLoading) {
      content = const Center(child: CircularProgressIndicator(),);
    }

    if(_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItem[index].id),
          onDismissed: (direction) {
            removeItem(_groceryItem[index], index);
          },
          background: Container(
            color: Theme.of(context).colorScheme.primary,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(_groceryItem[index].quantity.toString()),
          ),
        ),
      );
    }

    if(_error != null) {
      content = Center(child: Text(_error!),);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(onPressed: _addItem, icon: const Icon(Icons.add))
        ],
      ),
      body: content,
    );
  }
}