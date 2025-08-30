db = db.getSiblingDB('notification-management');

db.createUser({
  user: 'notif-user',
  pwd: 'dbinitPASSWORD001axi00',
  roles: [{ role: 'readWrite', db: 'notification-management' }]
});