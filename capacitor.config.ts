import type { CapacitorConfig } from '@capacitor/cli';
const config: CapacitorConfig = {
  appId: 'com.safirworld.chat',
  appName: 'SAFIR Chat',
  webDir: 'dist',
  android: { backgroundColor: '#070914' },
  plugins: {
    PushNotifications: { presentationOptions: ['badge','sound','alert'] },
    LocalNotifications: { smallIcon: 'ic_stat_safir' }
  }
};
export default config;
