import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'services/chat_service.dart';
import 'services/user_service.dart';
import 'chat_screen.dart';
import 'theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  String searchQuery = '';
  bool showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
              )
            : Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          if (showSearchBar)
            IconButton(
              icon: Icon(Icons.close, color: isDark ? Colors.white : const Color(0xFF6B7280)),
              onPressed: () {
                setState(() {
                  showSearchBar = false;
                  searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.search,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    size: 18,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    showSearchBar = true;
                  });
                },
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: isDark ? Colors.red[400] : Colors.red[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading chats',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF374151),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3B82F6),
                strokeWidth: 2.5,
              ),
            );
          }

          final chatRooms = snapshot.data ?? [];
          // Debug print to show all chat rooms received
          debugPrint('Chat rooms received for user: ${FirebaseAuth.instance.currentUser?.uid}');
          for (final chatRoom in chatRooms) {
            debugPrint('ChatRoom: id=${chatRoom['id']}, participants=${chatRoom['participants']}');
          }

          final filteredChatRooms = chatRooms.where((chatRoom) {
            if (searchQuery.isEmpty) return true;
            // Get the other participant's ID
            final participants = Map<String, dynamic>.from(chatRoom['participants'] ?? {});
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            final otherUserId = participants.keys.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            // For now, we'll filter by the other user's ID
            // In a real app, you'd want to fetch user details and filter by username
            return otherUserId.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          if (filteredChatRooms.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 40,
                        color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      searchQuery.isEmpty ? 'No messages yet' : 'No chats found',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF374151),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      searchQuery.isEmpty 
                          ? 'Start a conversation with someone'
                          : 'Try a different search term',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredChatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = filteredChatRooms[index];
              final participants = Map<String, dynamic>.from(chatRoom['participants'] ?? {});
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final otherUserId = participants.keys.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
              return _buildChatItem(context, chatRoom, otherUserId, isDark);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chatRoom, String otherUserId, bool isDark) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(otherUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildChatItemShimmer(isDark);
        }

        final otherUserData = userSnapshot.data;
        debugPrint('Fetched user data for $otherUserId: $otherUserData');
        final otherUsername = (otherUserData != null && otherUserData.containsKey('username'))
            ? otherUserData['username']
            : otherUserId; // fallback to UID if username missing
        final profileImageUrl = otherUserData?['profileImageUrl'] ?? '';
        final lastMessage = chatRoom['lastMessage'] ?? '';
        final lastMessageTime = chatRoom['lastMessageTime'] ?? 0;
        final lastSenderId = chatRoom['lastSenderId'] ?? '';
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

        // Show who sent the last message
        String lastMessagePrefix = '';
        if (lastSenderId == otherUserId) {
          lastMessagePrefix = '$otherUsername: ';
        } else {
          lastMessagePrefix = 'You: ';
        }

        // Filter by search query
        if (searchQuery.isNotEmpty &&
            !otherUsername.toLowerCase().contains(searchQuery.toLowerCase())) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF23262F) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: otherUserId,
                      otherUserName: otherUsername,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile Image
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: profileImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: profileImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                  child: Icon(
                                    Icons.person,
                                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                  child: Icon(
                                    Icons.person,
                                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              )
                            : Container(
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                                child: Icon(
                                  Icons.person,
                                  color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Chat Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherUsername, // Only show the other user's name as the room name
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (lastMessageTime > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(lastMessageTime),
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            // Show who sent the last message
                            '$lastMessagePrefix$lastMessage',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatItemShimmer(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23262F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Shimmer profile image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(width: 12),
          // Shimmer text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      return await _userService.getUserData(userId);
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  String _formatTime(int timestamp) {
    final now = DateTime.now();
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}