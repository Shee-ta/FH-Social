
enum SseType {
  addEvent('addEvent'),
  removeEvent('removeEvent'),  
  addMember('addMember'),
  removeMember('removeMember'),
  addComment('addComment'),
  removeComment('removeComment'),
  addFilePreview('addFilePreview'),
  removeFilePreview('removeFilePreview');

  const SseType(this.value);

  final String value;

  static SseType? parse(String value) {
    for (final type in SseType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return null;
  }
}