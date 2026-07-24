import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/presentation/screens/chats/chat_detail_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:chatappui/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final SearchProvider _searchProvider;

  @override
  void initState() {
    super.initState();
    _searchProvider = SearchProvider()..initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchProvider.dispose();
    super.dispose();
  }

  Future<void> _openChat(BuildContext context, UserModel user) async {
    await context.read<SearchProvider>().saveHistoryItem(user.username);
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(otherUser: user),
      ),
    );
  }

  void _applyHistoryItem(BuildContext context, String username) {
    _searchController.text = username;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: username.length),
    );
    context.read<SearchProvider>().selectHistoryItem(username);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchProvider>.value(
      value: _searchProvider,
      child: Scaffold(
        appBar: AppBar(
          title: UiHelper.customText(
            text: 'Contacts',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            context: context,
          ),
          actions: [UiHelper.darkModeToggle(context)],
        ),
        body: Consumer<SearchProvider>(
          builder: (context, searchProvider, _) {
            final hasQuery = _searchController.text.trim().isNotEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: UiHelper.customTextField(
                    controller: _searchController,
                    hintText: 'Search by username...',
                    prefixIcon: Icons.search,
                    context: context,
                    textInputAction: TextInputAction.search,
                    suffixIcon: hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              searchProvider.onQueryChanged('');
                            },
                          )
                        : null,
                    onChanged: searchProvider.onQueryChanged,
                    onSubmitted: (value) {
                      searchProvider.searchUsers(
                        value,
                        saveHistory: value.trim().isNotEmpty,
                      );
                    },
                  ),
                ),
                if (searchProvider.isSearching)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: hasQuery
                      ? _SearchResultsList(
                          users: searchProvider.results,
                          query: _searchController.text.trim(),
                          onTapUser: (user) => _openChat(context, user),
                        )
                      : _SearchHistoryList(
                          history: searchProvider.history,
                          onTapItem: (username) =>
                              _applyHistoryItem(context, username),
                          onDeleteItem: (username) {
                            searchProvider.deleteHistoryItem(username);
                          },
                          onClearAll: searchProvider.clearHistory,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<UserModel> users;
  final String query;
  final ValueChanged<UserModel> onTapUser;

  const _SearchResultsList({
    required this.users,
    required this.query,
    required this.onTapUser,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: UiHelper.customText(
            text: 'No users found for "$query".',
            fontSize: 14,
            textAlign: TextAlign.center,
            context: context,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, __) => UiHelper.sectionDivider(context),
      itemBuilder: (context, index) {
        final user = users[index];

        return ListTile(
          leading: UiHelper.avatar(
            name: user.displayName,
            photoUrl: user.photoUrl,
          ),
          title: UiHelper.customText(
            text: user.displayName,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            context: context,
          ),
          subtitle: UiHelper.customText(
            text: '@${user.username}',
            fontSize: 12,
            context: context,
            color: Colors.grey,
          ),
          trailing: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: user.isOnline ? Colors.green : Colors.grey,
            ),
          ),
          onTap: () => onTapUser(user),
        );
      },
    );
  }
}

class _SearchHistoryList extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onTapItem;
  final ValueChanged<String> onDeleteItem;
  final Future<void> Function() onClearAll;

  const _SearchHistoryList({
    required this.history,
    required this.onTapItem,
    required this.onDeleteItem,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: UiHelper.customText(
            text: 'Search for a username to start a new chat.',
            fontSize: 14,
            textAlign: TextAlign.center,
            context: context,
            color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.7,
                ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: UiHelper.customText(
                text: 'Recent Searches',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                context: context,
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...history.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text('@$item'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => onDeleteItem(item),
              ),
              onTap: () => onTapItem(item),
            ),
          ),
        ),
      ],
    );
  }
}
