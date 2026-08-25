import { Capacitor } from '@capacitor/core'
import { PushNotifications } from '@capacitor/push-notifications'
import { requireBackend } from './supabase'

export async function registerPush(userId) {
  if (!Capacitor.isNativePlatform()) return null
  let permission = await PushNotifications.checkPermissions()
  if (permission.receive !== 'granted') permission = await PushNotifications.requestPermissions()
  if (permission.receive !== 'granted') throw new Error('Notificarile nu au fost permise.')

  return new Promise(async (resolve, reject) => {
    const db = requireBackend()
    await PushNotifications.addListener('registration', async token => {
      const { error } = await db.from('device_tokens').upsert({ user_id: userId, token: token.value, platform: 'android', updated_at: new Date().toISOString() }, { onConflict: 'token' })
      if (error) reject(error); else resolve(token.value)
    })
    await PushNotifications.addListener('registrationError', reject)
    await PushNotifications.register()
  })
}

export async function wireNotificationNavigation(openConversation) {
  if (!Capacitor.isNativePlatform()) return
  await PushNotifications.addListener('pushNotificationActionPerformed', event => {
    const conversationId = event.notification?.data?.conversation_id
    if (conversationId) openConversation(conversationId)
  })
}
