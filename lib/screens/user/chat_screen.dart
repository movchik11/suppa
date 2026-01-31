import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/chat_cubit.dart';
import 'package:supa/models/chat_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String serviceName;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.serviceName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatCubit(widget.orderId)..subscribeToMessages(),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('chatWithMaster'.tr(), style: const TextStyle(fontSize: 18)),
              Text(
                widget.serviceName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        body: BlocListener<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state is ChatError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const AppLoadingIndicator();
                    }
                    if (state is ChatLoaded) {
                      final messages = state.messages;
                      if (messages.isEmpty) {
                        return Center(child: Text('startConversation'.tr()));
                      }

                      // Auto scroll to bottom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe =
                              msg.senderId ==
                              Supabase.instance.client.auth.currentUser?.id;
                          return _buildMessageBubble(msg, isMe);
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              _buildInputArea(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF673AB7) : Colors.white12,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: msg.imageUrl!,
                  placeholder: (context, url) =>
                      Container(height: 150, color: Colors.white10),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (msg.text != null && msg.text!.isNotEmpty)
              Text(
                msg.text!,
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(
                color:
                    (isMe
                            ? Colors.white
                            : Theme.of(context).textTheme.bodySmall?.color)
                        ?.withAlpha(150),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blue),
            onPressed: () async {
              final XFile? image = await _picker.pickImage(
                source: ImageSource.gallery,
              );
              if (image != null && mounted) {
                // Since this might be called outside the build method where the provider is
                // We need to re-fetch the cubit or use a builder around the input area
                final cubit = BlocProvider.of<ChatCubit>(context);
                cubit.sendMessage(image: image);
              }
            },
          ),
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: 'typeMessage'.tr(),
                fillColor: Theme.of(context).cardColor.withAlpha(153),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF673AB7),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_msgController.text.isNotEmpty) {
                  final cubit = BlocProvider.of<ChatCubit>(context);
                  cubit.sendMessage(text: _msgController.text);
                  _msgController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
