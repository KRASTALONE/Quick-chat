class BlockStatus {
  final bool blockedByMe;
  final bool blockedByOther;

  const BlockStatus({
    this.blockedByMe = false,
    this.blockedByOther = false,
  });

  bool get canSendMessage => !blockedByMe && !blockedByOther;

  String get description {
    if (blockedByMe) {
      return 'You blocked this user.';
    }
    if (blockedByOther) {
      return 'This user blocked you.';
    }
    return 'You can chat normally.';
  }
}
