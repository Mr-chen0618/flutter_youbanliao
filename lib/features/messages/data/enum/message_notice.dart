enum MessageNotice {
  system('系统消息', 'system'),
  interaction('互动消息', 'interaction'),
  visitor('谁看过我', 'visitor');

  const MessageNotice(this.label, this.icon);
  final String label;
  final String icon;
}
