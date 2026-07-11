
import 'package:flutter/material.dart';
import 'package:frontend/UI/constants.dart';
import 'package:frontend/controller/auth_controller.dart';
import 'package:frontend/controller/event_controller.dart';
import 'package:frontend/di/app_di.dart';
import 'package:frontend/entity/event.dart';
import 'package:frontend/dto/change_member_dto.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_ai.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_edit.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_file_previews.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_info.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_list.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_comment_input.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_join_button.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_members.dart';
import 'package:frontend/screens/main_screen/map/event_popup_components/event_popup_upload_file.dart';

void eventPopup(
  BuildContext context, 
  Event event, 
  List<CommentDraft> commentDrafts,
  void Function(EventDraft) setEventDraft,
  void Function() createEvent,
) {

  final mediaQuery = MediaQuery.of(context);
  final appBarHeight = Scaffold.maybeOf(context)?.appBarMaxHeight ?? (kToolbarHeight + kTextTabBarHeight);
  final maxSheetHeight = mediaQuery.size.height - mediaQuery.padding.top - appBarHeight;

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: maxSheetHeight - 10,
      maxWidth: Const.modalWidth,
    ),
    builder: (_) => EventPopup(
      event: event,
      commentDrafts: commentDrafts,
      setEventDraft: setEventDraft,
      createEvent: createEvent,
    ),
  );
}

class EventPopup extends StatefulWidget {
  
  EventPopup({
    super.key,
    required this.event,
    required this.commentDrafts,
    required this.setEventDraft,
    required this.createEvent,
  })  
  : authController = AppDI.instance.authController,
    eventController = AppDI.instance.eventController;

  final Event event;
  final AuthController authController;
  final EventController eventController;
  final List<CommentDraft> commentDrafts;
  final void Function(EventDraft) setEventDraft;
  final void Function() createEvent;

  @override
  State<EventPopup> createState() => _EventPopupState();
}

class _EventPopupState extends State<EventPopup> {

  bool isMember = false;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    isMember = widget.event.members.any((member) => member.id == widget.authController.userId);
    isOwner = widget.event.creator.id == widget.authController.userId;
    commentDraft = getCommentDraft() ?? CommentDraft(event: widget.event, text: '');
    commentController = TextEditingController(text: commentDraft.text);
    widget.event.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.event.controller.fetchEventEntities(widget.event.id);
    });
  }

  @override
  void dispose() {
    widget.event.controller.removeListener(_onControllerChanged);
    commentController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.event.controller.isDeleted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if(mounted) {
      setState(() {
        isMember = widget.event.members.any((member) => member.id == widget.authController.userId);
        isOwner = widget.event.creator.id == widget.authController.userId;
      });
    }
  }

  late final CommentDraft commentDraft;
  late final TextEditingController commentController;

  CommentDraft? getCommentDraft() {
    for(final draft in widget.commentDrafts) {
      if(widget.event.id == draft.event.id) {
        return draft;
      }
    }
    return null;
  }

  void setCommentDraft(String value)
  {
    setState(() {
      if(value.isEmpty) {
        widget.commentDrafts.removeWhere((draft) => widget.event.id == draft.event.id);
      }
      else {
        CommentDraft? draft = getCommentDraft();
        if(draft == null) {
          widget.commentDrafts.add(CommentDraft(event: widget.event, text: value));
        }
        else {
          draft.text = value;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwner) ...[
                    EventPopupEdit(
                    onEdit: () {
                      Navigator.of(context).pop();
                      widget.setEventDraft(widget.event.toDraft());
                      widget.createEvent();
                    },
                    onDelete: () {
                      widget.eventController.deleteEvent(widget.event.id).then((success) {
                        if(success && context.mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                  ),
                  Const.spacing,
                ],
                EventPopupInfo(event: widget.event),
                if (widget.event.members.isNotEmpty) ...[
                  EventPopupMembers(members: widget.event.members),
                ]
                else ...[
                  Const.spacing,
                ],
                Row(
                  spacing: 12,
                  children: [
                    if (widget.authController.isLoggedIn  && !isOwner) ...[
                      EventPopupJoinButton(
                        event: widget.event,
                        isMember: isMember,
                        changeMember: () => widget.event.controller.changeEventMembership(ChangeMemberDTO(
                          eventId: widget.event.id,
                          isAdded: !isMember
                        )),
                      ),
                    ],
                    if (isOwner) ...[
                      EventPopupUploadFile(
                        files: widget.event.filePreviews,
                        eventId: widget.event.id,
                        event: widget.event,
                      ),
                      if (widget.event.filePreviews.isNotEmpty 
                      && widget.event.filePreviews.any((file) 
                      => file.fileName.endsWith('.pdf'))) ...[
                        EventPopupAiButton(
                          event: widget.event,
                        ),
                      ],
                    ],
                    if (widget.authController.isLoggedIn) ...[
                      EventPopupFilePreview(
                        files: widget.event.filePreviews, 
                        event: widget.event,
                        isOwner: isOwner, 
                      ),
                    ],
                  ],
                ),
                if (widget.authController.isLoggedIn) ...[
                  Const.spacing,
                  EventPopupCommentInput(
                    event: widget.event,
                    commentDrafts: widget.commentDrafts,
                    commentController: commentController,
                    setCommentDraft: (value) => setCommentDraft(value),
                    ),
                ],
                EventPopupCommentList(comments: widget.event.comments, event: widget.event),
              ],
            ),
          ),
        ),
      ),
    );
  }
}