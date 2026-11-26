enum RoomOrder({required final bool byUnread, required final bool bySpace}) {
  unreadFirst(byUnread: true, bySpace: false),
  unreadFirstSpaceOrder(byUnread: true, bySpace: true),
  recentActivity(byUnread: false, bySpace: false),
  spaceOrder(byUnread: false, bySpace: true),
}
