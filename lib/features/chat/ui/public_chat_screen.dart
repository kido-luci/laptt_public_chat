import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:public_chat/_shared/bloc/user_manager/user_manager_cubit.dart';
import 'package:public_chat/_shared/data/chat_data.dart';
import 'package:public_chat/_shared/widgets/chat_bubble_widget.dart';
import 'package:public_chat/_shared/widgets/language_button_widget.dart';
import 'package:public_chat/_shared/widgets/message_box_widget.dart';
import 'package:public_chat/features/chat/bloc/chat_cubit.dart';
import 'package:public_chat/utils/locale_support.dart';

class PublicChatScreen extends StatelessWidget {
  const PublicChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (context) => ChatCubit(),
      child: const _PublicChatScreenBody(),
    );
  }
}

class _PublicChatScreenBody extends StatelessWidget {
  const _PublicChatScreenBody();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
        appBar: AppBar(
          title: Text(context.locale.publicRoomTitle),
          actions: const [
            LanguageButtonWidget(
              onlyAppLanguage: false,
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  return FirestoreListView<Message>(
                    query: context.read<ChatCubit>().chatContent,
                    reverse: true,
                    itemBuilder: (BuildContext context,
                        QueryDocumentSnapshot<Message> doc) {
                      if (!doc.exists) {
                        return const SizedBox.shrink();
                      }

                      final Message message = doc.data();

                      //lapl1412: i think user need to cache to improve the performance
                      return BlocProvider<UserManagerCubit>.value(
                        value: UserManagerCubit()
                          ..queryUserDetail(message.sender),
                        child: BlocBuilder<UserManagerCubit, UserManagerState>(
                          builder: (context, state) {
                            String? photoUrl;
                            String? displayName;

                            if (state is UserDetailState) {
                              photoUrl = state.photoUrl;
                              displayName = state.displayName;
                            }

                            return ChatBubble(
                                key: Key(message.id),
                                isMine: message.sender == user?.uid,
                                message: message.message,
                                photoUrl: photoUrl,
                                displayName: displayName,
                                translations: message.translations);
                          },
                        ),
                      );
                    },
                    emptyBuilder: (context) => const Center(
                      child: Text(
                          'No messages found. Send the first message now!'),
                    ),
                    loadingBuilder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
            MessageBox(
              onSendMessage: (value) {
                if (user == null) {
                  // do nothing
                  return;
                }

                context
                    .read<ChatCubit>()
                    .sendChat(uid: user.uid, message: value);
              },
            )
          ],
        ));
  }
}
