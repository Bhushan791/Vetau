// lib/components/comments/comment_input.dart
import 'package:flutter/material.dart';

class CommentInput extends StatefulWidget {
  final String hint;
  final Future<void> Function(String) onSend;
  final void Function()? onCancelReply;
  final String? replyingToName;

  const CommentInput({
    super.key,
    required this.onSend,
    this.hint = "Add a comment...",
    this.onCancelReply,
    this.replyingToName,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    await widget.onSend(text);
    setState(() => _isPosting = false);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.replyingToName != null)
          Row(
            children: [
              Expanded(child: Text("Replying to ${widget.replyingToName!}", style: TextStyle(color: Colors.grey[700]))),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onCancelReply,
              )
            ],
          ),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration.collapsed(hintText: widget.hint),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    IconButton(
                      icon: _isPosting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.blue),
                      onPressed: _isPosting ? null : _send,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
